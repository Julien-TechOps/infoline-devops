# terraform/ecr — registre d'images

Provisionne le dépôt **ECR `infoline-api`** qui héberge les images de l'API poussées par la
CI. Composant isolé, son propre state (même modèle que `terraform/eks/`).

## Contenu

- `main.tf` — `aws_ecr_repository.api` : `infoline-api`, `image_tag_mutability = IMMUTABLE`
  (un tag ne peut pas être ré-poussé → chaque SHA est figé), `scan_on_push = false`.

## Note d'historique (import)

Le dépôt a d'abord été créé **hors Terraform** (urgence du premier déploiement manuel en
Phase 3), puis réintégré à l'IaC par `terraform import`. Contrairement à EKS, ECR n'a **pas**
de cycle destroy/apply par session (stockage quasi nul) : l'IaC sert ici la **traçabilité et
la reproductibilité** du run final, pas une discipline de coût quotidienne.

## Usage

```bash
cd terraform/ecr
terraform init && terraform apply
terraform output   # URL du dépôt
```

## Documentation

Rationale : `architecture.md` § « Pourquoi ECR en IaC ». Provisioning ordonné : `RUNBOOK.md`
§2. Le tag = SHA court et l'immuabilité sont expliqués § « Déploiement de l'API sur EKS ».
