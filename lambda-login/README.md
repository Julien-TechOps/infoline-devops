# lambda-login — code source de la Lambda « login »

Projet **Maven / Java 21** : le code de la fonction serverless de login InfoLine (hello
world assumé — aucune vraie logique d'authentification, cf. contrainte de non
sur-développement applicatif). Handler : `com.infoline.login.LoginHandler`.

> **À ne pas confondre** avec `terraform/lambda-login/`, qui est l'**IaC** (fonction Lambda
> + API Gateway). Ici = le **code source** ; là-bas = l'infrastructure qui le déploie.
> Terraform ne compile pas le Java : il consomme le **jar déjà buildé** de ce dossier.

## Build

```bash
mvn -f . package          # produit target/lambda-login.jar
```

Le jar est ensuite référencé par `terraform/lambda-login/lambda.tf` (via son hash).
**Rejouer `mvn package` après toute modification du code, avant `terraform apply`** — sinon
Terraform redéploie silencieusement l'ancien jar (cf. `terraform/lambda-login/README.md`).

## Déploiement & test

Voir `terraform/lambda-login/README.md` (provisioning, `curl` sur l'`invoke_url`, invocation
directe `aws lambda invoke`).

## Documentation

Rationale : `architecture.md` § « Service serverless — AWS Lambda (login) ». Synthèse :
`doc_project/A1-Q1_synthese.md` (partie Lambda).
