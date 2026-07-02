# RUNBOOK — Build / Destroy / Redeploy

## Prérequis
- AWS CLI configuré (`aws sts get-caller-identity` répond), région `eu-west-3`.
- Terraform >= 1.5.
- `kubectl` (cluster EKS).
- Java 21 (OpenJDK) + Maven (build du jar Lambda).
- `jq` (lisibilité des réponses `curl` en test).

## Build complet (from scratch)
Composants indépendants (state Terraform séparé), ordre indifférent entre eux :
1. **EKS** — voir "Cluster EKS — Cycle de vie / Déployer" ci-dessous.
2. **Lambda** — voir "Lambda — Cycle de vie / Déployer" ci-dessous.

## Destroy (fin de session / soir / week-end)
**`terraform/eks` : destroy obligatoire.** Control plane facturé à l'heure (~0.10$/h)
qu'il soit utilisé ou non.

**`terraform/lambda-login` : destroy PAS nécessaire chaque soir.** Lambda + API Gateway
HTTP API sont facturés à l'usage, quasi nul au repos (cf. `architecture.md`). Détruire
seulement en fin de projet ou si inutilisé sur une longue période.

## Vérification post-déploiement
Pour chaque composant : `terraform state list` (ressources trackées) **+** au moins un
appel AWS CLI en lecture directe (`aws lambda get-function`, `aws eks describe-cluster`,
etc.) pour prouver que les ressources existent réellement côté AWS, pas seulement dans
le state. Détail par composant dans les sections "Vérifier" ci-dessous.

---

## Cluster EKS — Cycle de vie

### Déployer
```bash
cd terraform/eks
terraform init          # une seule fois, ou après changement de module
terraform plan -no-color -out=tfplan
terraform show -no-color tfplan > plan.txt   # relire avant d'appliquer
terraform apply tfplan
aws eks update-kubeconfig --region eu-west-3 --name infoline-eks
kubectl get nodes       # vérifier 2 nodes Ready
```

### Vérifier les versions disponibles (à faire si version.tf n'a pas été touché depuis longtemps)
```bash
aws eks describe-cluster-versions \
  --query "clusterVersions[?status=='STANDARD_SUPPORT'].clusterVersion" \
  --output table
```

### Détruire (fin de session — obligatoire)
```bash
cd terraform/eks
terraform destroy
terraform state list    # doit être vide
aws eks list-clusters --region eu-west-3          # doit être vide
aws ec2 describe-nat-gateways --region eu-west-3 \
  --filter "Name=state,Values=available"          # doit être vide
```

### En cas de "deposed object"
Normal. Correspond à un cycle create-before-destroy interrompu. Le prochain `apply` nettoie automatiquement. Ne pas lancer de `terraform destroy` en panique.

---

## Lambda "login" + API Gateway — Cycle de vie

### Déployer
```bash
# 1. Construire le jar AVANT terraform apply (Terraform ne compile pas le Java)
mvn -f lambda-login package

# 2. Provisionner
cd terraform/lambda-login
terraform init          # une seule fois, ou après changement de provider
terraform plan
terraform apply

terraform output invoke_url
terraform output function_name
```

### Tester
```bash
curl -s "$(terraform output -raw invoke_url)" | jq .

aws lambda invoke --function-name "$(terraform output -raw function_name)" \
  --payload '{}' --cli-binary-format raw-in-base64-out response.json && cat response.json
```

### Vérifier (preuve que les ressources existent réellement côté AWS)
```bash
terraform state list
aws lambda get-function --function-name infoline-login --no-cli-pager
aws iam get-role --role-name infoline-login-exec-role --no-cli-pager
aws iam list-attached-role-policies --role-name infoline-login-exec-role --no-cli-pager
aws apigatewayv2 get-apis --query "Items[?Name=='infoline-login-api']" --no-cli-pager
```

### Détruire (pas obligatoire chaque soir — voir "Destroy" plus haut)
```bash
cd terraform/lambda-login
terraform destroy
terraform state list    # doit être vide
```

### Piège à connaître : jar pas régénéré
`terraform plan`/`apply` ne lisent jamais `LoginHandler.java`, seulement le hash du
`.jar` déjà sur disque (`filebase64sha256`). Après toute modification du handler,
relancer `mvn -f lambda-login package` **avant** `terraform apply` — sinon `plan`
affiche `0 to change` sans erreur ni avertissement, et l'ancien code reste déployé.
