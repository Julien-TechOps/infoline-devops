# k8s — manifestes Kubernetes

Manifestes appliqués sur le cluster EKS (namespace `default`).

## Contenu

- `api-deployment.yaml` — `Deployment infoline-api`, **2 replicas**, port 8080, rolling
  update `maxSurge: 0 / maxUnavailable: 1`, sondes readiness/liveness sur `/hello`. L'image
  porte le placeholder `IMAGE_PLACEHOLDER`, **substitué par la CI** juste avant `kubectl
  apply` (référence ECR `…/infoline-api:<SHA>`) — le manifeste reste agnostique du compte.
- `api-service.yaml` — `Service infoline-api`, `type: LoadBalancer`, `80 → 8080`. Provisionne
  un **Classic Load Balancer** hors Terraform → **à supprimer avant `terraform destroy`**
  (cf. `RUNBOOK.md` §7).
- `elk/` — **stack de supervision ELK**, voir `k8s/elk/README.md`.

## Ce que la CI applique (et pas)

`.github/workflows/deploy.yml` fait `kubectl apply -f k8s/` **non récursif** → seuls
`api-deployment.yaml` et `api-service.yaml` sont appliqués. **`k8s/elk/` n'est pas embarqué
par la CI** (déploiement manuel, une fois par session) — c'est voulu (`RUNBOOK.md` §4bis).

## Documentation

Rationale (LoadBalancer, 2 replicas, `maxSurge: 0`, probes, placeholder) : `architecture.md`
§ « Déploiement de l'API sur EKS » et « CI/CD ». Synthèse : `doc_project/A2-Q3_synthese.md`.
