# A2-Q3 — Script build/test + déploiement de l'API Spring Boot sur le kube

*Déploiement de l'API sur le cluster EKS provisionné en Phase 1. Statut au 7 juillet 2026 :
partie 1/2 (déploiement manuel) faite ; partie 2/2 (pipeline CircleCI qui automatise la séquence)
prévue le 8 juillet.*

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

### Partie 2/2 — pipeline CircleCI (prévu 8 juillet) ⏳
Automatiser cette séquence manuelle : build Maven → test → build image → push ECR → `kubectl apply`.
Cf. `doc_project/backlog.md`, Phase 3.

## Pointeurs
- **Code / manifestes** : `k8s/api-deployment.yaml`, `k8s/api-service.yaml`.
- **Procédure de (re)déploiement** : `RUNBOOK.md`, section « Déployer l'API Spring Boot sur le cluster ».
- **Pourquoi ces choix** (LoadBalancer, 2 replicas, probes sur `/hello`, Classic LB, tag SHA,
  déploiement manuel d'abord) : `architecture.md`, section « Déploiement de l'API sur EKS ».
- **Frictions** : `doc_project/FRICTIONS.md`, session du 7 juillet (réveil du cluster, ECR immutable,
  ECR hors IaC, lecture des transitions de pods).
- **Captures** : `doc_project/captures/A2-Q3_*` (pods `Running`, `Service` + EXTERNAL-IP, curl ;
  images ECR = capture console à ajouter).

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
  - **Repo ECR créé hors IaC** : le reste du projet est en Terraform ; le repo ECR n'a pas (encore)
    de `aws_ecr_repository`. À intégrer avec le pipeline en Phase 3 pour rester cohérent « tout en IaC ».

## Statut

| | Manifestes | Déploiement EKS | Pipeline CircleCI | Doc | Captures |
|---|---|---|---|---|---|
| A2-Q3 | ✅ versionnés | ✅ manuel (curl OK) | ⏳ 8 juil | 🔶 partie 1 faite | 🔶 ECR à ajouter |
