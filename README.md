# InfoLine — ECF DevOps (Studi, promo Conway)

TP Administrateur Système DevOps. Sujet InfoLine : architecture microservices cloud —
API Java dockerisée et déployée sur EKS, login en Lambda serverless, deux fronts
Angular (principal + backoffice), base PostgreSQL, supervision via ELK. Infra
entièrement pilotée en Terraform (IaC).

## Structure du repo

- `terraform/` — IaC, un dossier par composant, chacun avec son propre state :
  `eks/` (cluster Kubernetes), `lambda-login/` (Lambda + API Gateway), `s3-test/`.
- `lambda-login/` — code source Java/Maven de la Lambda "login" (`terraform/lambda-login/`
  y référence le jar buildé).
- `api/` — API Java/Spring Boot (hello world), Dockerfile multi-stage (image
  `infoline-api`). Destinée à EKS via CI/CD (Phase 3).
- `apps/` — fronts Angular hello world (`frontend/` principal, `backoffice/`), chacun
  dockerisé multi-stage (`node` → `nginx`, images `infoline-frontend`/`infoline-backoffice`).
- `appflaskmin/` — appli Flask minimale du socle (Phase 0). Hello world volontairement
  triviaux : cf. contrainte de non sur-développement applicatif.
- `k8s/` — manifests Kubernetes.
- `.github/workflows/` — pipelines CI/CD (GitHub Actions), **seul outil CI réellement
  utilisé**. CircleCI (cité par le sujet) a été abandonné après un blocage account-level
  irrésolvable ; aucun fichier `.circleci/` n'est conservé dans le repo — cf.
  `architecture.md` § « Pourquoi GitHub Actions » et `FRICTIONS.md`.
- `doc_project/` — documentation du projet, voir ci-dessous.

## Documentation

- `architecture.md` — **schéma d'architecture global** (diagramme Mermaid en tête) + le
  "pourquoi" de chaque choix technique.
- `RUNBOOK.md` — comment construire/détruire/reconstruire chaque composant.
- `doc_project/sujet_ECF.md` — texte du sujet d'examen + correspondance questions ↔ phases.
- `doc_project/backlog.md` — avancement par phase, source de vérité.
- `doc_project/FRICTIONS.md` — journal chronologique des frictions et leçons retenues.
- `doc_project/{Question}_synthese.md` — une fiche par question ECF (ex.
  `A1-Q1_synthese.md`), pré-rédaction continue de la copie à rendre.
- `doc_project/captures/` — preuves brutes (transcripts terminal, captures d'écran),
  sans narratif.

## Pour les agents IA

`CLAUDE.md` (Claude Code) et `AGENTS.md` (OpenAI Codex) — contexte projet, contraintes
et rituel de fin de session, tenus synchronisés.
