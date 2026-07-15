# terraform — Infrastructure as Code

Toute l'infrastructure AWS est décrite ici. **Un dossier par composant, chacun avec son
propre state local** (backend S3 laissé commenté — opérateur unique) : cycles de vie
indépendants, blast radius d'un `apply`/`destroy` limité à une brique.

## Composants

| Dossier | Rôle | Détruit chaque soir ? |
|---|---|---|
| `eks/` | VPC + cluster EKS + node group + Access Entry CI | **Oui** (control plane facturé à l'heure) |
| `lambda-login/` | Lambda « login » + API Gateway HTTP API | Non (facturé à l'usage) |
| `ecr/` | Registre d'images `infoline-api` | Non (stockage quasi nul) |
| `iam-ci/` | Utilisateur IAM `infoline-ci` + policy minimale (identité de la CI) | Non |
| `s3-test/` | Bucket bac à sable Phase 0 — **hors architecture applicative** | Non |

## Ordre de dépendance

`ecr/` + `iam-ci/` + `eks/` + `lambda-login/` sont **indépendants entre eux**, mais `ecr/`,
`iam-ci/` et `eks/` doivent exister **avant** le déploiement applicatif par la CI. Chaque
dossier a son propre README de reproduction. Procédure complète et ordonnée : `RUNBOOK.md` §2.

## Réveil / destruction (budget)

```bash
# Réveil d'une session (~15-20 min pour EKS)
cd terraform/eks && terraform apply

# Fin de session — détruire au minimum EKS
cd terraform/eks && terraform destroy   # ⚠️ supprimer d'abord le Service LoadBalancer (k8s/) → ELB orphelin
```

Détail des pièges (ELB orphelin, ordre de destroy) : `RUNBOOK.md` §7-§8.

## Documentation

Rationale IaC (Terraform, isolation par composant, modules communautaires) :
`architecture.md` § « Pourquoi Terraform ». Synthèse : `doc_project/A1-Q1_synthese.md`.
