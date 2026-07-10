# A2-Q4 — Applications Angular (hello world) + dockerisation

*Deux fronts Angular 22 hello world (`frontend`, `backoffice`), dockerisés multi-stage
(`node:24-alpine` → `nginx:1.30-alpine`), servis en local sur 8081 / 8082. Statut au 6 juillet 2026.*

## Réponse apportée

- **Deux apps générées par `ng new`** (Angular 22), sans SSR ni routing — page hello world unique :
  - `apps/frontend/` → « Hello from InfoLine » (image `infoline-frontend:local`, port hôte 8081)
  - `apps/backoffice/` → « Hello from InfoLine Backoffice » (image `infoline-backoffice:local`, 8082)
- **Dockerfile multi-stage** (`apps/frontend/Dockerfile`, `apps/backoffice/Dockerfile`) :
  - Stage `build` : `node:24-alpine` — `npm ci` puis `npm run build -- --configuration production`.
  - Stage runtime : `nginx:1.30-alpine` — ne récupère que `dist/<projet>/browser` (fichiers statiques),
    plus une `nginx.conf` minimale (`try_files … /index.html` pour un futur routing SPA).
- **Images construites et exécutées** : `docker build` puis `docker run -d -p 8081:80` / `-p 8082:80`
  → `docker ps` montre les deux conteneurs `Up`, rendu vérifié dans le navigateur.

## Preuves

- Code : `apps/frontend/` et `apps/backoffice/` (`Dockerfile`, `nginx.conf`, `.dockerignore`, `src/`).
- Captures :
  - `doc_project/captures/A2-Q4_dockerfile.md` — le Dockerfile (commun aux deux, variante `browser`
    notée).
  - `doc_project/captures/A2-Q4_ng-build-frontend.md` / `A2-Q4_ng-build-backoffice.md` — transcripts
    `ng build` réussis (bundle, output location).
  - `doc_project/captures/A2-Q4_docker-ps-browser.png` — `docker ps` (mappings 8081/8082) + les deux
    pages rendues dans le navigateur (preuve « parlante » du hello world).
- Reproduction : `RUNBOOK.md`, §5.2 « Fronts Angular (Docker) ».

## Pourquoi ces choix

Détail dans `architecture.md`, section « Applications Front — Angular » (pourquoi pas de SSR, pourquoi
multi-stage, pourquoi `node:24-alpine` / `nginx:1.30-alpine`, pourquoi pas d'utilisateur non-root créé
à la main, piège `dist/browser`, alternative S3 + CloudFront non retenue).

## Points techniques maîtrisés

**CSR pur : la preuve est une capture navigateur, pas un curl.** Sans SSR, la réponse HTTP de nginx ne
contient que la coquille `<app-root></app-root>` + un `<script>` ; le texte hello world est injecté
dans le DOM **après** exécution du JS par le navigateur. `curl` ne peut donc pas l'afficher — contraste
net avec l'API Spring Boot, qui **calcule** le texte côté serveur et le renvoie dans le corps HTTP.

**Piège `dist/browser`.** Le build Angular moderne (« application builder », défaut depuis Angular 17)
écrit dans `dist/<projet>/browser/`, pas `dist/<projet>/`. Le `COPY --from=build` cible donc
`…/browser` — sinon le site est cassé.

**Variante Node du piège « jar périmé ».** `node_modules` n'est jamais copié depuis l'hôte
(`.dockerignore`) : les binaires natifs (esbuild/Rollup) sont spécifiques à l'OS/arch, un `node_modules`
généré sous WSL/Windows copié dans Alpine casserait le build. `npm ci` le régénère **dans** le conteneur
avec les bons binaires — l'image porte toujours un build cohérent avec la source.

## Conformité

- **Fiches Studi mobilisées** :
  - **B2 P3** (containers) : Dockerfile multi-stage, ordre des couches pour le cache
    (`package*.json` avant `COPY . .`), une application par conteneur, tags précis plutôt que `latest`.
  - **B2 P1** (environnement de test) : reproductibilité (`npm ci` depuis lockfile), même version de
    Node en local et dans l'image (rapprochement dev/exécution).
- **Écarts assumés** :
  - **Pas de SSR ni de routing** — inutile pour un hello world 100 % statique.
  - **Pas de déploiement du front** — le sujet ne l'exige pas : A2-Q4/A2-Q5 s'arrêtent à
    « créer / build / test », sans verbe « déployez » ni infra cible, contrairement à A2-Q3 pour l'API.
    La dockerisation est un **choix de cohérence architecturale**, pas une exigence littérale.
  - **Docker + nginx gardé local** plutôt que S3 + CloudFront (plus idiomatique en prod pour un SPA) :
    aucun déploiement demandé → aucun coût d'hébergement continu à optimiser, et introduire un nouveau
    service AWS pour un hello world ne se justifie pas dans le budget-temps. Voir `architecture.md`.
  - **Pas de push vers un registry aujourd'hui** — hors périmètre A2-Q4 (le front n'est pas visé par
    la CI/CD de déploiement A2-Q3).

## Statut

| App | Build Angular | Image Docker | Conteneur | Doc | Captures |
|---|---|---|---|---|---|
| `frontend` (8081) | ✅ | ✅ `infoline-frontend:local` | ✅ (rendu OK) | ✅ | ✅ |
| `backoffice` (8082) | ✅ | ✅ `infoline-backoffice:local` | ✅ (rendu OK) | ✅ | ✅ |
