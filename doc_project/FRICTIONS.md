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