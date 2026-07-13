# A3-Q1 — Elasticsearch connecté à Kubernetes

*Statut au 13 juillet 2026 : **démontré ✅**. Elasticsearch déployé sur le cluster EKS via l'opérateur
ECK, Filebeat (DaemonSet) collecte les logs de tous les pods et les indexe ; la connexion au Kubernetes
est prouvée par une recherche retrouvant un log réel enrichi de ses métadonnées k8s. Kibana + requêtes
commentées = A3-Q2 (jour suivant).*

## Réponse apportée

### Partie 1/3 — nœuds dimensionnés pour Elasticsearch ✅
Le node group EKS (`terraform/eks/`) est passé de `t3.micro` (1 GiB, insuffisant pour une JVM
Elasticsearch) à **`m7i-flex.large`** (8 GiB). Ce type a été sélectionné parmi ceux **explicitement
listés Free Tier eligible** dans `eu-west-3` — le compte étant en Free Tier, il refuse au lancement tout
type hors liste (cf. « Écart outil assumé » + FRICTIONS F11). 2 nœuds `Ready` vérifiés
(`kubectl get nodes -L node.kubernetes.io/instance-type`). Preuve : `A3-Q1_kubectl-get-nodes-m7i-flex`.

### Partie 2/3 — Elasticsearch déployé via l'opérateur ECK ✅
Opérateur **ECK 3.4.1** installé (CRD `Elasticsearch`/`Kibana`/`Beat` + contrôleur dans `elastic-system`),
puis CR `k8s/elk/elasticsearch.yaml` appliqué : **Elasticsearch 9.4.3 single-node** (`count: 1`), stockage
`emptyDir` (éphémère — écart assumé), `node.store.allow_mmap: false` (évite l'exigence `vm.max_map_count`
sur le nœud managé). L'opérateur a câblé automatiquement **TLS + authentification** (sécurité activée par
défaut depuis Stack 8+). Ressource passée à `PHASE: Ready` en ~55 s.
- **Vérifié** : `kubectl get elasticsearch` → Ready ; puis `curl -k -u elastic:$PW https://localhost:9200/_cluster/health`
  (accès par `kubectl port-forward`, certificat auto-signé d'où `-k`) → `"status":"green"`,
  `"number_of_nodes":1`. Preuves : `A3-Q1_elasticsearch-health`, `A3-Q1_es-tls-cert-browser` (le certificat
  TLS auto-généré par ECK, vu au navigateur).
- **Compatibilité ECK 3.4.1 ↔ Stack 9.4.3** confirmée empiriquement (le webhook de validation ECK n'a pas
  rejeté le CR, `PHASE` a convergé) — le pairing n'était pas garanti par une source doc, il l'est par le run.

### Partie 3/3 — Filebeat (DaemonSet) et preuve de connexion au cluster ✅
CR `k8s/elk/filebeat.yaml` appliqué : ServiceAccount + ClusterRole/Binding (lecture de l'API k8s), CRD
`Beat` en `daemonSet`, autodiscover Kubernetes, montages `hostPath` sur `/var/log/containers`,
`/var/log/pods`, `/var/lib/docker/containers`. `elasticsearchRef` → ECK câble seul le TLS et les
credentials vers `infoline-es`.
- **Vérifié — DaemonSet** : `kubectl get beat` → `HEALTH green`, `AVAILABLE 2 / EXPECTED 2` ;
  `kubectl get pods -l beat.k8s.elastic.co/name=infoline-filebeat -o wide` → **exactement 2 pods, un par
  nœud** (démonstration concrète du DaemonSet). Preuve : `A3-Q1_filebeat-daemonset`.
- **Vérifié — ingestion + connexion (preuve reine)** : `_cat/indices/filebeat-*` → index
  `.ds-filebeat-9.4.3-*` avec `docs.count` > 0 (1290 en quelques minutes) ; puis une recherche
  (`_search?q=kubernetes.pod.name:infoline-es*`) renvoie un **log réel enrichi** de son bloc `kubernetes`
  (`pod.name`, `namespace`, `node.name`, `labels`, `statefulset`), du champ `log.file.path`
  (`/var/log/containers/…`, le fichier physique lu sur le nœud) et de `orchestrator.cluster.name:
  infoline-eks` (rattachement explicite **au** cluster IaC d'A1-Q1). Preuves : `A3-Q1_cat-indices`,
  `A3-Q1_search-k8s-metadata` (floutée).

## Pointeurs
- **Code / manifestes** : `k8s/elk/elasticsearch.yaml`, `k8s/elk/filebeat.yaml`.
- **Procédure de déploiement / redeploy** : `RUNBOOK.md` §4bis (déploiement ELK manuel : ECK → ES → Filebeat
  → vérif), §7 (destroy — cas ELK), §8 (piège Free Tier + commande de diagnostic des types éligibles).
  Checklist pas-à-pas vécue : `doc_project/PHASE4-J1_checklist.md`.
- **Pourquoi ces choix** (logs vs métriques, ECK, emptyDir, Filebeat vs Fluent Bit/Logstash, m7i-flex.large) :
  `architecture.md`, section « Supervision par les logs — ELK ».
- **Frictions** : `doc_project/FRICTIONS.md` — session Lun 13 juil, **Friction 11** (piège Free Tier au
  lancement + dry-run trompeur) et observations (`-w` bloquant, faux « curl qui pend »).
- **Captures** : `doc_project/captures/A3-Q1_*` — `kubectl-get-nodes-m7i-flex`, `elasticsearch-health`,
  `es-tls-cert-browser.png`, `filebeat-daemonset`, `cat-indices`, `search-k8s-metadata` (floutée).

## Écart outil assumé

- **Opérateur ECK** plutôt que manifests Kubernetes bruts (StatefulSet/Deployment à la main) : ELK étant la
  techno la moins maîtrisée du projet (cf. `CLAUDE.md`), l'opérateur élimine la config manuelle de
  TLS/credentials/câblage ES↔Beats — le risque de friction le plus élevé. Approche production, défendable.
  Validé sans friction : ES et Filebeat verts du premier coup.
- **Stockage `emptyDir`** plutôt que `PersistentVolumeClaim` : le cluster n'a ni driver EBS CSI ni
  StorageClass ; les ajouter serait une extension d'infra hors périmètre pour un cluster détruit chaque
  soir. Les logs ne survivent pas à un redémarrage de pod — acceptable : les manifests sont la source de
  vérité et la démonstration se rejoue à l'identique (Filebeat ré-ingère en quelques minutes).
- **Type d'instance `m7i-flex.large`** : contrainte **compte Free Tier** (refus au lancement de tout type
  non éligible — pas une SCP ni une pénurie transitoire, comme d'abord supposé ; cf. F11). Type retenu parmi
  ceux listés Free Tier eligible dans la région, avec `c7i-flex.large` en second choix (hedge de capacité).

## Conformité
- **Fiche Studi mobilisée** : **B3 P1, P2** (paradigme logs vs métriques, indexation, déploiement
  Elasticsearch connecté à Kubernetes ; collecte des logs des pods via un agent de niveau nœud).
- **Écarts / points de vigilance assumés** :
  - Pas de haute disponibilité (`count: 1`) — cohérent avec un POC d'examen, nommé explicitement.
  - **Santé de l'index Filebeat en `yellow`** : son template demande 1 réplica, impossible à placer sur un
    seul nœud → réplica non assigné → index yellow. **Le shard primaire est sain** (donnée intacte), il
    manque juste la redondance — normal en mono-nœud, pas un bug. (Le `_cluster/health` était green tant
    que seuls les index système à 0 réplica existaient.)
  - Manifests ELK isolés dans `k8s/elk/` (jamais `k8s/`) pour ne pas être auto-appliqués par le pipeline CI
    de l'API. Déploiement ELK **manuel** et hors CI, assumé (pas de valeur à automatiser une supervision
    déployée une fois par session).
  - L'API `infoline-api` n'était pas déployée sur ce cluster fraîchement recréé : la preuve de connexion
    s'appuie sur les logs des pods réellement présents (ES, Filebeat, opérateur, kube-system) — suffisant,
    A3-Q1 demandant la connexion aux logs *du Kubernetes*, pas d'une app précise. Les logs applicatifs de
    l'API prendront leur sens pour A3-Q2 (requêtes erreurs/login parlantes).

## Statut

| | Manifestes | Déploiement EKS | Preuve de connexion | Doc | Captures |
|---|---|---|---|---|---|
| A3-Q1 | ✅ `k8s/elk/` | ✅ ECK + ES + Filebeat (verts) | ✅ log k8s-enrichi retrouvé dans ES | ✅ synthèse + archi + frictions | ✅ 6 captures (1 floutée) |
