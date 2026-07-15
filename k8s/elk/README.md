# k8s/elk — supervision par les logs (ELK)

Stack de supervision déployée **dans** le cluster EKS via l'opérateur **ECK** (Elastic Cloud
on Kubernetes). Isolée de `k8s/` pour **ne pas** être appliquée par le pipeline CI de l'API :
déploiement **manuel**, une fois par session (`RUNBOOK.md` §4bis).

Répond aux questions **A3-Q1** (Elasticsearch connecté à Kubernetes) et **A3-Q2** (Kibana +
requêtes KQL sur les logs).

## Contenu

- `elasticsearch.yaml` — CR `Elasticsearch infoline-es` 9.4.3, single-node, stockage
  `emptyDir` (éphémère, écart assumé), TLS + auth câblés par ECK.
- `filebeat.yaml` — CR `Beat` en **DaemonSet** (1 pod/nœud) + ServiceAccount/ClusterRole ;
  input `filestream` sur `/var/log/containers/*.log`, enrichissement `add_kubernetes_metadata`.
- `kibana.yaml` — CR `Kibana infoline-kibana` 9.4.3, `elasticsearchRef: infoline-es`.
- `kibana-saved-objects/dashboard-infoline-supervision.ndjson` — dashboard + data view
  `filebeat-*` + recherche Discover, **réimportables** (les objets `.kibana` vivent sur le
  stockage `emptyDir`, perdus à chaque `destroy`).

## Déploiement (résumé)

Opérateur ECK (URL versionnée `.../eck/3.4.1/`) → `elasticsearch.yaml` → `filebeat.yaml` →
`kibana.yaml` → accès Kibana par `kubectl port-forward … 5601`. Pas-à-pas complet, credentials
et vérifications : `RUNBOOK.md` §4bis.

## Documentation

Rationale (logs vs métriques, ECK, Filebeat en DaemonSet, `emptyDir`, port-forward) :
`architecture.md` § « Supervision par les logs — ELK ». Synthèses :
`doc_project/A3-Q1_synthese.md`, `doc_project/A3-Q2_synthese.md`.
