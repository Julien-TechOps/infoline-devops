# A2-Q5 — Script qui build/test les applications Angular

*Pipeline CI qui build et teste les deux fronts Angular à chaque push. Statut au 10 juillet 2026 :
réalisé en **GitHub Actions** (bascule assumée depuis CircleCI, cf. « Écart outil assumé »), vert de
bout en bout.*

## Réponse apportée

Le workflow `.github/workflows/angular.yml` build et teste les deux apps à chaque push sur `main`,
sans déploiement (le sujet A2-Q5 s'arrête à « build/test ») :
- **Matrice** `frontend` / `backoffice` — les deux apps passent le même pipeline en parallèle.
- **Étapes** (par app, `working-directory: apps/<app>`) : `actions/setup-node@v4` (Node 24, cache npm)
  → `npm ci` (install reproductible depuis le lockfile) → `npx ng build` → `npx ng test --watch=false`.
- **Vert de bout en bout** (commit `e96fac6`) : matrice `frontend` + `backoffice`, rapport Vitest
  `2 passes · 2 total` pour chaque app.

## Preuves

- Code : `.github/workflows/angular.yml`.
- Captures :
  - `doc_project/captures/A2-Q5_pipeline-green.png` — run vert, matrice 2 apps + résumé Vitest.
  - `doc_project/captures/A2-Q5_build-test-logs-ex-frontend.png` — logs détaillés des steps `Build`
    (`ng build`) + `Run tests` (`ng test --watch=false`), exemple `frontend` (backoffice identique,
    prouvé passant par la vue matrice).
- Reproduction : le pipeline se déclenche à chaque push `main` (cf. `RUNBOOK.md`, §3).

## Pourquoi ces choix

- **`npm ci` (pas `npm install`)** : install reproductible depuis le lockfile exact (fiche B2 P1).
- **Node 24 en CI = Node 24 en local et dans l'image Docker** : rapprochement dev/exécution.
- **`ng test --watch=false`** : exécution one-shot (pas de watcher interactif) adaptée à la CI ; runner
  **Vitest** (défaut Angular 22 — le flag Karma `--browsers` a été retiré car incompatible, cf.
  `FRICTIONS.md`).
- **Pas de déploiement** : contrairement à A2-Q3 (« déployez sur le kube »), A2-Q5 s'arrête à
  build/test — aucun verbe « déployez » ni infra cible. Cadrage détaillé dans `A2-Q4_synthese.md`.

## Écart outil assumé

Le sujet cite CircleCI (« CircleCI est accepté ») ; la copie livre GitHub Actions. Même écart qu'en
A2-Q3 : blocage account-level CircleCI non imputable au candidat (ticket #173426, cf. `FRICTIONS.md`
Jeu 9 juil), résolu par un outil CI/CD équivalent et natif à GitHub. La compétence évaluée (automatiser
le build/test) est démontrée à l'identique ; seul l'outil change.

## Conformité

- **Fiche Studi mobilisée** : **B2 P4** (automatiser build/test).
- **Écarts assumés** :
  - **Pas de déploiement du front** — hors périmètre A2-Q5 (build/test uniquement).
  - **Option de preuve minimaliste** : logs détaillés capturés sur `frontend` seul ; `backoffice`
    (hello world quasi jumeau) prouvé passant par la vue matrice. Défendable pour un hello world.

## Statut

| App | Build (`ng build`) | Test (`ng test`) | Pipeline CI | Captures |
|---|---|---|---|---|
| `frontend` | ✅ | ✅ 2 passes | ✅ vert (`e96fac6`) | ✅ |
| `backoffice` | ✅ | ✅ 2 passes | ✅ vert (`e96fac6`) | ✅ (via matrice) |
