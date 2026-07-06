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

---

## API Spring Boot (Docker) — Cycle de vie

Tout est **local** : aucun appel ni coût AWS, donc **aucun `terraform destroy`** à prévoir pour ce
composant. (Le push vers ECR et le déploiement EKS arrivent en Phase 3.)

### Prérequis
- Docker. Le build compile le jar *dans* l'image via `maven:3.9-eclipse-temurin-21` — pas besoin de
  Maven sur l'hôte pour construire l'image.

### Construire l'image
```bash
cd api
docker build -t infoline-api:local .
```

### Lancer et tester
```bash
docker run -d -p 8080:8080 --name infoline-api infoline-api:local
docker ps                        # vérifier le mapping 0.0.0.0:8080->8080/tcp
docker logs infoline-api         # vérifier "Started ApiApplication ... in X seconds"
curl -i http://localhost:8080/hello   # attendu : HTTP 200, "Hello from InfoLine API"
```

### Nettoyer (entre deux itérations sur le Dockerfile)
```bash
docker stop infoline-api && docker rm infoline-api
```

### Lancer sans Docker (débogage applicatif rapide)
```bash
cd api
mvn spring-boot:run                                   # mode dev
# ou la forme exacte exécutée dans le conteneur :
mvn package -DskipTests && java -jar target/*.jar
```

### Pas de piège « jar périmé » ici (contraste avec la Lambda)
Contrairement à la Lambda (où Terraform ne relit que le hash d'un jar déjà buildé — voir plus haut),
`docker build` **recompile** le jar depuis `src/` à chaque build : impossible de builder une image
avec du code périmé. Le seul cache en jeu est celui des couches Docker, qui s'invalide correctement
dès qu'un fichier de `src/` change.

## Fronts Angular (Docker) — Cycle de vie

Comme l'API Spring Boot : tout est **local**, aucun coût ni appel AWS, donc **aucun `terraform
destroy`** à prévoir. Deux apps au cycle identique : `frontend` (port 8081) et `backoffice` (8082).

### Prérequis
- Node.js 24 (LTS) + npm pour tester hors conteneur (`ng serve`, `ng build`). Le build définitif se
  fait *dans* l'image via `node:24-alpine`.
- Docker.

### Construire les images
```bash
cd apps/frontend   && docker build -t infoline-frontend:local .
cd ../backoffice   && docker build -t infoline-backoffice:local .
```

### Lancer et tester
```bash
docker run -d -p 8081:80 --name infoline-frontend  infoline-frontend:local
docker run -d -p 8082:80 --name infoline-backoffice infoline-backoffice:local
docker ps                                          # mappings 8081->80 et 8082->80
curl -s http://localhost:8081 | grep '<title>'     # <title>Frontend</title>
curl -s http://localhost:8082 | grep '<title>'     # <title>Backoffice</title>
```

### Nettoyer
```bash
docker rm -f infoline-frontend infoline-backoffice
```

### La preuve « parlante » est une capture navigateur, pas curl
L'app est en **CSR pur** (pas de SSR, choix assumé) : la réponse HTTP de nginx ne contient que la
coquille `<app-root></app-root>` + un `<script>`. Le texte « Hello from InfoLine » n'est injecté dans
le DOM qu'**après** exécution du JS par le navigateur — `curl` ne peut donc pas l'afficher (contraste
avec l'API Spring Boot, qui calcule le texte côté serveur). Preuve retenue :
`A2-Q4_docker-ps-browser.png` (les deux pages rendues + `docker ps`). `curl … | grep '<title>'`
prouve seulement que **deux pages différentes** sont servies, pas que le hello world s'affiche.

### Piège : le dossier `browser`
`ng build` écrit dans `dist/<projet>/browser/`, pas `dist/<projet>/`. Un `COPY` sans `/browser`
copie une arborescence en trop et casse le site.

### Piège cousin du « jar périmé » : node_modules
Ne jamais copier `node_modules` depuis l'hôte (binaires natifs esbuild/Rollup spécifiques à
l'OS/arch — un `node_modules` généré sous WSL/Windows copié dans Alpine casse le build de façon peu
lisible). Le `.dockerignore` exclut `node_modules`, et `npm ci` le régénère **dans** le conteneur
avec les bons binaires.

### Piège : `.git` imbriqué
Générer une app avec `ng new … --skip-git` : le repo `infoline-devops` est déjà versionné, sans ce
flag `ng new` initialise un second `.git` imbriqué dans `apps/frontend`.

### Piège d'environnement : mise à jour de Docker Desktop en session
Un update de Docker Desktop peut rendre les conteneurs invisibles pour `docker ps -a`/`docker images`
(le CLI se reconnecte à un moteur neuf) alors qu'ils répondent encore sur leurs ports (ancien moteur
toujours actif). Fix : **quitter complètement puis relancer Docker Desktop**. Ne pas mettre à jour
Docker Desktop pendant qu'un conteneur — ou pire un `terraform apply` — tourne.
