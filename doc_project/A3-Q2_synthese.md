# A3-Q2 — Kibana connecté à Elasticsearch + requêtes sur les logs

*Statut au 13 juillet 2026 : **terminé et vérifié**, en avance sur le créneau initialement prévu le 14.
Kibana est opérationnel sur EKS, connecté à Elasticsearch, et les recherches KQL sont prouvées par des
résultats réels dans Discover. S'appuie sur la stack A3-Q1 (Elasticsearch + Filebeat) reconstruite via
`RUNBOOK.md` §4bis. **Consolidation J3 (15 juillet) : dashboard minimal + scénario de détection d'incident
de bout en bout — voir la section « Consolidation » plus bas.***

## Réponse apportée

### Partie 1/3 — Kibana déployé et connecté à Elasticsearch ✅
CR `k8s/elk/kibana.yaml` : **Kibana 9.4.3** (même version qu'ES/Filebeat), `count: 1`,
`elasticsearchRef: {name: infoline-es}`. L'opérateur ECK monte automatiquement le CA TLS et les credentials
d'ES dans le pod Kibana — c'est le « connectez-le à Elasticsearch » du sujet, sans câblage manuel.
Le transcript `A3-Q2_kibana-ready.md` montre `HEALTH green`, un nœud Kibana 9.4.3 et son pod `1/1 Running`.
L'accès local par `kubectl port-forward service/infoline-kibana-kb-http 5601` puis l'authentification avec
le compte `elastic` ont abouti à la page d'accueil (`A3-Q2_kibana-home.png`).

### Partie 2/3 — Data view sur les logs ✅
La data view **`filebeat-*`**, basée sur le champ temps `@timestamp`, correspond au data stream
`filebeat-9.4.3`. Discover affiche les documents et leur histogramme temporel. Les colonnes ont été réduites
à `@timestamp`, `log.level`, `kubernetes.pod.name` et `message` afin de présenter une preuve lisible sans
exposer `cloud.account.id`. Preuves : `A3-Q2_data-view.png` et `A3-Q2_discover.png`.

### Partie 3/3 — Requêtes KQL commentées ✅
Les requêtes ont été adaptées aux champs réellement alimentés par les différents composants :

- `message : "WARN" or message : "ERROR"` repère les anomalies même lorsque `log.level` n'est pas
  normalisé ; 64 documents étaient retournés (`A3-Q2_kql-errors.png`).
- `message : "certificate_unknown"` retrouve un rejet TLS réel émis par Elasticsearch, avec le détail de
  la `SSLHandshakeException` (`A3-Q2_kql-certificate.png`).
- `kubernetes.namespace : "kube-system"` isole les composants système du cluster
  (`A3-Q2_kql-namespace.png`).
- `kubernetes.pod.name : infoline-es*` cible un service précis, ici Elasticsearch
  (`A3-Q2_kql-pod.png`).
- `stream : "stderr"` filtre le flux d'erreur des conteneurs (`A3-Q2_kql-stderr.png`).
- `kubernetes.namespace : "kube-system" and stream : "stderr"` combine deux critères pour restreindre
  l'investigation aux sorties d'erreur système (`A3-Q2_kql-combined.png`).
- Une fenêtre temporelle bornée réduit l'investigation autour d'un événement ; 95 documents sont visibles
  avec l'histogramme (`A3-Q2_kql-timewindow.png`).

## Pointeurs
- **Code / manifeste** : `k8s/elk/kibana.yaml`.
- **Procédure de déploiement / redeploy** : `RUNBOOK.md` §4bis (Kibana + port-forward 5601).
- **Pourquoi ces choix** (port-forward vs LoadBalancer, Kibana via ECK) : `architecture.md`, section
  « Supervision par les logs — ELK ».
- **Frictions** : `doc_project/FRICTIONS.md`, session Phase 4 (friction 12) + session Mer 15 juil (consolidation).
- **Captures** : `doc_project/captures/A3-Q2_*` (Kibana/KQL) + `doc_project/captures/A3-consolidation_*`
  (dashboard + incident) — transcripts bruts + PNG vérifiés visuellement.
- **Dashboard versionné** : `k8s/elk/kibana-saved-objects/dashboard-infoline-supervision.ndjson`
  (dashboard + data view + recherche sauvegardée, réimportables).

## Écart outil assumé
- **Accès par `port-forward`** plutôt qu'un Service `LoadBalancer` : évite un 2e ELB hors Terraform (coût +
  nettoyage avant chaque `destroy`). Suffisant pour la démonstration ; en production, Kibana serait exposé
  derrière un Ingress/ALB avec authentification et TLS gérés.
- **Thème « login » hors périmètre ELK** : la fonction login est **serverless (Lambda)** ; ses logs vont
  dans **CloudWatch**, pas dans Elasticsearch (Filebeat ne collecte que les logs des pods Kubernetes). Une
  requête KQL « login » n'a donc pas de sens ici — frontière assumée, pas un oubli.
- **Thème « latence »** : les applications sont des hello-world triviaux sans log de temps de réponse ; la
  dimension temporelle est démontrée via le **time picker** de Kibana (fenêtre glissante) plutôt qu'un champ
  de latence applicatif dédié.

## Conformité
- **Fiche Studi mobilisée** : **B3 P3, P4** (Kibana, exploration et requêtes sur les logs).
- **Écarts / points de vigilance assumés** :
  - Requêtes KQL portées sur les logs d'infrastructure/plateforme (ES, Filebeat, kube-system) — le scénario
    « erreur applicative visible = notification » sur l'API `infoline-api` est **traité en consolidation J3**
    (voir la section « Consolidation » dédiée).
  - Manifeste Kibana dans `k8s/elk/` (jamais `k8s/`) — non embarqué par le pipeline CI de l'API.
  - Captures Kibana : Account ID présent dans les documents Discover → vérification visuelle de chaque PNG
    (le grep ne détecte pas un ID dans une image).

