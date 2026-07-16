# Bilan de projet — ECF DevOps InfoLine

> ⚠️ **[BROUILLON Phase 5 — à réécrire / t'approprier avant dépôt.]** Structure inspirée du
> bilan de projet Hub2 (forme), contenu **ancré dans ce dépôt**. Rien n'est inventé : chaque
> affirmation renvoie au code, aux synthèses ou au journal. À relire ligne à ligne — c'est une
> pièce de la copie que tu devras défendre à l'oral.

**Auteur :** Julien Youssefi
**Contexte :** ECF Administrateur Système DevOps (Studi, promo Conway) — sujet InfoLine
**Période :** 18 juin → 23 juillet 2026 — 16 jours ouvrés (~112 h), phases 0 → 5
**Statut du document :** interne (rétrospective de fin de projet) — pièce d'accompagnement de la copie
**Date :** juillet 2026

> Ce bilan raconte le projet de bout en bout : le sujet, la réponse d'architecture, ce qui est
> livré et prouvé, les difficultés structurantes et leur résolution, les écarts assumés, et la
> conduite de projet. Il **complète** la doc du dépôt — [architecture.md](../architecture.md)
> (le « pourquoi » + schéma), [RUNBOOK.md](../RUNBOOK.md) (procédures), les
> `{Question}_synthese.md` (copie par question) et [FRICTIONS.md](FRICTIONS.md) (journal) —
> **sans la dupliquer**.

---

## En bref

**Le sujet.** InfoLine, agence en croissance à budget limité, veut une architecture
microservices cloud *scalable* : une API métier (Java Spring Boot) déployée sur Kubernetes, un
login serverless, deux fronts Angular (public + backoffice), une base PostgreSQL, le tout
**piloté en Infrastructure as Code** et **supervisé**, avec des applications **séparées** pour
qu'un incident sur l'une n'affecte pas les autres.

**La réponse.** Une infrastructure AWS **entièrement décrite en Terraform** (VPC + cluster EKS,
Lambda + API Gateway, ECR, IAM), une **CI/CD GitHub Actions** qui build/teste et déploie l'API
sur EKS, et une **supervision par les logs (ELK)** qui collecte et rend cherchables les logs de
tout le cluster. Les applications sont des **hello world volontairement triviaux** : le livrable
noté est l'**empaquetage et le déploiement**, pas le code applicatif.

**Ce que ça démontre.** Toutes les questions de l'ECF (A1-Q1 en deux volets EKS + Lambda,
A2-Q1 à Q5, A3-Q1 et Q2) sont couvertes, prouvées par des captures et rejouables via le RUNBOOK. Le fil conducteur : **un conteneur
(A2) déployé sur l'infra IaC (A1) par un pipeline CI/CD, supervisé par ELK (A3)** — une chaîne
DevOps complète, cohérente de bout en bout.

---

## 1. Le sujet et la réponse

### 1.1 Le sujet InfoLine

La direction impose un **budget limité au départ, extensible ensuite** → cloud et scalabilité.
L'équipe technique **sépare les applications** « pour diminuer le risque d'être hors service ».
Le périmètre annoncé : API Java sur Kubernetes, login serverless (Lambda), deux fronts Angular,
base PostgreSQL, automatisation IaC, CI/CD, et supervision avec notification en cas de
dysfonctionnement. Correspondance question ↔ phase dans [sujet_ECF.md](sujet_ECF.md).

### 1.2 La réponse : IaC + CI/CD + supervision

- **Infra en Terraform**, un composant = un dossier + un state séparé (`terraform/eks`,
  `lambda-login`, `ecr`, `iam-ci`) : cycles de vie indépendants, blast radius limité.
- **CI/CD GitHub Actions** : `deploy.yml` (API : `mvn verify` → build/push image ECR au SHA
  court → `kubectl apply` → `rollout status`) et `angular.yml` (fronts : build/test).
- **Supervision ELK** via l'opérateur ECK : Elasticsearch + Filebeat (DaemonSet) + Kibana,
  logs de tout le cluster indexés et cherchables (KQL).

### 1.3 Contraintes structurantes

Trois contraintes ont façonné les choix (détail et « pourquoi » dans
[architecture.md](../architecture.md)) :

