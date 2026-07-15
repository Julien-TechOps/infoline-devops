# A1-Q1 — Automatisation du déploiement d'infrastructure Cloud

*Cluster Kubernetes + service serverless, tous deux en Terraform. Statut au 2 juillet 2026.*

## Réponse apportée

- **Cluster Kubernetes** : Amazon EKS managé (VPC dédié 2 AZ, node group géré — `t3.micro`
  en Phase 1, puis `m7i-flex.large` en Phase 4 pour héberger Elasticsearch ; cf.
  `architecture.md` § « Pourquoi t3.micro » et « Pourquoi m7i-flex.large »),
  provisionné et détruit proprement en Terraform.
- **Service serverless** : Lambda "login" (Java 21) + API Gateway HTTP API, provisionnée
  en Terraform, invocation validée par `curl` et `aws lambda invoke`.

## Preuves

**EKS**
- Code : `terraform/eks/`
- Captures : `doc_project/captures/A1-Q1_terraform-apply-and-kubectl-get-nodes.md`,
  `A1-Q1_terraform-destroy-and-verification.md`, `A1-Q1_eks-console.png`
- Reproduction : `terraform/eks/README.md`

**Lambda**
- Code : `terraform/lambda-login/` (Terraform) + `lambda-login/` (Java/Maven, racine du
  repo)
- Captures : `doc_project/captures/A1-Q1_lambda-terraform-apply-output-CLI-validation.md`
  (apply, curl, invoke direct, `terraform state list`, `aws lambda get-function`,
  `aws iam get-role`/`list-attached-role-policies`, `aws apigatewayv2 get-apis` —
  preuve complète que les ressources existent réellement côté AWS, pas seulement dans
  le state), `A1-Q1_lambda-console-aws.png`, `A1-Q1_lambda-console-aws-synoptics.png`
- Reproduction : `terraform/lambda-login/README.md`

## Pourquoi ces choix

Détail complet dans `architecture.md`, sections "Cluster Kubernetes — Amazon EKS" et
"Service serverless — AWS Lambda (login)".

Phrases réutilisables pour la copie :

- *"Le cluster Kubernetes a été provisionné via Amazon EKS plutôt qu'un déploiement
  kubeadm auto-géré, pour déléguer la gestion du control plane à AWS et concentrer
  l'effort DevOps sur le node group et les workloads."*
- *"Le service de login a été provisionné en AWS Lambda plutôt qu'en serveur permanent
  afin d'aligner le coût d'infrastructure sur l'usage réel, conformément au budget
  limité fixé par la direction InfoLine, tout en bénéficiant d'une scalabilité
  automatique en cas de pic de trafic."*

## Conformité

- **Fiches Studi mobilisées** :
  - **B1 P4** (déployer automatiquement une infrastructure) : plan lu avant apply,
    composants isolés (state séparé EKS/Lambda) plutôt que copié-collé.
  - **B1 P7** (mettre une infrastructure en production Cloud) : triptyque Terraform
    *code, plan, preuve de résultat* ; services AWS managés (EKS, Lambda, API Gateway).
  - **B1 P5** (sécuriser son infrastructure) : nodes EKS en subnets privés + IAM délégué
    au module côté EKS ; rôle d'exécution Lambda au moindre privilège
    (`AWSLambdaBasicExecutionRole` uniquement) côté serverless.
- **Écart assumé** : le hello-world Lambda ne vérifie aucun identifiant réel (cf.
  contrainte de non sur-développement du code applicatif sur ce projet) — la logique de
  login arrive en Phase 2, ce n'est pas un livrable noté de cette question.

## Statut

| | Infra | Doc | Captures |
|---|---|---|---|
| EKS | ✅ | ✅ | ✅ |
| Lambda | ✅ | ✅ | ✅ |
