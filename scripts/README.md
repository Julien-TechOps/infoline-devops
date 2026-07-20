# scripts — reconstruction centralisée de l'infrastructure

> ⚠️ **Statut : non validé en conditions réelles.**
> Ces scripts orchestrent en un seul point ce que `RUNBOOK.md` décrit pas-à-pas — cette
> procédure manuelle étant, elle, **validée**. Les scripts n'ont pas encore été exécutés de
> bout en bout ; leur validation est prévue au run du **22 juillet 2026**.
>
> Le chemin de référence garanti reste `RUNBOOK.md`.

## Pourquoi

L'infrastructure est détruite chaque soir (les nœuds EKS sont facturés à l'heure). Elle doit
donc pouvoir être **reconstruite intégralement, dans le bon ordre, sans intervention
manuelle** — c'est la contrepartie de cette discipline, et la démonstration la plus directe
de ce qu'apporte l'infrastructure as code.

Ces scripts rejouent `apply` / `destroy` dans l'ordre de dépendance (ECR → IAM-CI → Lambda
→ EKS) et prennent en charge deux pièges que le RUNBOOK ne décrit qu'en prose : la
recompilation du jar Lambda **avant** le `terraform apply`, et le rafraîchissement du
kubeconfig après recréation du cluster.

Cf. `architecture.md` § « Pourquoi un script de reconstruction centralisé ».

## Sur la durée affichée

`rebuild.sh` affiche le temps écoulé, **à titre indicatif d'exploitation**. Ce n'est pas un
RTO : une garantie de temps de reprise supposerait un objectif de perte de données associé
(RPO), or la supervision utilise un stockage éphémère et l'état Terraform est local, sans
sauvegarde. Aucun engagement de reprise après sinistre n'est formulé sur ce périmètre.

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
  raccourcirait la reconstruction — optimisation volontairement non faite tant que le script
  n'est pas validé.
- **Kubeconfig** : chaque reconstruction du cluster change l'endpoint → `rebuild.sh` refait
  `aws eks update-kubeconfig` (piège RUNBOOK §8).
- **ELB orphelin** : `teardown.sh` fait `kubectl delete -f k8s/` avant le destroy EKS (RUNBOOK §7).
