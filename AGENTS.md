# AGENTS.md — ECF DevOps (InfoLine)

## Contexte du projet
TP Administrateur Système DevOps (Studi, promo Conway). Sujet InfoLine : architecture
microservices cloud — API Spring Boot dockerisée et déployée sur EKS, login en Lambda
serverless, deux fronts Angular (principal + backoffice), base PostgreSQL, supervision
via ELK (Elasticsearch + Kibana sur les logs Kubernetes). Infra entièrement pilotée en
Terraform (IaC). Dépôt final le 23 juillet 2026.

## Priorité absolue
1. PRO — faire fonctionner l'infra et les déploiements.
2. Académique — documenter et capturer au fil de l'eau, jamais reporté à la fin.
   La Phase 5 (doc) est compressée à ~25h : sans rédaction continue, elle ne suffira pas.

## Contraintes dures
- Ne JAMAIS sur-développer le code applicatif (Spring Boot / Angular = hello world
  volontairement triviaux). Le métier ici est l'empaquetage et le déploiement.
  Ne pas proposer d'améliorations non demandées sur ces deux apps.
- Rappeler de faire `terraform destroy` en fin de session (EKS + node groups coûtent
  à l'heure sur AWS).
- ELK est la techno la moins maîtrisée : lui laisser de la marge dans le planning.
- Calendrier sans marge réelle (16 jours ouvrés, ~112h) : ne jamais proposer de scope
  creep.

## Questions ECF et correspondance phases

Texte complet dans `doc_project/sujet_ECF.md`. Correspondance rapide :

| Question | Intitulé | Phase projet |
|---|---|---|
| A1-Q1 (1/2) | Cluster Kubernetes en IaC (EKS + Terraform) | Phase 1 — EKS |
| A1-Q1 (2/2) | Serverless Lambda en IaC | Phase 1 — Lambda |
| A2-Q1 | Spring Boot hello world exposé sur un port | Phase 2 — Spring Boot |
| A2-Q2 | Dockerisation Spring Boot | Phase 2 — Spring Boot |
| A2-Q3 | CI/CD build/test/deploy Spring Boot → EKS | Phase 3 — CI/CD |
| A2-Q4 | Angular hello world | Phase 2 — Angular |
| A2-Q5 | CI/CD build/test Angular (CircleCI) | Phase 3 — CI/CD |
| A3-Q1 | Elasticsearch connecté à Kubernetes | Phase 4 — ELK |
| A3-Q2 | Kibana + exemples de queries sur logs | Phase 4 — ELK |

Nommer chaque capture selon la question : `A2-Q2_dockerfile.png`, `A3-Q1_elasticsearch-pod.png`, etc.

## Rituel de fin de session
1. Commit Git (le lien Git est un livrable noté).
2. Ajouter une entrée dans `doc_project/FRICTIONS.md`.
3. Nommer les captures par question (ex. `A2-Q2_dockerfile.png`), déposées dans
   `doc_project/captures/` (preuve brute uniquement — pas de narratif dedans).
4. Ajouter 2-3 lignes dans `architecture.md`, même courtes.
5. Mettre à jour les statuts de la phase en cours dans `doc_project/backlog.md`.
6. Mettre à jour `doc_project/{Question}_synthese.md` (un fichier par question ECF,
   pas par sous-partie technique — cf. section suivante).

## Fichiers de référence
- `doc_project/backlog.md` — source de vérité de l'avancement par phase (colonne Question ECF incluse).
- `doc_project/sujet_ECF.md` — texte complet du sujet d'examen + table de correspondance.
- `doc_project/FRICTIONS.md` — journal chronologique, une entrée par session.
- `architecture.md` — le "pourquoi" de chaque choix technique.
- `doc_project/{Question}_synthese.md` — un par question ECF (ex. `A1-Q1_synthese.md`
  couvre EKS + Lambda), pré-rédaction continue de la copie à rendre : réponse apportée,
  pointeurs vers le code/README/captures, pointeur vers `architecture.md` pour le
  "pourquoi", fiches Studi mobilisées, écarts assumés, statut. Ne jamais y dupliquer du
  contenu qui a déjà un autre foyer (architecture, procédure, statut, frictions).
- `doc_project/captures/` — preuves brutes uniquement (transcripts terminal sans
  narratif, captures d'écran). Jamais de récit ou de justification ici.
- `RUNBOOK.md` — procédure de build/destroy/redeploy.

## Conventions
- Nomenclature du dépôt final : `ECF_BDOps_Hiver2025_copiearendre_NOM_Prenom`.
- Le repo Git est lui-même un livrable noté : structure et lisibilité comptent.
- Ne modifier aucun fichier `.tf`, `.py`, `.yml` ou code applicatif sans demande explicite.
