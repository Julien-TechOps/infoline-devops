# api — API Java Spring Boot (hello world)

Application Java 21 / Spring Boot, volontairement triviale (le livrable noté est
l'empaquetage et le déploiement, pas le code applicatif). Un seul endpoint :

- `GET /hello` → `Hello from InfoLine API`, exposé sur le **port 8080**
  (`src/main/resources/application.properties`).

Répond aux questions **A2-Q1** (exposée sur un port) et **A2-Q2** (dockerisation).

## Contenu

- `pom.xml` — build Maven, dépendance unique `spring-boot-starter-webmvc` (+ test).
- `src/main/java/com/infoline/api/HelloController.java` — le contrôleur `/hello`.
- `Dockerfile` — image **multi-stage** (JDK21+Maven → JRE21 alpine), utilisateur non-root
  `spring`, `EXPOSE 8080`.

## Build & run local

```bash
# Build + test
./mvnw verify

# Image Docker (recompile le jar depuis la source)
docker build -t infoline-api:local .
docker run --rm -p 8080:8080 infoline-api:local
curl http://localhost:8080/hello
```

## Déploiement

Poussée sur ECR (tag = SHA court) puis déployée sur EKS par la CI/CD
(`.github/workflows/deploy.yml`), via les manifestes `k8s/api-deployment.yaml` +
`k8s/api-service.yaml`. Procédure manuelle de secours : `RUNBOOK.md` §4.

## Documentation

Rationale : `architecture.md` § « Application API — Spring Boot ». Synthèses pour la copie :
`doc_project/A2-Q1_synthese.md`, `doc_project/A2-Q2_synthese.md`.
