# A3-Q2 — Kibana connecté à Elasticsearch + requêtes sur les logs

*Statut au 13 juillet 2026 : **terminé et vérifié**, en avance sur le créneau initialement prévu le 14.
Kibana est opérationnel sur EKS, connecté à Elasticsearch, et les recherches KQL sont prouvées par des
résultats réels dans Discover. S'appuie sur la stack A3-Q1 (Elasticsearch + Filebeat) reconstruite via
`RUNBOOK.md` §4bis.*

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
  Checklist pas-à-pas : `doc_project/PHASE4-J2_checklist.md`.
- **Pourquoi ces choix** (port-forward vs LoadBalancer, Kibana via ECK) : `architecture.md`, section
  « Supervision par les logs — ELK ».
- **Frictions** : `doc_project/FRICTIONS.md`, session Phase 4, friction 12.
- **Captures** : `doc_project/captures/A3-Q2_*` — transcript terminal brut + PNG vérifiés visuellement.

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
    « erreur applicative visible = notification » sur l'API `infoline-api` relève de J3 (consolidation).
  - Manifeste Kibana dans `k8s/elk/` (jamais `k8s/`) — non embarqué par le pipeline CI de l'API.
  - Captures Kibana : Account ID présent dans les documents Discover → vérification visuelle de chaque PNG
    (le grep ne détecte pas un ID dans une image).

## Statut

| | Manifeste | Déploiement + connexion ES | Data view | Requêtes KQL | Doc | Captures |
|---|---|---|---|---|---|---|
| A3-Q2 | ✅ | ✅ `HEALTH green` | ✅ `filebeat-*` | ✅ 7 preuves | ✅ | ✅ |
