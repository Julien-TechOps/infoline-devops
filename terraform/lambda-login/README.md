# terraform/lambda-login

Provisionne la fonction Lambda "login" (hello world Java) et son declencheur API Gateway HTTP
API (v2). Composant isole avec son propre state, sur le meme modele que `terraform/eks/` et
`terraform/s3-test/`.

## Contenu

- `versions.tf` — provider `aws` requis + config.
- `variables.tf` — `aws_region`, `function_name`, `jar_path`, `route_path`, `tags`.
- `lambda.tf` — role IAM (moindre privilege), fonction Lambda (jar pre-construit).
- `api_gateway.tf` — HTTP API, integration proxy, route, stage, permission d'invocation.
- `outputs.tf` — `invoke_url`, `function_name`, `function_arn`, `api_endpoint`.
- `terraform.tfvars.example` — a copier en `terraform.tfvars`.

Code source de la Lambda : `../../lambda-login/` (a la racine du repo, au meme niveau que
`appflaskmin/`) — projet Maven Java, classe `com.infoline.login.LoginHandler`.

## Usage

```bash
# 1. Construire le jar (prealable obligatoire, Terraform ne compile pas le Java)
mvn -f ../../lambda-login package

# 2. Provisionner
cd terraform/lambda-login
cp terraform.tfvars.example terraform.tfvars   # completer aws_region
terraform init
terraform plan
terraform apply

terraform output invoke_url
terraform output function_name
```

**Attention :** relancer `mvn package` apres toute modification de `LoginHandler.java`,
avant `terraform apply`. Terraform ne lit jamais le `.java`, seulement le hash du `.jar`
deja sur disque — si le jar n'est pas regenere, `terraform plan` affiche tranquillement
`0 to change` (aucune erreur) et un `apply` redeploierait l'ancien code sans le signaler.

## Tester

```bash
# Via le declencheur HTTP
curl -s "$(terraform output -raw invoke_url)" | jq .

# Invocation directe (sans passer par API Gateway)
aws lambda invoke \
  --function-name "$(terraform output -raw function_name)" \
  --payload '{}' --cli-binary-format raw-in-base64-out \
  response.json && cat response.json
```

## Pourquoi serverless ici (Lambda vs EKS)

Voir `architecture.md`, section "Service serverless — AWS Lambda (login)", pour le detail
et les chiffres. Resume : facturation a l'usage plutot qu'un serveur permanent, coherent
avec le budget limite d'InfoLine et la separation des applications exigee par le sujet.

## Nettoyage

```bash
terraform destroy
```
