# A2-Q2 — Dockerisation de l'application Spring Boot

*Image Docker multi-stage (`infoline-api:local`, ~92 Mo), conteneur qui répond HTTP 200 sur `/hello`. Statut au 3 juillet 2026.*

## Réponse apportée

- **Dockerfile multi-stage** (`api/Dockerfile`) :
  - Stage `build` : `maven:3.9-eclipse-temurin-21` (JDK complet + Maven) — compile et produit le jar.
  - Stage `runtime` : `eclipse-temurin:21-jre-alpine` (JRE seul) — ne récupère que le `.jar` du
    stage build, tourne sous un utilisateur non-root `spring`.
- **Image construite et exécutée** : `docker build -t infoline-api:local .` (build `--no-cache`
  réussi), puis `docker run -p 8080:8080` → conteneur `Up`, `curl` HTTP 200 `Hello from InfoLine API`.
- **Cache de build optimisé** : `pom.xml` copié et dépendances téléchargées
  (`mvn dependency:go-offline`) **avant** la copie du code source.

## Preuves

- Code : `api/Dockerfile`, `api/.dockerignore`
- Captures :
  - `doc_project/captures/A2-Q2_dockerfile.md` — le Dockerfile
  - `doc_project/captures/A2-Q2_docker-build.md` — transcript `docker build --no-cache` réussi
    (couches visibles : `dependency:go-offline` 36 s isolé, `package` 3,7 s)
  - `doc_project/captures/A2-Q2_docker-ps-logs-curl.png` — `docker ps` (mapping de port),
    `docker logs` (démarrage Spring), `curl` HTTP 200
- Reproduction : `RUNBOOK.md`, §5.1 « API Spring Boot (Docker) ».

## Pourquoi ces choix

Détail dans `architecture.md`, section « Application API — Spring Boot » (pourquoi multi-stage,
pourquoi `eclipse-temurin`/`-jre-alpine`, pourquoi un utilisateur non-root, ordre des couches).

Phrase réutilisable pour la copie (fiche B2 P3) :
- *« Le Dockerfile constitue une documentation exécutable : il décrit les étapes de construction de
  l'image et permet de reconstruire l'environnement applicatif à l'identique. »*

## Points techniques maîtrisés

**Ce que le stage `build` contient et qui a totalement disparu de l'image finale.** Le stage `build`
embarque **Maven 3.9**, le **JDK 21 complet** (dont le compilateur `javac`), le **code source**
(`src/`), le **`pom.xml`** et le **dépôt Maven local** (les dépendances téléchargées par
`dependency:go-offline`), plus tous les artefacts intermédiaires de compilation. L'image finale ne
contient que le **JRE 21** (machine virtuelle d'exécution, sans compilateur) et l'unique `app.jar`.
Résultat mesuré : ~92 Mo, au lieu d'une image qui traînerait tout l'outillage de build.

**Ordre des `COPY` et cache Docker.** Si l'on faisait `COPY . .` *avant* `mvn package` (au lieu de
copier `pom.xml` seul → `dependency:go-offline` → `COPY src`), alors sur un deuxième build où seul
`HelloController.java` a changé : la couche `COPY . .` verrait son empreinte modifiée (un fichier
source a changé) et **toutes les couches suivantes seraient invalidées**, y compris le téléchargement
des dépendances Maven — **entièrement re-effectué** à chaque changement de code. Avec l'ordre retenu,
seules les couches `COPY src` + `mvn package` sont rejouées ; la couche `dependency:go-offline` reste
en cache, donc **aucun re-téléchargement**. Principe (fiche B2 P3) : « ce qui change le moins souvent
en haut ».

**`EXPOSE 8080` vs `-p 8080:8080`.** C'est **`-p 8080:8080` au `docker run` qui rend réellement le
port joignable depuis la machine hôte** (il crée le mapping hôte → conteneur). `EXPOSE 8080` dans le
Dockerfile **n'ouvre rien par lui-même** : c'est de la documentation/métadonnée qui déclare le port
applicatif attendu (exploitée par l'outillage et par `docker run -P` majuscule, qui publie les ports
`EXPOSE` sur des ports hôtes aléatoires). Rappel d'une friction déjà rencontrée en Phase 0
(`EXPOSE 5000:5000` : EXPOSE ne fait pas de port mapping).

**Pourquoi le piège du « jar pas régénéré » (Lambda) ne peut pas se produire ici.** Côté Lambda,
`terraform apply` ne lit jamais le `.java` : il ne compare que le hash d'un `.jar` déjà présent sur
disque (`filebase64sha256`) — un `mvn package` oublié déploie donc du code périmé sans erreur. Le
Dockerfile multi-stage **rejoue `mvn package` depuis le code source copié à chaque `docker build`** :
le jar est toujours (re)compilé à partir de la source courante, à l'intérieur de l'image. Produire
une image avec un jar périmé est **impossible par construction**. (Le cache de couches ne contredit
pas cela : si `src/` n'a pas changé, la couche `mvn package` est réutilisée — ce qui est correct,
puisque la source est identique ; dès qu'un fichier de `src/` change, la couche `COPY src` est
invalidée et la recompilation a lieu.)

## Conformité

- **Fiche Studi mobilisée** :
  - **B2 P3** (containers) : Dockerfile, multi-stage, ordre des couches pour le cache, Dockerfile
    comme documentation exécutable.
- **Écarts assumés** :
  - **Pas de push vers un registry aujourd'hui** — ECR arrive en Phase 3 (A2-Q3).
  - **`-DskipTests` dans l'image** : les tests tourneront dans le pipeline CI/CD (Phase 3) ; le
    hello-world n'a que le test trivial `contextLoads`.
  - **Variante `-jre-alpine`** (image minimale) : sans risque ici car Spring Web n'a aucune
    dépendance native (garde-fou Alpine de la fiche B2 P3 non applicable) — à reconsidérer en cas
    de lib JNI.

## Statut

| | Image | Conteneur | Doc | Captures |
|---|---|---|---|---|
| `infoline-api:local` multi-stage | ✅ | ✅ (HTTP 200) | ✅ | ✅ |
