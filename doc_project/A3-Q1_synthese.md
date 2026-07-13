# A3-Q1 — Elasticsearch connecté à Kubernetes

*Statut au 12 juillet 2026 : **en cours**. Nœuds EKS redimensionnés et vérifiés Ready ; manifests
Elasticsearch/Filebeat écrits. Déploiement effectif sur le cluster live, preuve de connexion et
captures : à produire lundi 13 juillet.*

## Réponse apportée

### Partie 1/3 — nœuds dimensionnés pour Elasticsearch (12 juillet) ✅
Le node group EKS (`terraform/eks/`) est passé de `t3.micro` (1 GiB, insuffisant pour une JVM
Elasticsearch) à **`m7i-flex.large`** (8 GiB), sélectionné parmi les types explicitement listés
Free Tier eligible dans `eu-west-3` (contrainte de compte réelle, cf. « Écart outil assumé »).
2 nœuds `Ready` vérifiés (`kubectl get nodes -L node.kubernetes.io/instance-type`).

### Partie 2/3 — Elasticsearch déployé via l'opérateur ECK (à produire)
Manifest `k8s/elk/elasticsearch.yaml` écrit : CRD `Elasticsearch` (`elasticsearch.k8s.elastic.co/v1`),
single-node (`count: 1`), stockage `emptyDir` (pas de persistance — écart assumé), `allow_mmap: false`.
**Reste à faire** : installer l'opérateur ECK, appliquer le manifest, vérifier `HEALTH`/`PHASE` via
`kubectl get elasticsearch`, capturer la preuve (`_cluster/health`).

### Partie 3/3 — Filebeat (DaemonSet) et preuve de connexion au cluster (à produire)
Manifest `k8s/elk/filebeat.yaml` écrit : ServiceAccount + ClusterRole/Binding, CRD `Beat` en
`daemonSet`, autodiscover Kubernetes, montages `hostPath` sur `/var/log/containers` et `/var/log/pods`.
**Reste à faire** : appliquer, vérifier 1 pod Filebeat par nœud, puis prouver la connexion K8s→ES par
une recherche Elasticsearch retrouvant les logs réels des pods `infoline-api`.

## Pointeurs
- **Code / manifestes** : `k8s/elk/elasticsearch.yaml`, `k8s/elk/filebeat.yaml`.
- **Procédure de déploiement** : `RUNBOOK.md` §8 (piège Free Tier/type d'instance) — section Phase 4
  dédiée à compléter lundi. Checklist d'exécution pas-à-pas : `doc_project/PHASE4-J1_checklist.md`.
- **Pourquoi ces choix** (ECK vs manifests bruts, emptyDir vs PVC, Filebeat vs Logstash, type
  d'instance) : `architecture.md`, section « Pourquoi ELK pour la supervision » — stub à remplir lundi.
- **Frictions** : `doc_project/FRICTIONS.md` — Friction 11 (à rédiger : dry-run trompeur, restriction
  Free Tier au lancement, découverte `m7i-flex.large`).
- **Captures** : `doc_project/captures/A3-Q1_*` — aucune encore ; prévues lundi (nœuds Ready, santé ES,
  DaemonSet Filebeat, recherche de logs).

## Écart outil assumé

Trois écarts déjà actés (déploiement non encore fait, raisonnement fixé) :
- **Opérateur ECK** plutôt que manifests Kubernetes bruts (StatefulSet/Deployment à la main) : ELK
  étant la techno la moins maîtrisée du projet (cf. `CLAUDE.md`), l'opérateur élimine la configuration
  manuelle de TLS/credentials/câblage ES↔Kibana↔Beats — risque de friction le plus élevé du projet.
- **Stockage `emptyDir`** plutôt que `PersistentVolumeClaim` : le cluster n'a ni driver EBS CSI ni
  StorageClass (absents du Terraform actuel) ; les ajouter serait une extension d'infra hors périmètre
  du sujet pour un cluster détruit chaque soir. Les logs ne survivent pas à un redémarrage de pod —
  acceptable, les manifests restent la source de vérité et la démonstration se rejoue à l'identique.
- **Type d'instance `m7i-flex.large`** plutôt que le `t3.medium`/`t3.large` initialement visé : compte
  AWS Free Tier, restriction au lancement (pas une SCP ni une pénurie, comme d'abord supposé — voir
  Friction 11). Type retenu parmi ceux explicitement listés Free Tier eligible dans la région.

## Conformité
- **Fiche Studi mobilisée** : **B3 P1, P2** (paradigme logs, indexation, déploiement Elasticsearch
  connecté à Kubernetes).
- **Écarts / points de vigilance assumés** :
  - Pas de haute disponibilité côté Elasticsearch (`count: 1`) — cohérent avec un POC d'examen, à
    nommer explicitement plutôt que laisser croire à un oubli.
  - Health `yellow` attendu en single-node (réplicas système non assignés) — normal, pas un bug, à
    documenter dans la capture pour ne pas laisser un doute au jury.
  - Manifests ELK isolés dans `k8s/elk/` (jamais `k8s/`) pour ne pas être auto-appliqués par le
    pipeline CI de l'API (`kubectl apply -f k8s/` sur tout le dossier).

## Statut

| | Manifestes | Déploiement EKS | Preuve de connexion | Doc | Captures |
|---|---|---|---|---|---|
| A3-Q1 | ✅ écrits (`k8s/elk/`) | ❌ pas encore appliqués | ❌ à produire | 🔶 synthèse amorcée | ❌ aucune |