- **Budget** : discipline de `terraform destroy` quotidien (EKS facturé à l'heure), NAT Gateway
  unique, Lambda serverless (facturé à l'usage), Kibana en `port-forward` (pas de second ELB).
- **Compte AWS Free Tier** : refus au lancement des types d'instance non éligibles — contrainte
  qui a directement piloté le dimensionnement des nœuds (cf. §3).
- **Timebox** (~112 h, aucune marge) : hello world assumés, aucun sur-développement applicatif,
  aucun scope creep.

---

## 2. Synthèse technique (ce qui est livré et prouvé)

Chaque question a sa fiche `{Question}_synthese.md` (réponse + preuves + « pourquoi » + écarts).
Vue d'ensemble :

| Question ECF | Livré | Preuve principale |
|---|---|---|
| **A1-Q1** | VPC + EKS 1.34 (node group `m7i-flex.large`) **et** Lambda `java21` + API Gateway HTTP, en Terraform | `terraform apply`/`destroy` propres ; `curl`/`aws lambda invoke` ; consoles AWS |
| **A2-Q1 / Q2** | API Spring Boot `GET /hello:8080`, image Docker **multi-stage** non-root (~92 Mo) | conteneur HTTP 200 ; Dockerfile |
| **A2-Q3** | Déploiement API sur EKS **automatisé** (ECR → `kubectl apply` → rollout) | pipeline vert + **rolling update réel** (hash ReplicaSet change) + `curl` ELB |
| **A2-Q4** | Deux fronts Angular hello world dockerisés (`node`→`nginx`) | rendu navigateur des deux apps |
| **A2-Q5** | Pipeline Angular build/test (matrice `frontend`/`backoffice`) | run GitHub Actions vert |
| **A3-Q1** | Elasticsearch (ECK) + Filebeat sur EKS, logs K8s ingérés | log réel enrichi `kubernetes.*` retrouvé dans ES |
| **A3-Q2** | Kibana connecté à ES + requêtes KQL commentées | 7 recherches Discover + dashboard + scénario d'incident détecté/résolu |

**Le fil conducteur.** Ces briques ne sont pas juxtaposées : l'image construite en A2 est stockée
sur ECR et **déployée sur le cluster IaC d'A1** par le pipeline d'A2-Q3, puis **supervisée par
l'ELK d'A3** — la consolidation le prouve sur un cas réel (déploiement cassé volontairement,
détecté dans Kibana, résolu par rollback). C'est la cohérence inter-blocs attendue d'un dossier
DevOps.

> **Honnêteté des chiffres.** Les applications étant des hello world, ce bilan **ne fabrique
> aucune métrique** de performance ou de temps. Il présente ce qui est **vérifiable** (composants
> déployés, preuves capturées, procédures rejouables). La valeur démontrée est la **maîtrise de
> la chaîne d'empaquetage → déploiement → supervision**, pas un gain applicatif.

---

## 3. Difficultés majeures et résolution

Synthèse des frictions structurantes — récit complet et leçons dans [FRICTIONS.md](FRICTIONS.md),
non redupliqué ici.

| Difficulté | Cause | Résolution |
|---|---|---|
| **CircleCI inutilisable** (repos jamais listés) | blocage *account-level* côté CircleCI, support payant (ticket #173426) | bascule **GitHub Actions** (pipeline identique, natif GitHub) — écart **validé par le formateur** |
| **`terraform apply` bloqué 28 min sans erreur** | compte **Free Tier** refusant au lancement les types d'instance non éligibles (invisible dans la sortie `apply`, `dry-run` trompeur) | node group sur `m7i-flex.large` / `c7i-flex.large` (types éligibles, listés par `describe-instance-types`) — cf. FRICTIONS **F11** |
| **Rolling update en échec** (pod surnuméraire `Pending`) | `t3.micro` plafonne à 4 pods/nœud (limite ENI/CNI) | `maxSurge: 0` / `maxUnavailable: 1` + `--timeout=240s` (rollout séquentiel) — cf. **F10** |
| **Filebeat ne collectait pas tous les namespaces** | config `autodiscover+hints` fragile en Stack 9.x | bascule input `filestream` + `add_kubernetes_metadata` — cf. **F12** |
| **Clé AWS exposée** | credential en clair dans un fichier de travail | rotation de la clé `infoline-ci` + `.gitignore` durci — cf. **F7** |
| **`kubectl` en erreur DNS au réveil** | endpoint EKS recréé aléatoirement à chaque `apply`, kubeconfig périmé | `aws eks update-kubeconfig` à **chaque** reconstruction (RUNBOOK §8) |

Fil rouge de ces frictions : la contrainte de **compte** (Free Tier, budget) borne des décisions
d'**architecture** (type de nœud → stratégie de déploiement), et un empêchement **externe**
(CircleCI) peut imposer une bascule d'outil — assumée et documentée plutôt que subie.

---

## 4. Écarts assumés et ce qui serait fait différemment

Écarts **volontaires**, cohérents avec le périmètre (budget, timebox, hello world). Chacun est
nommé pour ne pas passer pour un oubli ; le « pourquoi » détaillé est dans
[architecture.md](../architecture.md).

- **PostgreSQL non déployé** : présent au sujet mais aucune brique applicative ne le consomme
  (API sans datasource) → non provisionné. En cible : RDS en Terraform.
- **Fronts Angular non déployés** : A2-Q5 s'arrête à « build/test » (pas de verbe « déployez »,
  contrairement à A2-Q3). Buildés/testés en CI, non mis sur EKS. En cible : S3 + CloudFront (SPA).
- **Authentification CI par clés statiques** : OIDC (rôle de confiance sans clé longue durée) non
  retenu par timeboxing — **durcissement de production** identifié.
- **State Terraform local** (backend S3 commenté) : suffisant pour un opérateur unique ; à activer
  (state distant + lock) dès le travail en équipe.
- **Elasticsearch `emptyDir`, single-node** : pas de PVC (ni driver EBS CSI) ni de HA — les logs ne
  survivent pas à un `destroy`, acceptable pour un cluster éphémère. En cible : PVC gp3 + réplicas.
- **Supervision = détection visuelle**, pas d'alerting push (Watcher / Kibana Alerting) : la
  « notification » du sujet est interprétée comme un dysfonctionnement **visible dans Kibana**.
- **RTO non encore mesuré** : les scripts `scripts/rebuild.sh` / `teardown.sh` centralisent la
  reconstruction mais restent à **valider et chronométrer** au run final (22 juil).

---

## 5. Conduite de projet

- **Découpage en phases** (roadmap v4) : socle (0) → EKS/Lambda (1) → apps (2) → CI/CD (3) →
  ELK (4) → doc & livrables (5). Source de vérité d'avancement : [backlog.md](backlog.md).
- **Documentation au fil de l'eau** (priorité imposée dès le départ) : à chaque session, commit +
  entrée FRICTIONS + captures nommées par question + mise à jour des synthèses. La Phase 5 (doc,
  ~25 h) n'aurait pas suffi sans cette continuité — pari tenu.
- **Discipline de coût** : `terraform destroy` en fin de session, `RUNBOOK.md` retesté comme
  répétition du run final noté.
- **Preuves brutes séparées du narratif** : `doc_project/captures/` (transcripts + PNG, ~54
  fichiers) ne contient aucune justification — le « pourquoi » vit dans `architecture.md`, le
  « comment » dans le RUNBOOK, le récit dans FRICTIONS. Cette séparation des foyers documentaires
  évite la duplication et les incohérences.
- **Outillage IA transparent** : le dépôt documente son pairing (`CLAUDE.md` / `AGENTS.md`) ;
  l'IA a servi d'outil de rédaction et de vérification, les **décisions techniques et leur
  justification restent les miennes** (à défendre à l'oral). *(Section à ajuster selon ce que tu
  souhaites mettre en avant devant le jury.)*

---

## Glossaire

| Terme | En clair |
|---|---|
| **IaC** (*Infrastructure as Code*) | Décrire l'infra en fichiers versionnés (Terraform) plutôt qu'à la main. |
| **EKS** | Kubernetes managé par AWS (control plane délégué). |
| **Serverless / Lambda** | Fonction facturée à l'usage, sans serveur permanent à maintenir. |
| **CI/CD** | Chaîne automatisée build → test → déploiement à chaque push. |
| **Rolling update** | Remplacement progressif des pods d'un déploiement, sans coupure. |
| **ELK / ECK** | Stack de logs (Elasticsearch + Kibana) ; ECK = son opérateur Kubernetes. |
| **DaemonSet** | Un pod par nœud (ici Filebeat, pour lire les logs de chaque nœud). |
| **RTO** (*Recovery Time Objective*) | Temps de remise en route de l'infra après destruction/incident. |
| **Free Tier** | Palier gratuit AWS ; ici, il restreint les types d'instance lançables. |

---

## Sources & traçabilité

- **Code** : `terraform/` (IaC), `k8s/` + `k8s/elk/` (workloads), `.github/workflows/` (CI/CD),
  `api/`, `lambda-login/`, `apps/` (applicatif).
- **Docs produit** : [architecture.md](../architecture.md) (schéma + pourquoi),
  [RUNBOOK.md](../RUNBOOK.md), [README.md](../README.md).
- **Copie par question** : `doc_project/{A1-Q1..A3-Q2}_synthese.md`.
- **Journal & suivi** : [FRICTIONS.md](FRICTIONS.md), [backlog.md](backlog.md),
  [sujet_ECF.md](sujet_ECF.md), `doc_project/captures/`.
- **Reconstruction (RTO)** : `scripts/` (brouillon, à valider au run du 22 juil).
