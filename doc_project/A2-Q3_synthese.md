# A2-Q3 — Script build/test + déploiement de l'API Spring Boot sur le kube

*Déploiement de l'API sur le cluster EKS provisionné en Phase 1. Statut au 10 juillet 2026 :
partie 1/2 (déploiement manuel) faite ; partie 2/2 (pipeline qui automatise la séquence) réalisée
en **GitHub Actions**, vert de bout en bout — bascule assumée depuis CircleCI, cf. « Écart outil assumé ».*

## Réponse apportée

### Partie 1/2 — déploiement manuel (7 juillet) ✅
Image de l'API poussée sur ECR puis déployée sur le cluster EKS via deux manifestes versionnés :
- **`k8s/api-deployment.yaml`** : `Deployment` à 2 replicas, image
  `…/infoline-api:23547c5` (tag = SHA court du commit), probes `readiness` **et** `liveness` sur
  `GET /hello`.
- **`k8s/api-service.yaml`** : `Service` `type: LoadBalancer` → provisionne un Classic Load Balancer
  AWS, publie le port 80 public vers le `targetPort: 8080` des pods.
- **Vérifié de bout en bout** : 2 pods `Running` (2/2 Ready), `Endpoints` peuplés (2 IP:8080), puis
  `curl http://<elb-dns>/hello` → `Hello from InfoLine API`. Chemin complet
  Internet → ELB(80) → NodePort → pod(8080).

### Partie 2/2 — pipeline GitHub Actions (10 juillet) ✅
La séquence manuelle est automatisée dans `.github/workflows/deploy.yml` : job `build-test`
(`mvn verify`), puis job `build-push-deploy` (configure AWS credentials → ECR login →
`docker build`/tag = SHA court/push → `aws eks update-kubeconfig` → **substitution de l'image**
(`IMAGE_PLACEHOLDER` → réf ECR construite depuis les secrets) → `kubectl apply -f k8s/` →
`kubectl rollout status --timeout=240s` comme garde-fou qui fait échouer le job si le déploiement
ne converge pas). L'infra CI (ECR IaC, IAM `infoline-ci`, Access Entry EKS versionnée dans
`terraform/eks/access-entries.tf`) est réutilisée telle quelle depuis CircleCI. Deux frictions de
capacité traitées (cf. `FRICTIONS.md`, Friction 10) : `maxSurge: 0` / `maxUnavailable: 1` (nodes
t3.micro = 4 pods/node), puis `--timeout` du rollout porté à 240 s (rollout séquentiel plus lent).
**Preuve reine capturée** (commit `e96fac6`) : pipeline vert, rolling update réel (hash ReplicaSet
`5b6f7c7895` → `955fc7c6`, remplacement séquentiel confirmé par les logs `1 out of 2…` et l'écart
d'âge des pods), et `curl` ELB → `Hello from InfoLine API` après déploiement automatique.

## Pointeurs
- **Code / manifestes** : `k8s/api-deployment.yaml`, `k8s/api-service.yaml`.
- **Procédure de (re)déploiement** : `RUNBOOK.md`, §3 (déploiement continu CI/CD — chemin nominal)
  et §4 (déploiement manuel de secours).
- **Pourquoi ces choix** (LoadBalancer, 2 replicas, probes sur `/hello`, Classic LB, tag SHA,
  déploiement manuel d'abord) : `architecture.md`, section « Déploiement de l'API sur EKS ».
- **Frictions** : `doc_project/FRICTIONS.md` — 7 juil (réveil cluster, ECR immutable, transitions de
  pods), Jeu 9 juil (bascule CircleCI → GitHub Actions, Friction 10 rollout/t3.micro), Ven 10 juil
  (substitution image, preuve du rolling update).
- **Captures** : `doc_project/captures/A2-Q3_*` — partie 1 (manuel, 7 juil) : `pods-running.md`,
  `svc-loadbalancer.md`, `curl-hello.md`, `ecr-images.png` ; partie 2 (pipeline, 10 juil) :
  `pipeline-green.png`, `rollout-transcript.md` (hash A→B), `deploy-job-logs.png` (rollout séquentiel),
  `curl-after-deploy.md`.

## Écart outil assumé

Le sujet cite CircleCI ; la copie livre GitHub Actions. Écart assumé et argumenté (comme la
dockerisation du front en A2-Q4) : blocage account-level CircleCI non imputable au candidat,
support inaccessible sans plan payant (ticket #173426, cf. FRICTIONS.md Jeu 9 juil),
validation d'écart demandée aux enseignants sur le forum Studi. Résolu par un outil CI/CD
équivalent et natif à GitHub. La compétence évaluée (automatiser build/test/déploiement sur
le cluster) est démontrée à l'identique ; seul l'outil change. Pointeurs : workflow dans
`.github/workflows/`, "pourquoi" dans architecture.md (section CI/CD), infra CI (ECR IaC,
IAM `infoline-ci`, Access Entry) inchangée.

## Conformité
- **Fiche Studi mobilisée** : **B2 P4** (automatiser la mise en production). Ici le déploiement manuel
  est la ligne de base que le pipeline (partie 2/2) automatisera ; la friction manuelle **justifie** le
  CI/CD (on ne peut pas argumenter la valeur du pipeline sans avoir vécu le déploiement à la main).
- **Écarts / points de vigilance assumés** :
  - **Classic Load Balancer** (contrôleur legacy intégré à EKS), pas de AWS Load Balancer Controller
    (ALB/NLB) : suffisant pour exposer un hello world, aucune installation supplémentaire. À
    reconsidérer si Ingress/HTTPS requis.
  - **Probes sur `/hello`** faute d'endpoint `/actuator/health` dédié (Spring Actuator non ajouté —
    applicatif volontairement trivial).
  - **Repo ECR** : initialement créé hors IaC (partie 1/2, urgence du premier déploiement),
    **réintégré par `terraform import`** (`terraform/ecr/`) — dernier maillon hors-Terraform refermé.
    Cf. `architecture.md` « Pourquoi ECR en IaC ».

## Statut

| | Manifestes | Déploiement EKS | Pipeline GitHub Actions | Doc | Captures |
|---|---|---|---|---|---|
| A2-Q3 | ✅ versionnés | ✅ manuel + auto (curl OK) | ✅ vert (`e96fac6`) | ✅ parties 1-2 | ✅ rolling update prouvé |
