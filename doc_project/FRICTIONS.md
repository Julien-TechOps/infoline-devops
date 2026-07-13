# BILAN PHASE 0 — 18 juin 2026

---

## FRICTIONS TECHNIQUES

### F01 — .gitignore manquant avant le premier commit

- **Cause :** réflexe non acquis, `.gitignore` créé après le premier commit.
- **Conséquence :** le dossier `.terraform/` (674 Mo, binaire provider AWS) et `terraform.tfstate` commités et poussés. GitHub a rejeté le push.
- **Résolution :** `git filter-branch` pour réécrire l'historique + force push.
- **Leçon retenue :** créer `.gitignore` AVANT le premier `git add`.

Fichiers à exclure systématiquement dans tout projet Terraform :
```
.terraform/
*.tfstate
*.tfstate.backup
tfplan
```

---

### F02 — Région AWS par défaut incorrecte

- **Cause :** compte créé sans choisir la région, AWS a mis Stockholm (`eu-north-1`) par défaut.
- **Résolution :** changement manuel vers `eu-west-3` (Paris) immédiatement après création.
- **Leçon retenue :** toujours vérifier la région en haut à droite de la console avant toute action. Toutes les ressources du projet doivent être dans `eu-west-3`.

---

## FRICTIONS D'APPRENTISSAGE — Concepts à consolider

### A01 — `terraform plan -out=tfplan` : utilité non connue

- **Ce qui manque :** comprendre pourquoi sauvegarder le plan est critique en prod et dans un pipeline CI/CD.
- **Ce qu'il faut maîtriser :** la différence entre `plan` sans `-out` (recalcul au moment de l'apply, risque de dérive) et `plan -out` (apply exécute exactement ce qui a été validé, sans surprise).
- **Priorité :** moyenne — à mentionner dans la doc technique pour montrer la maturité prod.

```bash
terraform plan -out=tfplan   # sauvegarde le plan
terraform apply tfplan        # applique EXACTEMENT ce plan
```

---

### A02 — Risques du `terraform destroy` sur EKS : non anticipés

- **Ce qui manque :** visualiser ce qui se passe concrètement quand on détruit un cluster avec des charges actives.
- **Ce qu'il faut maîtriser :**
  - Ordre de destruction : pods → volumes → load balancers → nodes → control plane
  - Risque de ressources orphelines créées par Kubernetes hors Terraform (Load Balancers de type `Service`)
  - Perte de données si volumes EBS non sauvegardés
- **Réflexe à acquérir :**

```bash
kubectl delete svc --all        # supprimer les ressources K8s d'abord
terraform plan -destroy          # vérifier ce qui va être détruit
terraform destroy                # seulement ensuite
```

- **Priorité :** haute — EKS arrive en Phase 1 dans 7 jours.

---

### A03 — Cycle de vie Dockerfile multi-stage : pas encore ancré

- **Ce qui manque :** visualiser spontanément pourquoi on utilise deux images de base (node → nginx) et ce qu'on cherche à éviter (embarquer 300+ Mo de tooling de build dans l'image de prod).
- **Ce qu'il faut maîtriser :** écrire un Dockerfile multi-stage Angular sans aide, expliquer le `COPY --from=builder`, justifier le choix de `nginx:alpine`.

```dockerfile
# Stage 1 : build — image jetable
FROM node:18 AS builder
WORKDIR /app
COPY . .
RUN npm install && ng build --configuration production

# Stage 2 : prod — ultra-légère (~25 Mo vs ~1 Go)
FROM nginx:alpine
COPY --from=builder /app/dist/mon-app /usr/share/nginx/html
```

- **Priorité :** moyenne — arrive en Phase 2 (2 juillet).

---

### A04 — Rôle du backoffice mal compris initialement

- **Ce qui manque :** distinction entre redondance (haute disponibilité) et séparation des responsabilités métier.
- **Ce qu'il faut maîtriser :** expliquer l'architecture InfoLine en termes de loi de Conway — deux apps séparées = deux périmètres de risque. Si le backoffice tombe, le site client continue. C'est de l'**isolation**, pas du failover.
- **Priorité :** faible — surtout utile pour la doc technique et l'oral.

---

## CE QUI EST ACQUIS — PHASE 0

| Élément | Statut |
|---|---|
| Compte AWS sécurisé (MFA root, user IAM `terraform-ecf`) | ✅ |
| Alertes billing actives (zero-spend + plafond 15$) | ✅ |
| aws CLI configuré et fonctionnel (`eu-west-3`) | ✅ |
| `aws sts get-caller-identity` répond avec le bon user | ✅ |
| kubectl installé (v1.36.2) | ✅ |
| docker opérationnel (v29.2.1) | ✅ |
| Repo Git `infoline-devops` public sur GitHub | ✅ |
| Premier `terraform init / plan / apply / destroy` sur S3 | ✅ |
| Réflexe `terraform destroy` après chaque test | ✅ |
| `.gitignore` Terraform en place | ✅ |

---

## POINTS DE VIGILANCE POUR LA SUITE


**Git :** le `.gitignore` doit être créé en **premier** dans chaque nouveau dossier Terraform, avant tout `terraform init`. En Phase 1, configurer un backend S3 pour stocker le state à distance — c'est la pratique correcte en équipe.

**Coûts EKS :** environ 0.10$/heure pour le control plane seul. Discipline stricte requise :
- Cluster créé le matin, détruit le soir
- Pas de cluster qui tourne la nuit ou le week-end
- Vérifier AWS Billing après chaque session

**Prochaine session — Phase 1 (25 juin) :** EKS + Lambda en Terraform.
Points à préparer mentalement : structure d'un module Terraform EKS, rôle IAM pour EKS, différence entre node group managé et non managé.

---

# BILAN PHASE 0 — 19 juin 2026

---

## FRICTIONS TECHNIQUES

