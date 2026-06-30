# CLAUDE.md — ECF DevOps (InfoLine)

## Contexte
TP Administrateur Système DevOps (Studi, promo Conway). Sujet InfoLine : architecture
microservices cloud — API Spring Boot dockerisée et déployée sur EKS, login en Lambda
serverless, deux fronts Angular (principal + backoffice), base PostgreSQL, supervision
via ELK (Elasticsearch + Kibana sur les logs Kubernetes). Infra entièrement pilotée en
Terraform (IaC). Dépôt final le 23 juillet 2026.

## Priorité absolue (à rappeler à chaque session)
1. PRO — faire fonctionner l'infra et les déploiements.
2. Académique — documenter et capturer ensuite, mais **au fil de l'eau, jamais reporté
   à la fin**. La Phase 5 (doc) est compressée à ~25h : sans rédaction continue depuis
   la Phase 1, elle ne suffira pas.

## Contraintes dures
- Ne JAMAIS sur-développer le code applicatif (Spring Boot / Angular = hello world
  volontairement triviaux). Le métier ici est l'empaquetage et le déploiement, pas le
  développement applicatif. Timeboxer durement, ne pas proposer d'améliorations non
  demandées sur ces deux apps.
- Toujours rappeler de faire `terraform destroy` en fin de session, le soir et le
  week-end (EKS + node groups coûtent à l'heure sur AWS).
- ELK est la techno la moins maîtrisée du projet : ne pas la sous-estimer, lui laisser
  de la marge.
- Calendrier sans marge réelle (16 jours ouvrés, ~112h) : ne jamais proposer de scope
  creep, de "pendant qu'on y est on pourrait aussi...".

## Rituel de fin de session (non négociable)
1. Commit Git (le lien Git est un livrable noté).
2. Ajouter une entrée dans `doc_project/FRICTIONS.md`.
3. Nommer les captures par question (ex. `A2-Q2_dockerfile.png`).
4. Ajouter 2-3 lignes dans `architecture.md`, même courtes.
5. Mettre à jour les statuts de la phase en cours dans `doc_project/backlog.md`.

## Fichiers de référence
- `doc_project/backlog.md` — source de vérité de l'avancement par phase.
- `doc_project/FRICTIONS.md` — journal chronologique, une entrée par session.
- `architecture.md` — le "pourquoi" de chaque choix technique (réutilisable telle
  quelle dans la doc technique finale).
- `RUNBOOK.md` — procédure de build/destroy/redeploy. À retester régulièrement : c'est
  littéralement la répétition du run final noté par le jury.

## Conventions
- Nomenclature du dépôt final : `ECF_BDOps_Hiver2025_copiearendre_NOM_Prenom`.
- Le repo Git est lui-même un livrable noté : structure et lisibilité comptent.
