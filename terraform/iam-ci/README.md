# terraform/iam-ci — identité IAM de la CI (moindre privilège)

Provisionne l'utilisateur IAM **`infoline-ci`** dont se sert la CI/CD pour pousser sur ECR et
mettre à jour le Deployment sur EKS. Distinct du compte à droits larges qui pilote Terraform :
si les clés CI fuitent, le **blast radius est limité**.

## Contenu

- `main.tf` :
  - `aws_iam_user.ci` (`infoline-ci`) + `aws_iam_access_key` (**clés statiques**).
  - Policy inline minimale : push/pull ECR + `eks:DescribeCluster` — **rien d'autre**.
  - Outputs `ci_access_key_id` / `ci_secret_access_key` (**sensibles**).

Le **pont IAM → RBAC Kubernetes** (pour que `kubectl` de la CI soit autorisé *dans* le
cluster) est une **Access Entry** définie côté `terraform/eks/` (`access-entries.tf`,
policy `AmazonEKSEditPolicy`), pas ici.

## Usage

```bash
cd terraform/iam-ci
terraform init && terraform apply

# Récupérer les credentials → à mettre dans les secrets GitHub Actions
terraform output -raw ci_access_key_id
terraform output -raw ci_secret_access_key   # AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY
```

## Documentation

Rationale (moindre privilège, IAM vs RBAC, Access Entry vs `aws-auth`, OIDC non retenu) :
`architecture.md` § « Pourquoi un utilisateur IAM CI dédié » et « Amélioration de production
non retenue : OIDC ». Provisioning ordonné + secrets GitHub : `RUNBOOK.md` §2.