## Consolidation (J3, 15 juillet) — dashboard + scénario de détection d'incident

Consolidation d'A3-Q1/Q2 (pas une question ECF distincte) : fermeture de la boucle d'observabilité sur un
**cas réel** — API déployée, dashboard minimal, puis un dysfonctionnement **provoqué → détecté dans Kibana
→ résolu**.

### Dashboard « InfoLine — Supervision ELK »
Trois panneaux sur la data view `filebeat-*` :
1. **Log Volume Over Time** — histogramme temporel du volume total de logs (le « pouls » du cluster).
2. **Log Distribution by Pod** — barres horizontales, top 10 des `kubernetes.pod.name` (qui parle le plus).
3. **Error Count** — Metric filtré `message : "WARN" or message : "ERROR"` (filtre posé **dans l'éditeur
   Lens du panneau**, pas au niveau du dashboard, pour ne pas contaminer les 2 autres), avec une mini-courbe
   « Line » en fond donnant la tendance temporelle des erreurs.

Le dashboard est **exporté en Saved Objects** (`k8s/elk/kibana-saved-objects/dashboard-infoline-supervision.ndjson`,
avec la data view `filebeat-*` et la recherche `Logs — Reduced Columns`) → réimportable en quelques secondes
au prochain réveil, plutôt que reconstruit à la main. C'est nécessaire car ces objets vivent dans l'index
`.kibana`, sur le stockage **`emptyDir`** d'ES (écart persistance acté en A3-Q1) — perdus à chaque `destroy`.
Preuve baseline : `A3-consolidation_dashboard-baseline.png`.

### Scénario d'incident : un déploiement cassé
- **Baseline saine** : API `infoline-api` déployée (image ECR `0d0207f`, déploiement manuel RUNBOOK §4),
  `curl http://<elb>/hello` → `Hello from InfoLine API`. Preuve : `A3-consolidation_api-healthy.md`.
- **Dysfonctionnement provoqué** (zéro modif de code) : `kubectl set env deployment/infoline-api SERVER_PORT=notanumber`
  → Spring Boot échoue à binder `server.port` au démarrage → `CrashLoopBackOff` (relances au rythme du
  backoff Kubernetes plafonné à ~5 min, visible dans les logs). L'ancien pod (ReplicaSet `955fc7c6`) reste
  `Running` (`maxSurge: 0 / maxUnavailable: 1`) → app **dégradée**, pas 100 % down. Preuves :
  `A3-consolidation_incident-pods.md`, `A3-consolidation_incident-logs.md` (stack trace
  `Failed to bind properties under 'server.port'`, `Origin: System Environment Property "SERVER_PORT"`).
- **Détection dans Kibana (= la « notification »)** :
  - *Signal le plus robuste* — **Log Distribution by Pod** : le pod qui crashe **bondit en tête** du classement
    (contre le bas de tableau en baseline), indépendamment de la fenêtre temporelle. `A3-consolidation_dashboard-incident.png`.
  - *Comparaison chiffrée valide* (même fenêtre « Today » que la baseline) — **Error Count 63 → 94**.
    `A3-consolidation_dashboard-incident-today.png`.
  - *Recherche ciblée* dans Discover : `kubernetes.pod.name : infoline-api* and message : "server.port"`
    → retrouve la stack trace de crash. `A3-consolidation_incident-kibana.png`.
- **Résolution** : `kubectl rollout undo deployment/infoline-api` → pods `2/2 Running` (le ReplicaSet sain
  `955fc7c6` est restauré à l'identique), `curl /hello` → 200, tendance des erreurs qui retombe au bruit de
  fond. Preuve : `A3-consolidation_recovery-kibana.png`.

**Boucle fermée** : émettre → collecter (Filebeat) → indexer (ES) → visualiser (dashboard) → **remarquer**
(Discover/dashboard) → **agir** (rollback). Un dysfonctionnement réel, repéré sans instrumentation d'alerte
dédiée = la « notification » demandée par InfoLine.

### Écarts / points de vigilance assumés (consolidation)
- **Détection visuelle, pas alerting push** : la « notification » est interprétée comme *un dysfonctionnement
  visible dans Kibana*. L'alerting automatisé (Watcher / Kibana Alerting) est l'étape production, nommée mais
  hors périmètre.
- **Comparer à fenêtre temporelle égale** : le compteur cumulé « Today » ne peut que croître → juger la
  résolution sur la **tendance récente** (sparkline + Panneau 1), pas sur le total brut affiché.
- **Multiline non configuré** : chaque ligne d'une stack trace Java est indexée comme un **document distinct**
  (pas de parser `multiline` sur l'input `filestream`) — n'empêche pas de retrouver l'incident, mais en
  production on grouperait l'exception en un seul document.
- **Dysfonctionnement = incident d'exploitation** (déploiement cassé), pas un bug métier — cohérent avec des
  apps volontairement triviales, et le cas le plus fréquent en production.

## Statut

| | Manifeste | Déploiement + connexion ES | Data view | Requêtes KQL | Doc | Captures |
|---|---|---|---|---|---|---|
| A3-Q2 | ✅ | ✅ `HEALTH green` | ✅ `filebeat-*` | ✅ 7 preuves | ✅ | ✅ |

**Consolidation (J3)** : dashboard 3 panneaux (versionné en Saved Objects) + scénario d'incident
**provoqué → détecté dans Kibana → résolu** de bout en bout — ✅ (8 captures `A3-consolidation_*`).
