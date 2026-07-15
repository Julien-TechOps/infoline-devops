# RUNBOOK — Déploiement de bout en bout (infra IaC → CI/CD)

Procédure complète et reproductible : provisionner l'infrastructure en Terraform, puis
déployer l'API en continu via GitHub Actions. Sert deux objectifs : **rejouer le run final**
(dépôt du 22 juil) et **valider la Phase 3** (les étapes portant un marqueur 📸 / 💾 produisent
une preuve à déposer dans `doc_project/captures/`).

> **Marqueurs de preuve**
> 📸 **Capture** = screenshot à enregistrer. 💾 **Transcript** = sortie terminal à coller dans un `.md`.
> ⚠️ **Floutage systématique** de l'`ACCOUNT_ID` (12 chiffres) → `<ACCOUNT_ID>` et **jamais** de clé
> réelle dans une capture (cf. `doc_project/FRICTIONS.md`, F7 + rotation clé `infoline-ci`).
> Récupérer l'account ID : `aws sts get-caller-identity --query Account --output text`.

---

## 0. Vue d'ensemble

| Composant | Module Terraform | Détruit chaque soir ? | Rôle |
|---|---|---|---|
| VPC + Cluster EKS + Access Entry CI | `terraform/eks/` | **OUI** (facturé à l'heure) | Exécute l'API |
| Registre d'images ECR | `terraform/ecr/` | non (stockage quasi nul) | Stocke les images de l'API |
| Utilisateur IAM `infoline-ci` | `terraform/iam-ci/` | non (sinon clés à re-régler) | Identité du pipeline CI |
| Lambda login + API Gateway | `terraform/lambda-login/` | non (facturé à l'usage) | Login serverless (indépendant) |

**Deux chemins de déploiement de l'API :**
- **Nominal — CI/CD (§3)** : un push sur `main` déclenche GitHub Actions (build/test → push ECR →
  substitution de l'image + `kubectl apply` → `rollout status`).
- **Secours — manuel (§4)** : `kubectl apply` à la main. Pour debug ou pipeline indisponible.

**Dépendances pour que le CI/CD fonctionne :** cluster EKS **UP** + ECR + Access Entry CI (incluse
dans l'apply EKS) + secrets GitHub renseignés. Le Lambda est indépendant (login), sans lien avec le
déploiement de l'API.

**Réveil de session :** EKS est détruit chaque soir → chaque matin, `terraform apply` dans
`terraform/eks/` (**~15-20 min**) **avant** tout `kubectl` ou tout déclenchement du pipeline.

---

## 1. Prérequis

- **AWS CLI** configuré (compte `terraform-ecf`, droits larges), région `eu-west-3` —
  `aws sts get-caller-identity` répond.
- **Terraform** ≥ 1.6.
- **kubectl** (pilotage du cluster EKS).
- **Docker** (build local des images ; le CI build les siennes).
- **Java 21 (OpenJDK) + Maven** (build du jar Lambda ; build local optionnel de l'API).
- **Node.js 24 + npm** (build/test local optionnel des fronts).
- **jq** *(optionnel — confort de lecture des réponses `curl` ; les tests passent sans)*.
- **Accès GitHub** au repo + droit de gérer les *Actions secrets* (pour le CI, §2.3). `gh` CLI pratique.

---

## 2. Provisionner l'infrastructure (IaC)

States Terraform **séparés** (un par module). Les composants sont indépendants ; l'ordre entre eux
est libre. Pour **activer le CI/CD**, il faut au minimum **ECR (§2.1) + IAM-CI (§2.2) + secrets (§2.3)
+ EKS (§2.4)**. Le Lambda (§2.5) est optionnel pour le déploiement de l'API.

### 2.1 ECR — registre d'images (permanent, ne PAS détruire chaque soir)
Le repo `infoline-api` existe déjà côté AWS (créé hors IaC en Phase 3, puis **adopté** par le bloc
`import` de `terraform/ecr/main.tf`). L'apply est idempotent si le state est présent.
```bash
cd terraform/ecr
terraform init
terraform plan          # attendu : 0 to change (repo déjà adopté) ; sinon adoption via import
terraform apply
```
Vérifier :
```bash
aws ecr describe-repositories --repository-names infoline-api --region eu-west-3 --no-cli-pager
```
> Facturé au stockage (quasi nul) : **jamais** de `terraform destroy` quotidien. Tags **immuables** :
> un tag ne peut pas être ré-poussé → un tag neuf par build (SHA court du commit).

### 2.2 Utilisateur IAM CI `infoline-ci` (permanent)
Crée l'utilisateur, sa clé d'accès et sa policy minimale (push/pull ECR + `eks:DescribeCluster`).
```bash
cd terraform/iam-ci
terraform init
terraform apply
```
Récupérer les identifiants (à reporter dans les secrets GitHub, §2.3) :
```bash
terraform output ci_access_key_id
terraform output -raw ci_secret_access_key   # ⚠️ secret — ne jamais committer ni capturer
```
Vérifier :
```bash
aws iam get-user --user-name infoline-ci --no-cli-pager
```
> Ne PAS détruire chaque soir : un destroy régénère des clés → il faudrait re-renseigner les secrets
> GitHub à chaque cycle.

### 2.3 Secrets GitHub (une seule fois, ou après rotation de clé)
Repo GitHub → **Settings → Secrets and variables → Actions**, créer trois secrets consommés par
`.github/workflows/deploy.yml` :
- `AWS_ACCESS_KEY_ID` = sortie `ci_access_key_id` (§2.2)
- `AWS_SECRET_ACCESS_KEY` = sortie `ci_secret_access_key` (§2.2)
- `AWS_ACCOUNT_ID` = l'account ID (12 chiffres)

En CLI (équivalent) :
```bash
gh secret set AWS_ACCESS_KEY_ID     -b "$(cd terraform/iam-ci && terraform output -raw ci_access_key_id)"
gh secret set AWS_SECRET_ACCESS_KEY -b "$(cd terraform/iam-ci && terraform output -raw ci_secret_access_key)"
gh secret set AWS_ACCOUNT_ID        -b "$(aws sts get-caller-identity --query Account --output text)"
```

### 2.4 Cluster EKS + VPC + Access Entry CI (DÉTRUIT chaque soir)
Vérifier d'abord les versions supportées si `versions.tf`/`terraform.tfvars` n'a pas été touché depuis
longtemps :
```bash
aws eks describe-cluster-versions \
  --query "clusterVersions[?status=='STANDARD_SUPPORT'].clusterVersion" --output table
```
Provisionner (~15-20 min : control plane ~10-15 min, puis le node group rejoint) :
```bash
cd terraform/eks
terraform init                               # une seule fois, ou après changement de module
terraform plan -no-color -out=tfplan
terraform show -no-color tfplan > plan.txt   # relire avant d'appliquer
terraform apply tfplan
aws eks update-kubeconfig --region eu-west-3 --name infoline-eks
kubectl get nodes                            # attendu : 2 nodes Ready (v1.34)
```
Cet apply crée **aussi** l'Access Entry de `infoline-ci` (`terraform/eks/access-entries.tf`,
policy `AmazonEKSEditPolicy`) : le pipeline CI est autorisé côté RBAC **automatiquement**, sans
commande manuelle. Vérifier :
```bash
aws eks list-access-entries --cluster-name infoline-eks --region eu-west-3 --no-cli-pager
# doit lister le principal .../infoline-ci en plus des rôles de service et de terraform-ecf
```
> **Nodes en `t3.micro`** (t3.medium indisponible sur ce compte) = 4 pods/node max — d'où
> `maxSurge: 0` sur le Deployment (cf. §8 et FRICTIONS F10).

### 2.5 Lambda login + API Gateway (permanent, indépendant)
Le jar doit être **compilé avant** l'apply (Terraform ne compile pas le Java) :
```bash
mvn -f lambda-login package
cd terraform/lambda-login
terraform init
terraform plan
terraform apply
terraform output invoke_url
terraform output function_name
```
Tester :
```bash
curl -s "$(terraform output -raw invoke_url)"; echo    # JSON brut ; ajouter « | jq . » si jq installé
aws lambda invoke --function-name "$(terraform output -raw function_name)" \
  --payload '{}' --cli-binary-format raw-in-base64-out response.json && cat response.json
```
> Facturé à l'usage (quasi nul au repos) : destroy **seulement** en fin de projet (voir §7).

---

## 3. Déploiement continu de l'API (CI/CD — chemin nominal)

Le déploiement de l'API sur EKS est **automatisé** par `.github/workflows/deploy.yml`. Aucune commande
`kubectl` à taper à la main dans le flux nominal.

### 3.1 Déclenchement et séquence du pipeline
Tout **push sur `main`** lance deux workflows :
- **`Deploy API to EKS`** (`deploy.yml`) : `build-test` (`mvn verify`) → `build-push-deploy`
  (configure AWS creds → login ECR → `docker build`/tag = SHA court/push → `aws eks update-kubeconfig`
  → substitution de l'image (`IMAGE_PLACEHOLDER` → `<ECR>/infoline-api:<SHA>`) → `kubectl apply -f k8s/`
  → `kubectl rollout status --timeout=240s`, garde-fou qui fait échouer le job si le déploiement ne
  converge pas).
- **`Build & Test Angular Apps`** (`angular.yml`) : matrice `frontend`/`backoffice`, `npm ci` →
  `npx ng build` → `npx ng test --watch=false`. **Pas de déploiement** (le sujet A2-Q5 s'arrête à
  build/test).

### 3.2 Prérequis d'un déploiement réussi
- Cluster EKS **UP** (§2.4) — sinon `update-kubeconfig`/`kubectl` échouent.
- ECR + Access Entry CI présents (§2.1 / §2.4) + secrets GitHub (§2.3).
- Sur un cluster fraîchement recréé (matin), il est **vide** : le premier run du pipeline substitue
  l'image (`IMAGE_PLACEHOLDER` → ECR au SHA courant) puis crée le Deployment/Service
  (`kubectl apply -f k8s/`).

### 3.3 Séquence de validation Phase 3 (à filmer, cluster UP)

**Étape 0 — cluster prêt** (§2.4 : `kubectl get nodes` → 2 Ready).

**Étape 1 — premier déploiement (état initial stable)**
- Déclencher un run : push d'un commit (ou *Re-run* du workflow depuis l'onglet Actions).
- Attendre les **deux workflows verts**.
  - 📸 **Capture** `A2-Q3_pipeline-green.png` — run *Deploy API to EKS* vert.
  - 📸 **Capture** `A2-Q5_pipeline-green.png` — run *Build & Test Angular Apps* vert (matrice 2 apps).
  - 📸 **Capture** `A2-Q5_build-test-logs.png` — logs des steps *Build* + *Run tests* (`ng build` /
    `ng test --watch=false`) des deux apps.
- Noter l'état initial :
  ```bash
  kubectl get pods -o wide         # relever le hash ReplicaSet (image SHA « A »)
  ```

**Étape 2 — film du rolling update (déploiement frais)**
> Un rolling update n'est visible qu'au **2ᵉ** déploiement (l'état initial doit être stable). D'où
> l'étape 1 puis un commit no-op ici.
- Commit **no-op** (ex. bump d'un commentaire) + push `main` → nouvelle image (SHA « B »).
- Filmer la bascule dans un même terminal :
  ```bash
  kubectl get pods -w                                   # nouveau hash monte, ancien descend
  kubectl rollout status deployment/infoline-api        # → « successfully rolled out »
  ```
  - 💾 **Transcript** `A2-Q3_rollout-transcript.md` — avant / pendant / après, **hash ReplicaSet qui
    change** (SHA A → SHA B) + `successfully rolled out`.
  - 📸 **Capture** *(optionnel, renforce)* `A2-Q3_deploy-job-logs.png` — logs des steps
    *Substitute image and apply manifests* + *Wait for rollout to complete*.

**Étape 3 — preuve fonctionnelle (le service répond après déploiement auto)**
```bash
kubectl get svc infoline-api                 # relever l'EXTERNAL-IP (hostname ELB)
curl http://<elb-dns>/hello                  # attendu : Hello from InfoLine API
```
- 💾 **Transcript** `A2-Q3_curl-after-deploy.md` — `curl` → `Hello from InfoLine API`.
- ⚠️ Flouter l'`ACCOUNT_ID` dans **toutes** ces captures/transcripts avant dépôt.

---

## 4. Déploiement manuel de l'API (secours / référence)

À utiliser si le pipeline est indisponible, ou pour du debug. **Cluster UP requis** (§2.4).
```bash
# Le manifeste versionné porte IMAGE_PLACEHOLDER (pas d'ACCOUNT_ID en dur). Substituer l'image réelle
# à l'apply — repo ECR + tag = SHA court d'un commit déjà présent sur ECR (sinon, laisser le CI/CD la produire) :
IMAGE=<ACCOUNT_ID>.dkr.ecr.eu-west-3.amazonaws.com/infoline-api:<SHA>
sed "s|IMAGE_PLACEHOLDER|$IMAGE|" k8s/api-deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/api-service.yaml

kubectl get pods -w                    # attendre 2/2 Running, puis Ctrl-C
kubectl get endpoints infoline-api     # doit lister 2 IP:8080 (preuve que les labels matchent)
kubectl get svc infoline-api -w        # attendre l'EXTERNAL-IP (<pending> ~1-3 min), puis Ctrl-C
curl http://<external-ip-ou-hostname>/hello   # attendu : Hello from InfoLine API
```
> Le chemin **nominal** est le CI/CD (§3). Cette section est le fallback. Ne pas oublier le
> `kubectl delete -f k8s/` avant le `terraform destroy` du soir (ELB hors IaC — §7).

---

## 4bis. Déploiement de la supervision ELK (A3 — manuel, hors CI/CD)

Déployé **à la main**, jamais par le pipeline de l'API : les manifests sont dans `k8s/elk/` (pas `k8s/`,
que la CI applique en entier). Prérequis : cluster **UP** avec des nœuds **≥ 4 GiB** — le node group est
en `m7i-flex.large` / `c7i-flex.large` (types **Free Tier eligible**, cf. §8 le piège des types non
éligibles au lancement).

```bash
# 1. Opérateur ECK — CRD via `create` (le fichier CRD dépasse la limite d'annotation de `apply`), opérateur via `apply`
kubectl create -f https://download.elastic.co/downloads/eck/3.4.1/crds.yaml
kubectl apply  -f https://download.elastic.co/downloads/eck/3.4.1/operator.yaml
kubectl -n elastic-system get pods                          # elastic-operator-0 → Running

# 2. Elasticsearch (single-node, emptyDir)
kubectl apply -f k8s/elk/elasticsearch.yaml
kubectl get elasticsearch                                   # 📸 A3-Q1 : HEALTH green, PHASE Ready

# 3. Filebeat (DaemonSet — 1 pod par nœud)
kubectl apply -f k8s/elk/filebeat.yaml
kubectl get beat                                            # HEALTH green, AVAILABLE 2 / EXPECTED 2
kubectl get pods -l beat.k8s.elastic.co/name=infoline-filebeat -o wide   # 📸 A3-Q1 : 1 pod/nœud

# 4. Kibana (connecté à Elasticsearch par ECK)
kubectl apply -f k8s/elk/kibana.yaml
kubectl get kibana                                        # HEALTH green, NODES 1
kubectl get pods -l kibana.k8s.elastic.co/name=infoline-kibana   # 1/1 Running
PW=$(kubectl get secret infoline-es-es-elastic-user -o go-template='{{.data.elastic | base64decode}}')
kubectl port-forward service/infoline-kibana-kb-http 5601 # terminal dédié (bloquant)
# Navigateur : https://localhost:5601 ; login elastic + mot de passe PW
# Kibana : data view filebeat-* avec @timestamp, puis Discover

# 5. Vérification + preuve de connexion ES (port-forward + curl ; certificat auto-signé → -k)
kubectl port-forward service/infoline-es-es-http 9200       # tunnel local, dans un terminal dédié (bloquant)
curl -k -u elastic:$PW https://localhost:9200/_cluster/health?pretty                 # 💾 status green
curl -k -u elastic:$PW "https://localhost:9200/_cat/indices/filebeat-*?v"            # 💾 index filebeat, docs>0
curl -k -u elastic:$PW "https://localhost:9200/filebeat-*/_search?q=kubernetes.pod.name:infoline-es*&size=1&pretty"  # 💾 log enrichi kubernetes.*
```
> ⚠️ **Floutage** : la réponse `_search` contient l'Account ID (`cloud.account.id` + ARN `orchestrator.cluster.id`) → remplacer par `<ACCOUNT_ID>` avant toute capture.
> ⚠️ **`kubectl get … -w`** : le flag *watch* bloque le terminal — `Ctrl+C` avant d'enchaîner (sinon les commandes suivantes ne s'exécutent pas ; cf. FRICTIONS session 13 juil).
> Données ES en `emptyDir` : perdues à chaque `destroy` — **normal**, ces manifests se réappliquent au réveil suivant (Filebeat ré-ingère en quelques minutes).

---

## 5. Cycles de vie locaux (dev, hors AWS — aucun coût)

Utiles pour valider l'applicatif **hors** chaîne AWS (A2-Q1/Q2 et A2-Q4). Aucun `terraform destroy`
à prévoir.

### 5.1 API Spring Boot (Docker)
```bash
cd api
docker build -t infoline-api:local .
docker run -d -p 8080:8080 --name infoline-api infoline-api:local
docker ps                              # mapping 0.0.0.0:8080->8080/tcp
docker logs infoline-api               # « Started ApiApplication ... »
curl -i http://localhost:8080/hello    # HTTP 200, « Hello from InfoLine API »
docker stop infoline-api && docker rm infoline-api   # nettoyage
```
> `docker build` **recompile** le jar depuis `src/` à chaque build : pas de piège « jar périmé »
> (contraste avec la Lambda, §8).

**Lancer sans Docker (débogage applicatif rapide, prouve l'app sur son port — A2-Q1) :**
```bash
cd api
mvn spring-boot:run                                   # mode dev
# ou la forme exacte exécutée dans le conteneur :
mvn package -DskipTests && java -jar target/*.jar
```

### 5.2 Fronts Angular (Docker)
```bash
cd apps/frontend   && docker build -t infoline-frontend:local .
cd ../backoffice   && docker build -t infoline-backoffice:local .
docker run -d -p 8081:80 --name infoline-frontend  infoline-frontend:local
docker run -d -p 8082:80 --name infoline-backoffice infoline-backoffice:local
docker ps                                          # mappings 8081->80 et 8082->80
curl -s http://localhost:8081 | grep '<title>'     # <title>Frontend</title>
curl -s http://localhost:8082 | grep '<title>'     # <title>Backoffice</title>
docker rm -f infoline-frontend infoline-backoffice # nettoyage
```
> **CSR pur** : la preuve « parlante » du hello world est une **capture navigateur**, pas un `curl`
> (le texte est injecté par le JS après chargement). Cf. `A2-Q4_docker-ps-browser.png`.

---

## 6. Vérification post-déploiement (preuve d'existence réelle côté AWS)

Pour chaque composant : `terraform state list` **+** au moins un appel AWS CLI en lecture directe
(pas seulement le state).
```bash
# EKS
cd terraform/eks && terraform state list
aws eks describe-cluster --name infoline-eks --region eu-west-3 --query "cluster.status" --no-cli-pager
# ECR
aws ecr describe-repositories --repository-names infoline-api --region eu-west-3 --no-cli-pager
# IAM-CI
aws iam get-user --user-name infoline-ci --no-cli-pager
# Lambda
aws lambda get-function --function-name infoline-login --no-cli-pager
aws apigatewayv2 get-apis --query "Items[?Name=='infoline-login-api']" --no-cli-pager
```

---

## 7. Détruire (fin de session / soir / week-end)

**`terraform/eks` : destroy OBLIGATOIRE chaque soir** (control plane ~0,10 $/h + nodes EC2).
**Si l'API est déployée** (Service `type: LoadBalancer`) : `kubectl delete -f k8s/` **avant** le
destroy — le Classic Load Balancer est créé **hors** état Terraform ; le laisser tourner laisse un ELB
orphelin dont les ENIs peuvent bloquer la suppression du VPC.
**Si la supervision ELK est déployée** : Elasticsearch et Kibana s'accèdent tous deux par `port-forward` ;
aucun Service `LoadBalancer` n'est créé. `terraform destroy` seul suffit (nœuds supprimés → pods ELK
supprimés, données `emptyDir` perdues = normal). Si ce choix change un jour, tout Service `LoadBalancer`
ELK devra être supprimé avant le destroy.
```bash
kubectl delete -f k8s/                 # uniquement si l'API a été déployée sur ce cluster
kubectl delete -f k8s/elk/             # uniquement si un Service LoadBalancer ELK a été ajouté
cd terraform/eks
terraform destroy
terraform state list                   # doit être vide
aws eks list-clusters --region eu-west-3                                   # doit être vide
aws ec2 describe-nat-gateways --region eu-west-3 \
  --filter "Name=state,Values=available"                                  # doit être vide
```
**`ecr` / `iam-ci` / `lambda-login` : PAS de destroy quotidien** (stockage/usage quasi nul). Détruire
**seulement en fin de projet** :
```bash
cd terraform/lambda-login && terraform destroy   # login serverless
cd ../ecr                 && terraform destroy   # ⚠️ supprime les images poussées
cd ../iam-ci              && terraform destroy   # ⚠️ invalide les clés → secrets GitHub à re-régler
```
> `terraform/s3-test/` (bucket de test Phase 0) : détruire s'il traîne encore
> (`cd terraform/s3-test && terraform destroy`).

---

## 8. Pièges connus (consolidés)

- **Réveil du cluster ~15-20 min** avant tout `kubectl`/CI : à budgéter chaque matin après le destroy.
- **`deposed object` (EKS)** : normal (cycle create-before-destroy interrompu), le prochain `apply`
  nettoie. Ne pas paniquer avec un `destroy`.
- **Rolling update sur `t3.micro`** : `maxSurge: 0` / `maxUnavailable: 1` (4 pods/node) + rollout
  séquentiel plus lent → `--timeout=240s` côté pipeline (cf. FRICTIONS F10).
- **Jar Lambda périmé** : `plan`/`apply` ne relisent que le hash du `.jar` (`filebase64sha256`), jamais
  `LoginHandler.java`. Relancer `mvn -f lambda-login package` **avant** `terraform apply`, sinon
  `0 to change` sans erreur et ancien code déployé.
- **Pas de piège « jar périmé » côté API Docker** : `docker build` recompile depuis `src/`.
- **ECR tags immuables** : un tag ne peut pas être ré-poussé → un tag neuf (SHA court) par build.
- **Version EKS retirée du catalogue** : vérifier les versions supportées (§2.4) avant un apply si le
  code n'a pas tourné depuis longtemps.
- **Docker Desktop mis à jour en session** : conteneurs « fantômes » (CLI reconnecté à un moteur neuf).
  Quitter/relancer Docker Desktop. Ne pas updater pendant qu'un conteneur ou un `apply` tourne.
- **Fronts Angular** : `COPY` doit cibler `dist/<projet>/browser` (pas `dist/<projet>`) ; ne jamais
  copier `node_modules` de l'hôte (`.dockerignore` + `npm ci`) ; générer avec `ng new --skip-git`
  (éviter un `.git` imbriqué).
- **Compte AWS Free Tier — types d'instance restreints au lancement** : `terraform apply` reste bloqué
  en boucle sur `Still creating...` (ASG) si `node_instance_types` contient un type hors Free Tier —
  erreur réelle (visible seulement côté ASG, pas dans la sortie `apply`) :
  `InvalidParameterCombination - The specified instance type is not eligible for Free Tier`.
  Un `run-instances --dry-run` **ne détecte pas** cette restriction (il teste l'autorisation IAM/SCP,
  pas l'éligibilité Free Tier). Lister les types réellement lançables :
  ```bash
  aws ec2 describe-instance-types --region eu-west-3 \
    --filters "Name=free-tier-eligible,Values=true" \
    --query 'InstanceTypes[].{Type:InstanceType,vCPU:VCpuInfo.DefaultVCpus,MemoryMiB:MemoryInfo.SizeInMiB}' \
    --output table
  ```
  En cas de blocage : `Ctrl+C` sur l'`apply` (le control plane reste intact, seul le node group est
  interrompu), corriger `terraform.tfvars`, refaire `plan`/`apply` (cf. FRICTIONS F11).
- **`kubectl` échoue avec une erreur DNS après un réveil de cluster** (`dial tcp: lookup <hash>.eks.amazonaws.com
  ... no such host`) : **kubeconfig périmé**, pas un souci réseau. Chaque `terraform destroy`/`apply` recrée
  le cluster avec un **nouvel endpoint aléatoire** (`aws eks describe-cluster --query cluster.endpoint` donne
  le vrai) ; `~/.kube/config` garde l'ancien tant qu'on ne le rafraîchit pas. Vérifier en comparant l'endpoint
  de l'erreur à celui de `describe-cluster` — s'ils diffèrent, **relancer** `aws eks update-kubeconfig`
  (§2.4) : à faire à **chaque** reconstruction du cluster, pas une seule fois par session/projet.