- `docker pull julienyoussefi/appflaskmin` sans tag → erreur `latest not found` : tag explicite obligatoire au push ET au pull
- `EXPOSE 5000:5000` dans le Dockerfile : syntaxe incorrecte, EXPOSE ne fait pas de port mapping (c'est le rôle de `-p` au `docker run`)
- `VOLUME /chemin/hote:/app/logs` dans le Dockerfile : syntaxe incorrecte, VOLUME déclare un point de montage, pas un mapping (c'est le rôle de `-v` au `docker run`)
- `-d 256mo` confondu avec `--memory 256m` : `-d` = detached mode, pas une limite mémoire

---

## FRICTIONS D'APPRENTISSAGE — Concepts à consolider

### A01 — Vocabulaire "orchestration" mal positionné
Composer n'est pas un orchestrateur. Ce mot est réservé à Kubernetes/Swarm. Compose = gestion multi-conteneurs sur un hôte unique. Risque de confusion face à un jury.

### A02 — Réseau inter-conteneurs sans Compose : non anticipé
Sans Compose, deux conteneurs ne se parlent pas automatiquement. Il faut `docker network create` + `--network` sur chaque `docker run`. Compose crée ce réseau automatiquement et résout les noms de services comme hostnames.

### A03 — Critère de choix `slim` vs image complète mal justifié
Le critère n'est pas l'agilité du projet mais les dépendances natives. Si `requirements.txt` contient des libs qui compilent du C (psycopg2, Pillow, cryptography...), `slim` échoue au build faute d'outils de compilation.

### A04 — Volumes en prod vs dev : distinction pas encore automatique
Monter `./code:/app` en volume est acceptable en dev (hot reload). En prod c'est une erreur : casse l'immuabilité de l'image, la traçabilité et le rollback. En prod, le code est dans l'image via `COPY`, les volumes sont réservés aux données persistantes (DB, uploads, logs).

---

## CE QUI EST ACQUIS — PHASE 0

- Modèle mental image / conteneur / layer : solide
- cgroups (limites ressources) vs namespaces (isolation vue) : compris et su expliquer
- Blast radius sécurité : faille kernel → tous les conteneurs sur l'hôte impactés vs VM (deux barrières)
- Dockerfile complet et ordonné avec justifications : FROM, WORKDIR, COPY, RUN, COPY, EXPOSE, VOLUME, CMD forme exec
- Ordre des layers pour optimiser le cache build : dépendances stables en haut, code applicatif en bas
- Cycle complet build → login → push → run exécuté sur machine réelle
- Format obligatoire `username/image:tag` pour Docker Hub
- `docker run` avec `-d`, `-p`, `-v`, `--memory` : maîtrisé
- Analyse d'un `docker-compose.yml` de projet réel : `image` vs `build`, `depends_on`, `restart: always`, `env_file`, volumes persistants vs code source
- Secrets : `.env` hors Git, `.gitignore` obligatoire

---

## POINTS DE VIGILANCE POUR LA SUITE

- Pratiquer le cycle build/tag/push sur chaque nouveau service du projet ECF pour ancrer les réflexes
- Ne jamais utiliser `latest` comme tag en CI/CD — toujours un tag sémantique ou SHA Git
- Dockerfile multi-stage : pas encore abordé — à couvrir avant la phase CI/CD (réduit drastiquement la taille des images de prod)
- Revoir la distinction Compose / Swarm / Kubernetes avant l'ECF : trois niveaux, trois usages, ne pas confondre

---

## Session Mer 1 juil — Phase 1 A1 : EKS

### Friction 1 — Version Kubernetes non supportée
**Symptôme :** `InvalidParameterException: unsupported Kubernetes version 1.29` au moment du `terraform apply`
**Cause :** AWS retire les anciennes versions de son catalogue (cycle ~14 mois support standard). La version 1.29 était dans le code mais plus disponible à la création.
**Résolution :** `aws eks describe-cluster-versions --query "clusterVersions[?status=='STANDARD_SUPPORT'].clusterVersion"` → versions disponibles : 1.33/1.34/1.35/1.36. Mis `cluster_version = "1.34"` dans terraform.tfvars (pas dans variables.tf pour respecter la séparation code/valeurs).
**Leçon :** Toujours vérifier la liste des versions EKS supportées avant d'écrire la valeur dans le code. À faire en début de session si du temps a passé.

### Friction 2 — Node group "deposed" après apply partiel
**Symptôme :** Second apply affiche `1 added, 0 changed, 1 destroyed` avec un objet "deposed" détruit.
**Cause :** Le premier apply avait échoué après la création du node group mais avant la fin du cycle. Terraform avait gardé l'ancien objet en état "deposed" en attente de nettoyage.
**Résolution :** Aucune action manuelle nécessaire — le second apply a créé le nouveau node group puis détruit l'ancien automatiquement.
**Leçon :** Un `deposed object` dans les logs Terraform n'est pas une erreur. C'est le mécanisme de remplacement sécurisé (create before destroy). Après un destroy, vérifier avec `terraform state list` ET `aws eks list-clusters` — ne pas se fier à un seul signal.

### Friction 3 — Commandes collées en une ligne (copier-coller terminal)
**Symptôme :** `Unknown options: kubectl,get,nodes` après avoir collé deux commandes en une.
**Cause :** Copier-coller d'un bloc multi-commandes sans vérifier la séparation — le terminal a concaténé les deux lignes.
**Résolution :** Corriger avec `&&` entre les commandes, ou les exécuter séparément.
**Leçon :** Toujours relire ce qui est collé dans le terminal avant de valider. En cas de doute, séparer les commandes.

---

## Session Jeu 2 juil — Phase 1 A1 (2/2) : Lambda + API Gateway

### Friction 4 — Dossier imbriqué cassant `source_dir` (détecté avant apply)
**Symptôme :** aucun, justement — bug silencieux détecté par relecture avant tout `terraform apply`. Le composant `terraform/lambda-login/` avait été livré avec un sous-dossier `Infoline_Lambda/` en trop, contenant les `.tf` ET le handler.
**Cause :** `variable "source_dir"` (défaut `"../../lambda-login"`) est un chemin relatif à `path.module`. Avec les `.tf` un niveau plus bas que prévu, la résolution pointait vers un dossier qui ne contenait pas le handler à sa racine → paquet Lambda mal formé (aurait échoué à l'invocation sans erreur au `plan`/`apply`).
**Résolution :** arborescence aplatie (`.tf` directement dans `terraform/lambda-login/`, comme `eks/`/`s3-test/`), code source déplacé vers `lambda-login/` à la racine du repo.
**Leçon :** un chemin relatif Terraform (`path.module`, `source_dir`, etc.) ne s'auto-corrige jamais si l'arborescence bouge — `terraform validate` ne le détecte pas non plus (il ne vérifie pas que les fichiers référencés existent réellement sur disque à ce stade). Seule la lecture attentive ou un `plan`/`apply` réel l'aurait révélé. Réflexe à généraliser : après tout déplacement de dossier, relire les chemins relatifs qui le traversent.

### Friction 5 — `terraform.tfvars.example` manquant, `aws_region` sans défaut
**Symptôme :** aucun run réel, détecté à la lecture — `terraform plan` aurait échoué faute de valeur pour `aws_region` (pas de défaut dans `variables.tf`, et le fichier `.example` censé être copié n'existait pas).
**Résolution :** fichier `terraform.tfvars.example` créé (`aws_region = "eu-west-3"`, alignée sur `terraform/eks/terraform.tfvars`), puis `terraform.tfvars` réel copié dessus (commité comme pour `eks/`, pas de secret dedans).
**Leçon :** un exemple documenté dans un `README.md` (`cp terraform.tfvars.example ...`) n'est pas une preuve qu'il existe — vérifier physiquement les fichiers avant de suivre une procédure écrite.

### Friction 6 — Écart énoncé : "Java function" vs hello-world Python
**Symptôme :** aucun, décision consciente. Le handler initial était en Python, alors que `sujet_ECF.md` demande explicitement une "Java function" pour le login.
**Résolution :** handler réécrit en Java 21 (`com.infoline.login.LoginHandler`), zéro dépendance externe, buildé par Maven. `lambda.tf` adapté : suppression du `data.archive_file` (incompatible avec du code compilé), référence directe au jar buildé via `filebase64sha256`.
**Leçon :** relire l'énoncé mot à mot avant de coder l'infra, pas seulement l'esprit général ("un service serverless"). Un écart mineur en apparence (langage du hello-world) peut coûter des points à l'oral si le jury s'y attarde.

### Friction 7 — Identifiant de compte AWS exposé dans une capture brute
**Symptôme :** le transcript de `terraform apply` contenait `arn:aws:lambda:eu-west-3:<compte réel>:function:infoline-login` en clair.
**Cause :** copier-coller direct du terminal sans repasser par la convention déjà établie sur les captures EKS (`<ACCOUNT_ID>`, `<IAM_USER>`, `<OIDC_HASH>` — cf. commit "flouter identifiants AWS dans les captures A1-Q1").
**Résolution :** identifiant remplacé par `<ACCOUNT_ID>` avant tout commit.
**Leçon :** la convention de floutage n'est pas automatique — à appliquer systématiquement à toute nouvelle capture brute (transcript ou screenshot), pas seulement se souvenir qu'elle existe pour EKS. Un repo public sur GitHub ne pardonne pas un oubli.

### Friction 8 — `response.json` non couvert par `.gitignore`
**Symptôme :** `aws lambda invoke ... response.json` crée un fichier de sortie local à la racine de `terraform/lambda-login/`, absent de `.gitignore`.
**Résolution :** ligne `response.json` ajoutée au `.gitignore`.
**Leçon :** chaque nouvelle commande de test qui écrit un fichier local mérite un réflexe `.gitignore` immédiat, sur le même principe que F01 (Phase 0) pour `.terraform/`/`*.tfstate` — ne pas attendre un rejet de push pour s'en apercevoir.

### Point mineur non bloquant — `invoke_url` avec double slash
`terraform output invoke_url` renvoie `.../amazonaws.com//login` (double slash) : le stage `$default` retourne déjà une URL terminée par `/`, additionnée au `/login` de `var.route_path`. Fonctionnel (l'invocation via cette URL a réussi), corrigeable avec `trimsuffix(...)` dans `outputs.tf` si une URL propre est souhaitée pour la documentation finale — non fait à ce stade, jugé cosmétique.

## CE QUI EST ACQUIS — PHASE 1 LAMBDA
- Composant Terraform isolé (state propre) et sa raison d'être (blast radius)
- Résolution de chemins relatifs Terraform (`path.module`) et son piège en cas de déplacement de dossier
- Différence de packaging Lambda interprété (zip du source) vs compilé (jar pré-construit + `filebase64sha256`)
- Rôle IAM d'exécution au moindre privilège vs permission d'invocation (`aws_lambda_permission`) vs autorisation utilisateur — trois couches distinctes
- Modèle de facturation serverless (usage) vs EKS (à l'heure) et son impact sur la discipline `terraform destroy`
- Validation façon formateur (7 blocs, méthode réutilisable pour les phases suivantes) faite avec Claude.ai — cf. `doc_project/VALIDATION_lambda-iac.md` (généré puis utilisé, non conservé dans le repo)

## POINTS DE VIGILANCE POUR LA SUITE
- Avant Phase 2 (Spring Boot) : le JDK 21 + Maven installés cette session serviront directement — vérifier la version Java attendue par l'image Docker Spring Boot choisie.
- Généraliser le réflexe de floutage (`<ACCOUNT_ID>` etc.) à toute future capture, dès la Phase 2.
- `terraform/lambda-login/` n'a pas besoin d'un destroy systématique en fin de session (coût quasi nul à l'usage) — à la différence d'`eks/`. Documenté dans `architecture.md` et `doc_project/A1-Q1_synthese.md` pour éviter toute confusion à l'oral.
- Relancer `mvn package` après toute modification de `LoginHandler.java`, avant `terraform apply` — Terraform ne compare que le hash du `.jar` déjà sur disque, aucune erreur si le jar n'est pas régénéré (documenté dans `terraform/lambda-login/README.md`).
- Nouveau type de document introduit cette session : `doc_project/{Question}_synthese.md`, un par question ECF (pas par sous-partie technique), pré-rédaction continue de la copie à rendre — pas un doublon d'`architecture.md`/`backlog.md`/`captures/`. À appliquer dès A2-Q1.

---

## Session Ven 3 juil — Phase 2 : Spring Boot (A2-Q1) + Dockerisation (A2-Q2)

Session globalement fluide : application générée via Spring Initializr, lancée en local
(HTTP 200 sur `/hello`), puis image Docker multi-stage construite (`--no-cache` OK) et conteneur
validé (HTTP 200, utilisateur non-root, ~92 Mo). Une seule vraie friction, plus quelques points
d'attention.

### Friction 9 — Renommage de la classe principale → erreur au démarrage
**Symptôme :** renommer la classe principale générée par Spring Initializr (`ApiApplication`) en
`InfolineApiApplication` (nom suggéré pour refléter le package `com.infoline.api`) provoquait une
erreur ; l'application ne démarrait plus.
**Cause :** le nom de la classe principale généré par Initializr est couplé à l'`artifactId` (`api`)
et référencé à plusieurs endroits — le nom du fichier `.java` (en Java, une classe publique doit
résider dans un fichier de même nom), la classe de test `ApiApplicationTests`, et la détection du
*main-class* au repackage par `spring-boot-maven-plugin`. Un renommage partiel (la classe sans le
fichier, ou sans les références) casse la compilation ou le démarrage.
**Résolution :** nom généré conservé tel quel (`ApiApplication`). L'identité « InfoLine » est portée
par le **package** `com.infoline.api` et par la réponse de l'endpoint (`Hello from InfoLine API`),
pas par le nom de la classe.
**Leçon :** ne pas renommer cosmétiquement la classe principale d'un projet Spring Initializr —
point de couplage multiple pour zéro bénéfice sur un hello-world (la contrainte de non
sur-développement s'y applique aussi). Conserver les noms générés.

### Point mineur non bloquant — nom du starter en Spring Boot 4
`spring-boot-starter-web` (réflexe historique) est devenu `spring-boot-starter-webmvc` en
Spring Boot 4.x (stack Servlet/Tomcat). Le `pom.xml` généré par Initializr utilise déjà le bon nom —
à ne pas « corriger » par habitude vers l'ancien.

### Point mineur non bloquant — Maven hôte 3.8.7 vs image 3.9
L'hôte a Maven 3.8.7, l'image de build utilise `maven:3.9-eclipse-temurin-21`. Sans impact : c'est le
`docker build` qui fait foi pour l'image livrée (il embarque sa propre version de Maven) ; le Maven
de l'hôte ne sert qu'au débogage local optionnel.

## CE QUI EST ACQUIS — PHASE 2 SPRING BOOT
- Dockerfile multi-stage Java : séparation JDK+Maven (build) / JRE (runtime), et ce qui traverse les
  stages (le `.jar` seul, via `COPY --from`).
- Ordre des couches pour le cache : `pom.xml` + `dependency:go-offline` avant `COPY src`, pour ne pas
  re-télécharger les dépendances à chaque changement de code.
- `EXPOSE` = documentation/métadonnée ; `-p` au `docker run` = mapping réel qui rend le port joignable
  (confirmation du concept déjà croisé en Phase 0).
- Impossibilité par construction d'un jar périmé avec un build multi-stage (contraste avec le piège
  Lambda `filebase64sha256`).
- Utilisateur non-root dans l'image (moindre privilège, cohérent avec l'IAM Lambda).
- Déclarer explicitement `server.port` même quand la valeur = défaut, pour rendre le choix prouvable.

## POINTS DE VIGILANCE POUR LA SUITE
- Phase 3 (A2-Q3) : l'image `infoline-api` devra être taguée et poussée vers ECR (pas de `latest` en
  CI/CD — tag SHA/sémantique), puis déployée sur EKS. Prévoir les manifests K8s (`k8s/`).
- Convention de nommage des captures : `{Question}_descripteur` en kebab minuscule (ex.
  `A2-Q2_docker-build.md`). Harmonisée sur toutes les captures de la session (renommage des
  `A2-Q2-Docker-*` et des suffixes `_v1`/`_v2`) ; à maintenir dès la phase suivante.

## Session Lun 6 juil — Phase 2 : Angular (A2-Q4)

Deux apps Angular 22 hello world (`apps/frontend/`, `apps/backoffice/`), dockerisées multi-stage
`node:24-alpine` → `nginx:1.30-alpine`, servies en local sur 8081/8082. Réalisé avec l'appui d'une
discussion Claude.ai (cadrage du sujet, recette Dockerfile+nginx, pièges).

### Cadrage — le sujet n'exige PAS la dockerisation du front
Asymétrie repérée dans le texte du sujet : l'API a « créer / dockeriser / déployer sur le kube »
(A2-Q1/Q2/Q3), le front n'a que « créer » (A2-Q4) et « build/test » (A2-Q5) — aucun verbe
« déployez », aucune infra cible. Docker est un **prérequis mécanique** de A2-Q3 (Kubernetes n'exécute
que des conteneurs), pas du front. La dockerisation du front est donc un **choix de cohérence archi
assumé**, pas une exigence : documenté comme tel dans `A2-Q4_synthese.md` (transforme l'écart en preuve
de compréhension). → Levier de priorisation : si le calendrier se tend, c'est le composant le moins
risqué à simplifier/couper.

### Piège dist/browser
Le build Angular moderne (« application builder ») écrit dans `dist/<projet>/browser/`, pas
`dist/<projet>/`. Le `COPY --from=build` doit cibler `…/browser` — sinon le site est cassé. Piège n°1
des Dockerfile Angular+nginx copiés d'un tuto ancien.

### curl ne « parle » pas pour un Angular CSR
Sans SSR, la réponse HTTP de nginx est la coquille `<app-root></app-root>` + `<script>` : le texte
hello world n'existe qu'après exécution du JS côté navigateur. `curl` ne peut pas l'afficher (contraste
net avec l'API Spring Boot). → Preuve retenue : une **capture navigateur** (`A2-Q4_docker-ps-
browser.png`), pas un curl. La capture curl initialement prévue (`A2-Q4_docker-ps-curl.png`) a été
abandonnée (fichier vide supprimé). `curl … | grep '<title>'` ne prouve que « deux pages différentes ».

### Docker Desktop mis à jour en session : conteneurs « fantômes »
Après un update de Docker Desktop, `docker ps -a`/`docker images` vides alors que les conteneurs
répondaient encore sur leurs ports (CLI reconnecté à un moteur neuf, ancien moteur toujours actif).
Résolu par un restart complet de Docker Desktop. → Ne jamais laisser Docker Desktop se mettre à jour
pendant qu'un conteneur (ou un `terraform apply`) tourne.

### Node.js absent de WSL au départ
`node -v` → command not found ; installé avant de générer les apps. Veiller à la **même version** en
local et dans le Dockerfile (Node 24), esprit fiche B2 P1 (rapprochement dev/exécution).

## CE QUI EST ACQUIS — PHASE 2 ANGULAR
- Dockerfile multi-stage front : stage `node:24-alpine` (build jetable) → `nginx:1.30-alpine` (runtime
  statique), `COPY --from` du seul dossier `dist/<projet>/browser`.
- `npm ci` (lockfile, reproductible) plutôt que `npm install` ; `.dockerignore` exclut `node_modules`
  (binaires natifs spécifiques à l'OS — variante Node du piège « jar périmé »).
- nginx : workers déjà non-root par défaut dans l'image officielle — pas besoin de créer un user
  (contraste avec Spring Boot).
- CSR pur : la preuve d'un hello world Angular est une capture navigateur, pas un curl.
- `ng new --skip-git` pour éviter un `.git` imbriqué dans un repo déjà versionné.
- Le sujet n'exige pas le déploiement du front (A2-Q4/Q5 s'arrêtent à build/test) : dockeriser est un
  choix de cohérence, pas une contrainte.

## Session Mar 7 juil — Phase 3 : déploiement manuel de l'API sur EKS (A2-Q3, partie 1/2)

Premier déploiement de l'API Spring Boot sur le cluster EKS de la Phase 1, à la main (`kubectl apply`),
avant l'automatisation CircleCI. Objectif assumé : sentir la friction manuelle pour justifier le
pipeline. Réalisé avec l'appui d'une discussion Claude.ai (diagnostic du cluster éteint, recette
Deployment/Service, lecture des transitions de pods).

### Le réveil du cluster n'est pas gratuit (coût caché du destroy quotidien)
Le cluster ayant été détruit la veille (rituel du soir), aucun `kubectl` ne répondait : il a fallu
`terraform apply` dans `terraform/eks` (~15-20 min — control plane EKS ~10-15 min, puis le node group
démarre ses EC2 et rejoint) **avant** tout déploiement. Cette étape n'apparaît dans aucun planning de
journée parce que ce n'est pas une tâche produit mais un **prérequis de session** qui revient chaque
matin suivant un destroy. Propagé en garde-fou : `RUNBOOK.md` (étape en tête du déploiement EKS) et
`CLAUDE.md`/`AGENTS.md` (symétrie coût du destroy ↔ coût du réveil).

### ECR : tags immuables → un tag par build, jamais réutilisé
Le repo ECR est en tags **immuables** : un même tag ne peut pas être ré-poussé. Convention adoptée en
conséquence : **un tag différent par build**, égal au SHA court du commit (`git rev-parse --short HEAD`,
ici `23547c5`) — ce qui relie l'image à l'état exact du repo. Pas de `latest` en CI/CD.

### ECR affiche 3 entrées pour 1 push (pas 3 versions)
Un seul `docker push` crée 3 entrées dans la console ECR : l'**Image Index** (manifeste OCI), l'**image
réelle**, et une **attestation de provenance/SBOM** générée par BuildKit. Structure standard d'un
manifeste OCI moderne, pas trois versions de l'application.

### Lecture fine des transitions de pods (Running ≠ Ready, readiness ≠ liveness)
- `Running` ≠ `Ready` : un pod peut être `Running` (process démarré) mais `0/1` (readinessProbe pas
  encore passée). L'écart observé (`Running` à 12s, `1/1` à 27s) colle exactement à
  `initialDelaySeconds: 10` + `periodSeconds: 5` sur la readiness — la probe a fait son travail, pas un
  incident.
- `RESTARTS 0` = la livenessProbe n'a jamais échoué. Distinction retenue : une **readiness** qui échoue
  retire le pod des cibles du Service (ne redémarre rien) ; seule une **liveness** qui échoue tue et
  relance le conteneur.
- Le hash dans le nom du pod (`infoline-api-76987f66dd-…`) identifie le **ReplicaSet** créé par le
  Deployment : il changera au prochain déploiement d'une nouvelle image — marqueur visuel d'un rolling
  update en CI/CD.

### Point de cohérence repéré : le repo ECR est hors IaC
Tout le projet est en Terraform, mais le repo ECR a été créé hors IaC (aucun `aws_ecr_repository` dans
les `.tf` du projet). À intégrer en Phase 3 (avec le pipeline) pour ne pas laisser un maillon hors
Terraform. Noté, **non corrigé aujourd'hui** (pas de scope creep en fin de session).

### À anticiper au prochain destroy : l'ELB créé hors Terraform
Le Service `type: LoadBalancer` provisionne un Classic Load Balancer **hors** état Terraform. Faire
`kubectl delete -f k8s/` **avant** le `terraform destroy` du cluster — sinon l'ELB (et ses ENIs dans les
subnets) reste orphelin et peut faire échouer/traîner la suppression du VPC. Consigné dans `RUNBOOK.md`
(section Détruire). Pas encore rencontré, anticipé.

### Ce qui a bien fonctionné
Pull ECR par les nodes sans souci IAM (policy attachée par le module Terraform dès la Phase 1), labels
`Deployment`/`Service` alignés du premier coup (`Endpoints` peuplés immédiatement avec 2 IP:8080),
Classic Load Balancer provisionné en ~47s (plus vite que les 1-3 min attendues), `curl` public OK au
premier essai.

## CE QUI EST ACQUIS — PHASE 3 (déploiement manuel)
- `type: LoadBalancer` sur EKS sans contrôleur = Classic Load Balancer legacy, zéro installation ;
  chemin Internet → ELB(80) → NodePort → pod(`targetPort`).
- `Deployment` (état voulu, replicas, template) → `ReplicaSet` (hash dans le nom du pod) → pods, et
  `Service` couplé aux pods par labels/selector (vérifiable par `kubectl get endpoints`).
- readiness (retire du trafic) vs liveness (redémarre) vs `Running` (process lancé, pas forcément prêt).
- Tag d'image = SHA du commit, jamais `latest` ; ECR immuable impose un tag neuf par build.
- Toute session EKS commence par un `terraform apply` (~15-20 min) et, si un Service LoadBalancer
  tourne, se termine par `kubectl delete` avant le destroy : le destroy du soir a un coût aux deux bouts.

---

## Session Mer 8 juil — Phase 3 : mise en place infra CI (A2-Q3, partie 2/2)

Objectif : automatiser le déploiement de l'API sur EKS via un pipeline. Préparatifs
d'infra CI menés à bien, mais blocage total sur l'outil CircleCI (voir session suivante).

Réalisé et acquis cette session (réutilisable quel que soit l'outil CI) :
- ECR passé en IaC : `terraform/ecr/`, ressource `aws_ecr_repository` existante adoptée
  par `terraform import` (repo infoline-api créé hors IaC en Phase 3 partie 1). Referme le
  dernier maillon hors-Terraform. Leçon : le bloc `resource` doit répliquer la config
  réelle AVANT import, sinon `plan` propose de modifier une ressource existante au lieu de
  l'adopter.
- Utilisateur IAM CI dédié `infoline-ci` créé via Terraform (`terraform/iam-ci/`), policy
  au moindre privilège : push/pull ECR + `eks:DescribeCluster` uniquement. Distinct du
  compte `terraform-ecf` à droits larges — limite le blast radius si les clés CI fuient.
- Access Entry EKS pour `infoline-ci` (mécanisme moderne EKS, pas `aws-auth` legacy) +
  policy `AmazonEKSEditPolicy`. Point conceptuel clé : IAM (authentification AWS) et RBAC
  Kubernetes (autorisation dans le cluster) sont deux couches distinctes ; `eks:Describe
  Cluster` seul donne un `kubectl ... Unauthorized` tant que l'Access Entry n'existe pas.
  Vérifié en local en basculant les credentials sur `infoline-ci` : `kubectl get pods`
  répond sans Unauthorized.
- Rotation de la clé `infoline-ci` après exposition accidentelle dans une capture (réflexe
  de sécurité, clé révoquée + régénérée via `terraform apply -replace`).
- Repo GitHub passé en privé (réduit la surface pendant le développement ; sera rendu
  accessible au jury au dépôt).

---

## Session Jeu 9 juil — Phase 3 : blocage CircleCI irrésolvable → bascule GitHub Actions

### Friction majeure — CircleCI ne liste aucun repo (problème account-level)
Symptôme : page Projects CircleCI vide en permanence ("We couldn't find any
repositories"), donc impossible de configurer le moindre projet ni pipeline.
Diagnostic mené sur ~2 sessions, méthodique : réinstallation propre de la GitHub App
(scope "select" puis "All repositories"), révocation OAuth, suppression + recréation
complète de l'organisation CircleCI, "Refresh permissions", ré-authentification complète
AVEC vidage des cookies circleci.com, flux alternatif "Add Project" via Pipelines. Aucune
piste documentée n'a débloqué l'affichage.
Cause retenue : problème de configuration côté serveur CircleCI propre au compte (leur
propre assistant reconnaît "not enough information to diagnose an account-level backend
issue"). Compte GitHub personnel (pas une organisation) → plusieurs pistes standard du
support inapplicables.

### Suite — support CircleCI (ticket #173426) et arbitrage
Ticket support ouvert (réf. #173426). Réponse reçue : CircleCI ne garantit aucun délai de
traitement sans souscription à un plan de support payant. Délai indéterminé incompatible
avec l'échéance du 23 juillet.
Décision : bascule sur GitHub Actions actée comme solution **DÉFINITIVE** (pas un
contournement temporaire en attendant CircleCI). Justification technique, pas seulement
contournement : le code est déjà hébergé sur GitHub, donc GitHub Actions est l'outil CI/CD
natif de la plateforme — aucune intégration OAuth/App tierce à maintenir. Toute l'infra CI
préparée le 8 juillet (ECR IaC, IAM `infoline-ci`, Access Entry EKS) est réutilisée telle
quelle, indépendante de l'outil.
Le `.circleci/config.yml` reste versionné dans le repo à titre documentaire (démarche
initiale + portabilité du pipeline), sans intention de le connecter.
Conformité : message posté sur le forum Studi (enseignants DevOps) pour valider l'écart
d'outil sur A2-Q3/A2-Q5 (le sujet cite CircleCI), en précisant que la compétence évaluée —
automatiser build/test/déploiement sur le cluster — est démontrée à l'identique avec GitHub
Actions. Poursuite sur GitHub Actions en attendant leur retour.
Leçon : couper une piste morte à temps et changer d'outil équivalent est une décision
d'ingénierie, pas un échec. Diagnostiquer, escalader (ticket + enseignants), puis trancher
rationnellement face à un empêchement structurel (modèle de support payant, pas un bug
transitoire).

### Après-midi — mise en œuvre GitHub Actions
Même journée, après-midi : le pipeline GitHub Actions décidé le matin est mis en œuvre (build/test Maven → push ECR → déploiement EKS via `kubectl`). Le premier rolling update automatisé a révélé une friction de capacité côté nodes.

### Friction 10 — rolling update `infoline-api` bloqué par la limite de pods du node t3.micro
**Symptôme :** le rollout du Deployment `infoline-api` restait bloqué indéfiniment en CI (`kubectl rollout status` en timeout après 120 s) ; un pod restait `Pending`, jamais planifié.
**Cause :** les nodes tournent en `t3.micro` (`t3.medium` indisponible sur ce compte AWS), soit un plafond de 4 pods par node (limite ENI/CNI AWS, fonction du type d'instance). Le `maxSurge` par défaut du rolling update tentait de démarrer un 3ᵉ pod simultané le temps de la bascule ; les deux nodes étant déjà proches de leur plafond, aucun n'avait de place → `0/2 nodes are available: Too many pods`.
**Résolution :** `maxSurge: 0` / `maxUnavailable: 1` dans `k8s/api-deployment.yaml` : un ancien pod est arrêté avant que le nouveau démarre, garantissant qu'il n'y a jamais plus de 2 pods `infoline-api` en simultané. Le rollout converge alors dans la capacité disponible.
**Leçon :** la capacité réelle des nodes (`t3.micro`, pas `t3.medium`) n'est pas qu'une contrainte de coût/compte isolée — elle borne directement les stratégies de déploiement possibles. Un rolling update par défaut suppose de la marge pour faire coexister ancien et nouveau pod ; nodes saturés, il faut expliciter `maxSurge`/`maxUnavailable`. Le « pourquoi t3.micro » est documenté dans `architecture.md` (section EKS), pas redupliqué ici.

**Suite — timeout du rollout porté de 120 s à 240 s (conséquence assumée, pas un contournement) :** une fois `maxSurge: 0` en place, le blocage de capacité (« Too many pods ») disparaît, mais le rollout devient **séquentiel** : les 2 replicas se remplacent un à la fois, chacun devant démarrer la JVM Spring Boot puis passer la readinessProbe (`initialDelaySeconds: 10`) avant la bascule suivante. La convergence prend ~90-110 s, ce qui dépassait le `--timeout=120s` du step « Wait for rollout to complete » (`.github/workflows/deploy.yml`) → `1 of 2 updated replicas are available… timed out waiting for the condition`. Diagnostic tranché avant de corriger : `kubectl rollout status --timeout=180s` en local renvoie `successfully rolled out` (2 pods `1/1 Running`) — ce n'est pas un pod qui échoue, seulement un timeout trop court. Fix : `--timeout` porté à **240 s**. Marge assumée qui couvre le pire cas du rollout séquentiel imposé par la capacité réduite des nodes t3.micro, pas un pansement sur un déploiement cassé.

---

## Session Ven 10 juil — Phase 3 : clôture (preuve du rolling update, durcissement, RUNBOOK)

Session de clôture : capture de la preuve reine du déploiement continu, durcissement du manifeste, et consolidation du RUNBOOK de bout en bout. Aucune friction bloquante.

### Durcissement — ACCOUNT_ID sorti du manifeste (placeholder + substitution CI)
`k8s/api-deployment.yaml` codait en dur la référence ECR complète (ACCOUNT_ID en clair), gênant avant un repo public. Remplacé par `IMAGE_PLACEHOLDER`, substitué par la vraie référence (depuis les secrets GitHub) juste avant `kubectl apply` — ce qui fusionne au passage les steps `apply` + `set image`. Le bloc `import` du module ECR (`terraform/ecr/`), son adoption terminée, a été retiré (un rebuild from-scratch passe désormais par `create`). Validé vert au commit `e96fac6`. « Pourquoi » consigné dans `architecture.md`.

### Preuve reine capturée — rolling update réel
Rolling update automatisé prouvé : hash ReplicaSet `5b6f7c7895` → `955fc7c6` (nouveau ReplicaSet, ancien retiré) + `successfully rolled out` + `curl` ELB → `Hello from InfoLine API`. Rollout **séquentiel** confirmé de deux façons (`maxSurge: 0`) : logs `1 out of 2 new replicas have been updated…` et écart d'âge des deux pods (~58 s), pas de bascule simultanée.

### Friction mineure — `jq` absent (test Lambda)
`curl … | jq .` (§2.5 RUNBOOK) échouait faute de `jq` installé, **avalant la sortie du `curl`** (route API Gateway non vérifiée alors que l'invoke direct passait). Résolu : `jq` marqué **optionnel** dans le RUNBOOK, `curl` brut en commande principale. Leçon : un test de route ne doit pas dépendre d'un formateur — robustesse pour le run final (machine du jury sans `jq`).

### Friction mineure — transcript `-w` perdu (séquences terminal)
La capture du flux `kubectl get pods -w` (état PENDANT) a été polluée par des séquences d'échappement du terminal intégré VS Code au copier-coller. Contourné sans refaire de déploiement : la preuve avant/après (hash changé) + l'écart d'âge des pods suffisent à la définition de la preuve reine. Réflexe pour la suite : rediriger avec `| tee -a fichier.md` plutôt que copier-coller un flux `-w`.

### RUNBOOK réécrit de bout en bout
`RUNBOOK.md` refondu : provisioning IaC ordonné (ECR → IAM-CI → secrets GitHub → EKS+Access Entry → Lambda) → déploiement continu CI/CD (avec marqueurs de captures Phase 3) → cycles locaux → vérif → destroy → pièges. Sert le run final reproductible **et** la validation Phase 3.

## CE QUI EST ACQUIS — PHASE 3 (CI/CD)
- Pipeline GitHub Actions build/test/déploiement API → EKS vert de bout en bout ; build/test des 2 fronts Angular (matrice, Vitest). Bascule assumée depuis CircleCI (outil équivalent, écart soumis aux enseignants).
- Deux couches d'autorisation EKS distinctes : IAM (authentification) vs RBAC/Access Entry (autorisation dans le cluster), versionnées en Terraform.
- Rolling update lu et prouvé : ReplicaSet (hash), `maxSurge`/`maxUnavailable`, rollout séquentiel imposé par la capacité des nodes (t3.micro), garde-fou `rollout status` à timeout dimensionné.
- Manifeste k8s agnostique du compte (placeholder substitué en CI) — pas d'ACCOUNT_ID en dur.
- ECR et IAM-CI en IaC, permanents (non détruits chaque soir), distincts d'EKS (détruit quotidiennement).

## POINTS DE VIGILANCE POUR LA SUITE (Phase 4 — ELK)
- ELK est la techno la moins maîtrisée : lui laisser de la marge (cf. CLAUDE.md).
- La supervision (A3) répond à l'exigence du sujet « monitorer + notifier » — sur les **logs** K8s, pas des métriques.
- Réveil du cluster ~15-20 min avant tout `kubectl` : à budgéter en début de session ELK.

---

## Session Lun 13 juil — Phase 4 : ELK (A3-Q1 — Elasticsearch connecté à K8s)

A3-Q1 **démontré** : Elasticsearch déployé sur EKS via l'opérateur ECK, Filebeat (DaemonSet) ingère les logs de tous les pods, connexion prouvée par un log k8s-enrichi retrouvé dans ES. Une friction bloquante majeure (le type d'instance, résolue autrement que prévu) et deux pièges d'outil mineurs mais instructifs.

### Friction 11 — `terraform apply` bloqué en boucle : compte Free Tier, types d'instance restreints au lancement
**Symptôme :** après passage de `node_instance_types` sur `t3a.medium`/`t3.medium` (pour héberger Elasticsearch, `t3.micro` à 1 GiB étant trop petit), `terraform apply` reste bloqué **28+ min** sur `module.eks.…aws_eks_node_group.this[0]: Still creating…`, sans jamais d'erreur dans sa sortie. Les nœuds ne rejoignent jamais le cluster.
**Cause :** le compte AWS est en **Free Tier**, qui **refuse au lancement** tout type d'instance non éligible. L'Auto Scaling Group retente en boucle un lancement EC2 systématiquement rejeté — erreur visible **uniquement** via `aws autoscaling describe-scaling-activities --region eu-west-3` : `Could not launch On-Demand Instances. InvalidParameterCombination - The specified instance type is not eligible for Free Tier`. Elle n'apparaît **jamais** dans la sortie `terraform apply` (qui ne fait que poller la création du node group).
**Résolution :** `Ctrl+C` sur l'apply (le control plane, déjà créé, reste intact — seul le node group est interrompu). Lister les types **réellement** lançables : `aws ec2 describe-instance-types --region eu-west-3 --filters "Name=free-tier-eligible,Values=true" --query 'InstanceTypes[].{Type:InstanceType,vCPU:VCpuInfo.DefaultVCpus,MemoryMiB:MemoryInfo.SizeInMiB}' --output table` → révèle une liste plus riche qu'attendu, dont **`m7i-flex.large` (8 GiB)** et `c7i-flex.large` (4 GiB), éligibles. `terraform.tfvars` → `node_instance_types = ["m7i-flex.large", "c7i-flex.large"]` (hedge de capacité), re-`apply` → 2 nœuds `Ready` en `m7i-flex.large`.
**Leçon :** sur ce compte, un **`run-instances --dry-run` ment** — il valide l'autorisation IAM/SCP, **pas** l'éligibilité Free Tier, donc renvoie « Request would have succeeded » pour des types en réalité refusés au lancement (c'est ce qui avait fait retenir `t3a.medium` à tort). Ne jamais valider un type par dry-run seul ici : passer par `describe-instance-types --filters free-tier-eligible`. Corrige deux hypothèses antérieures fausses (« liste blanche SCP », puis « pénurie transitoire »). Commande de diagnostic + piège consignés dans `RUNBOOK.md` §8.

### Piège d'outil — le flag `-w` (watch) bloque le terminal ; les commandes suivantes ne s'exécutent pas
`kubectl get elasticsearch -w` (utile pour suivre `PHASE` en direct) ne rend **jamais** la main. Les commandes tapées ensuite dans le même terminal (`PW=…`, `curl …`) s'affichent mais **ne sont jamais exécutées** par le shell. Symptôme trompeur : « mon `curl` ne fait rien, même avec `-v` ». **Leçon :** `Ctrl+C` le watch avant de continuer à travailler dans ce terminal. Corollaire de diagnostic : si `curl -v` n'affiche **rien** (pas même `* Trying …`), c'est que curl **ne tourne pas** — chercher côté terminal, pas côté réseau.

### Fausse piste — le « handshake TLS qui échoue » venait du navigateur, pas de curl
Les logs d'Elasticsearch montraient bien un `SSLHandshakeException: certificate_unknown` au moment des tests — ce qui a un instant fait soupçonner un problème de connexion `curl`. En réalité c'était le **navigateur** (ouvert en parallèle sur `https://localhost:9200`, qui rejette le certificat auto-signé avant le « Proceed anyway »). Le `curl -k`, lui, ne produisait aucun log car il ne s'exécutait pas (cf. piège `-w` ci-dessus). **Leçon :** corréler l'horodatage et l'origine (`remoteAddress`) d'une erreur serveur avant de l'attribuer à la mauvaise commande. La capture navigateur du certificat s'est révélée une **bonne preuve** ECF au passage (`A3-Q1_es-tls-cert-browser.png`).

### Ce qui a bien marché (à ne pas oublier de reproduire)
ECK 3.4.1 + Elasticsearch 9.4.3 + Filebeat 9.4.3 **verts du premier coup**. `node.store.allow_mmap: false` a évité la friction classique `vm.max_map_count`. La recette `emptyDir` (volume `elasticsearch-data` + pas de `volumeClaimTemplates`) a fonctionné sans PVC pendant. Le pairing de version ECK↔Stack, non confirmé par une doc fraîche, a été **validé par le run** (webhook ECK non déclencheur, `PHASE: Ready`).

## CE QUI EST ACQUIS — PHASE 4 (A3-Q1)
- Elasticsearch déployé sur EKS via l'opérateur ECK ; Filebeat en DaemonSet (1/nœud) ingère les logs de tous les pods ; connexion prouvée (log enrichi `kubernetes.*` retrouvé dans ES, `orchestrator.cluster.name: infoline-eks`).
- Modèle mental des logs K8s consolidé : conteneur `stdout` → fichier `/var/log/containers/*.log` **sur le nœud** → Filebeat (`hostPath`, DaemonSet) enrichit et pousse → Elasticsearch indexe → cherchable.
- Sécurité ES activée par défaut (TLS auto-signé + auth) gérée par ECK ; accès par `kubectl port-forward` + `curl -k -u elastic:$PW`.
- Contrainte Free Tier des types d'instance cartographiée (m7i-flex.large / c7i-flex.large éligibles) — voir aussi mémoire projet + RUNBOOK §8.

### Friction 12 — Filebeat 9.x : autodiscover+hints génère une configuration invalide
**Symptôme :** la configuration autodiscover avec hints ne collectait pas de façon fiable tous les logs et déclenchait l'erreur `more than one namespace configured` lorsque Filebeat activait le module Elasticsearch.
**Cause :** en 9.x, les hints peuvent produire plusieurs sections de configuration incompatibles pour un même input. Cette abstraction ajoutait ici de la complexité alors que le besoin est simplement de lire tous les fichiers de conteneurs du nœud.
**Résolution :** remplacement par un input unique `filestream` sur `/var/log/containers/*.log`, parser `container`, suivi de `add_kubernetes_metadata`. Les symlinks sont explicitement suivis. Le DaemonSet est resté vert (2/2) et les logs de `kube-system`, ECK, Elasticsearch, Filebeat et Kibana sont devenus interrogeables dans Discover.
**Leçon :** partir du flux Kubernetes réel (fichiers du nœud → enrichissement → ES) donne ici une configuration plus explicite et robuste que l'autodiscover par hints.

## CE QUI EST ACQUIS — PHASE 4 (A3-Q2)
- Kibana 9.4.3 géré par ECK, `HEALTH green`, relié à `infoline-es` par `elasticsearchRef` ; accès local par port-forward, donc aucun ELB supplémentaire.
- Data view `filebeat-*` sur `@timestamp` et Discover validés avec des logs Kubernetes réels.
- Recherches KQL prouvées : erreurs, `certificate_unknown`, namespace, pod, `stderr`, critères combinés ; analyse par fenêtre temporelle également capturée.
- Frontières assumées : login Lambda dans CloudWatch, hors collecte Filebeat ; pas de champ de latence dans les hello-world.

## POINTS DE VIGILANCE POUR LA SUITE
- Index Filebeat en `yellow` (réplica non plaçable en mono-nœud) = normal, pas un bug.
- L'alerting actif reste hors périmètre ; la preuve ECF porte sur la visibilité et la recherche des dysfonctionnements dans Kibana.
