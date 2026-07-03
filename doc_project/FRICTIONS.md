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