# A2-Q1 — Application Java Spring Boot exposée sur un port

*Application Spring Boot "hello world" (`GET /hello`), validée en local avant conteneurisation. Statut au 3 juillet 2026.*

## Réponse apportée

- **Application** : Java 21 + Spring Boot 4.1.0, dépendance unique `spring-boot-starter-webmvc`,
  un seul endpoint REST `GET /hello` renvoyant `Hello from InfoLine API`.
- **Exposition sur un port** : `server.port=8080` **déclaré explicitement** dans
  `application.properties`.
- **Validation** : lancée hors Docker d'abord (débogage plus rapide), réponse HTTP 200 sur
  `/hello` vérifiée au `curl` avant l'étape de conteneurisation (cf. `A2-Q2_synthese.md`).

Le sujet formule Q1 « … à partir d'une image docker java spring boot et exposez-le sur un port » :
la lecture retenue traite Q1 (l'application tourne et répond) et Q2 (elle est empaquetée dans une
image) comme deux étapes successives — l'application a été développée et validée en local avant
d'être conteneurisée à partir d'une image Java officielle (cf. `A2-Q2_synthese.md`).

## Preuves

- Code : `api/` (projet Maven, racine du repo)
  - `api/src/main/java/com/infoline/api/ApiApplication.java` — classe principale
  - `api/src/main/java/com/infoline/api/HelloController.java` — endpoint `/hello`
  - `api/src/main/resources/application.properties` — `server.port=8080`
- Captures : `doc_project/captures/A2-Q1_curl-local-v1.png`, `A2-Q1_curl-local-v2.png`
  (application lancée en local + réponse HTTP 200 sur `/hello`)
- Reproduction : `RUNBOOK.md`, section « API Spring Boot (Docker) », sous-section
  « Lancer sans Docker ».

## Le choix du port (« un port de votre choix »)

Le sujet demande explicitement un port « de votre choix ». Bien que `8080` soit déjà le défaut
implicite de Spring Boot, il a été **déclaré noir sur blanc** dans `application.properties`
(`server.port=8080`) : le choix devient visible dans le code et prouvable en capture, au lieu de
reposer sur un comportement par défaut non écrit. C'est une ligne concrète à montrer au jury.

## Pourquoi ces choix

Détail dans `architecture.md`, section « Application API — Spring Boot » (pourquoi Java/Spring Boot,
pourquoi Java 21).

Phrase réutilisable pour la copie :
- *« L'application a été développée et validée en local (réponse HTTP 200 sur `/hello`, port 8080)
  avant d'être conteneurisée à partir d'une image Java officielle, afin d'isoler le débogage
  applicatif de l'étape d'empaquetage. »*

## Conformité

- **Fiches Studi mobilisées** :
  - **B2 P3** (containers) : vocabulaire image/conteneur, préparation à la conteneurisation.
  - **B2 P1** (logique de validation) : valider l'applicatif hors conteneur d'abord, pour ne pas
    confondre un bug applicatif avec un bug d'image lors de l'étape Q2.
- **Écarts assumés** :
  - **Maven plutôt que Gradle** — cohérence avec `lambda-login/` déjà en Maven, un seul outil de
    build à suivre pendant l'ECF (le sujet accepte les deux).
  - **Nom de classe conservé** (`ApiApplication`, non renommé en `InfolineApiApplication`) —
    l'identité InfoLine est portée par le package `com.infoline.api` et la réponse de l'endpoint ;
    cf. `doc_project/FRICTIONS.md`, session Ven 3 juil (Friction 9).
  - **Aucune logique métier** dans l'endpoint (contrainte de non sur-développement applicatif).

## Note — pourquoi deux fichiers de synthèse pour A2 (Q1 et Q2), un seul pour A1-Q1

A1-Q1 est **un seul numéro de question** couvrant deux sous-parties techniques (EKS + Lambda) → un
seul `A1-Q1_synthese.md`. A2-Q1 et A2-Q2 sont **deux numéros de question distincts** dans la table
de correspondance → la règle « un fichier par question ECF » impose deux fichiers. Répartition :
**A2-Q1** = l'application tourne et répond sur un port (validée en local) ; **A2-Q2** =
l'application est empaquetée dans une image Docker multi-stage et le conteneur répond.

## Statut

| | Applicatif | Doc | Captures |
|---|---|---|---|
| Spring Boot `/hello` sur `:8080` | ✅ | ✅ | ✅ |
