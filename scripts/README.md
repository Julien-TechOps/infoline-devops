# scripts — reconstruction centralisée (RTO)

> ⚠️ **BROUILLON Phase 5 — NON testé de bout en bout.**
> Ces scripts orchestrent en un point ce que `RUNBOOK.md` décrit pas-à-pas (procédure, elle,
> **validée manuellement**). Ils n'ont pas encore tourné en conditions réelles : la
> validation — et la **mesure effective du RTO** — est prévue au run final du **22 juil**.
> **Ne pas communiquer de chiffre de RTO** tant que `rebuild.sh` n'a pas été exécuté en vrai.
> Le chemin de référence garanti reste `RUNBOOK.md`.

## Pourquoi

Un DevOps doit pouvoir **chiffrer le temps de remise en route** de l'infra après incident
(RTO — Recovery Time Objective). Ces scripts rejouent `apply` / `destroy` dans le bon ordre
de dépendance et **mesurent le temps de reconstruction**, plutôt que de dérouler le RUNBOOK
à la main. Cf. `architecture.md` § « Pourquoi un script de reconstruction centralisé (RTO) ».

## Scripts

| Script | Rôle |
|---|---|
| `rebuild.sh` | Reconstruit toute l'infra IaC (ECR, IAM-CI, Lambda, EKS) et **chronomètre** le run. |
| `teardown.sh` | Détruit l'infra. Par défaut : **EKS seul** (destroy quotidien). `--full` : tout. |

Les deux exigent une **confirmation explicite** (ou `-y` / `--yes`) — `terraform apply`/`destroy`
coûtent de l'argent et détruisent des ressources.

## Prérequis

Identiques au RUNBOOK §1 : `aws` (compte à droits larges, région `eu-west-3`), `terraform` ≥ 1.6,
`kubectl`, `mvn` (build du jar Lambda). Lancer **depuis la racine du repo**.

```bash
./scripts/rebuild.sh            # reconstruction complète (confirmation demandée)
./scripts/rebuild.sh --yes      # sans confirmation
./scripts/teardown.sh           # destroy EKS quotidien
./scripts/teardown.sh --full -y # destroy total (fin de projet)
```

Variables surchargeables : `AWS_REGION` (défaut `eu-west-3`), `CLUSTER_NAME` (défaut
`infoline-eks`).

## Limites connues (à lever au run du 22 juil)

- **Déploiement de l'API** : le chemin **nominal** est un `git push` sur `main` (CI GitHub
  Actions). `rebuild.sh` reconstruit l'infra puis **rappelle** ce push ; il propose en option
  (`--deploy-api-manual`) le déploiement manuel du RUNBOOK §4 à partir de la dernière image ECR.
- **Séquentiel** : EKS (~15-20 min) est lancé après les autres briques. Le paralléliser
  réduirait le RTO horloge — optimisation volontairement non faite tant que le script n'est pas
  validé.
- **Kubeconfig** : chaque reconstruction du cluster change l'endpoint → `rebuild.sh` refait
  `aws eks update-kubeconfig` (piège RUNBOOK §8).
- **ELB orphelin** : `teardown.sh` fait `kubectl delete -f k8s/` avant le destroy EKS (RUNBOOK §7).
