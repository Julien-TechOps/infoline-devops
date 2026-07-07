# Backlog — ECF DevOps InfoLine (miroir de Roadmap_ECF_DevOps_v4)

**Dernière mise à jour :** Mar 7 juil 2026

## Légende
✅ fait et vérifié · 🔶 en cours / partiel · ❌ pas commencé · — non applicable à cette étape

## Livrables finaux (jury)
- [ ] Lien Git de tout le code (commit à chaque session, repo public/accessible)
- [ ] Documentation technique (architecture.md + schéma d'architecture)
- [ ] Copie à rendre + captures (nomenclature : ECF_BDOps_Hiver2025_copiearendre_NOM_Prenom)

## Où j'en suis / prochaine action
Phase 1 A1 terminée : VPC + cluster EKS + node group provisionnés, 2 nodes Ready v1.34, destroy propre confirmé.
Phase 1 Lambda terminée : bug de structure (dossier imbriqué cassant `source_dir`) détecté et corrigé avant apply, handler basculé en Java (conformité énoncé), `terraform apply` exécuté (8 ressources), invocation validée par curl et `aws lambda invoke`. Validation façon formateur (7 blocs) faite avec Claude.ai. Reste : captures CLI optionnelles (transcript déjà complet), commit Git.
Phase 2 Spring Boot terminée (Ven 3 juil) : API Spring Boot 4.1 / Java 21 (`api/`), endpoint `/hello` sur `:8080` validé en local, Dockerfile multi-stage (image `infoline-api:local` ~92 Mo, utilisateur non-root), conteneur vérifié HTTP 200. Couvre A2-Q1 et A2-Q2 (deux synthèses créées).
Phase 2 Angular terminée (Lun 6 juil) : deux apps Angular 22 hello world (`apps/frontend/` + `apps/backoffice/`), dockerisées multi-stage `node:24-alpine` → `nginx:1.30-alpine`, servies en local sur 8081/8082, rendu vérifié au navigateur. Couvre A2-Q4 (synthèse créée). Écart cadré : le sujet n'exige pas le déploiement du front (dockerisation = choix de cohérence, cf. `A2-Q4_synthese.md`).
Phase 3 démarrée (Mar 7 juil) : API Spring Boot déployée **manuellement** sur EKS — image ECR (tag = SHA court `23547c5`), manifestes versionnés (`k8s/api-deployment.yaml` 2 replicas + `k8s/api-service.yaml` LoadBalancer), `curl http://<elb-dns>/hello` OK de bout en bout. Couvre A2-Q3 partie 1/2 (déploiement) ; partie 2/2 (pipeline CircleCI) à venir. Friction structurante : le cluster détruit la veille impose un `terraform apply` (~15-20 min) en début de session.
Prochaine session (8-10 juil) : Phase 3 — pipelines CircleCI (A2-Q3 build/test/deploy API → EKS automatisé, A2-Q5 build/test Angular). Point à traiter : passer le repo ECR en IaC.

## Avancement par phase

| Date | Phase | Question ECF | Objectif (PRO) | Infra | Doc | Captures |
|---|---|---|---|---|---|---|
| 18-19 juin | Phase 0 — Socle | — | AWS + Terraform + Docker réactivés | ✅ | ✅ | ✅ |
| Mer 1 juil | Phase 1 — EKS | A1-Q1 (1/2) | Cluster EKS provisionné par Terraform | ✅ | ✅ | ✅ |
| Jeu 2 juil | Phase 1 — Lambda | A1-Q1 (2/2) | Lambda + API Gateway en Terraform | ✅ | ✅ | ✅ |
| Ven 3 juil | Phase 2 — Spring Boot | A2-Q1 · A2-Q2 | API Spring Boot dockerisée | ✅ | ✅ | ✅ |
| Lun 6 juil | Phase 2 — Angular | A2-Q4 | Apps Angular (frontend + backoffice) dockerisées | ✅ | ✅ | ✅ |
| 7-10 juil | Phase 3 — CI/CD | A2-Q3 · A2-Q5 | Pipelines CircleCI build/test/deploy sur EKS (A2-Q3 déploiement manuel fait, pipeline à venir) | 🔶 | 🔶 | 🔶 |
| 13-15 juil | Phase 4 — ELK | A3-Q1 · A3-Q2 | Elasticsearch + Kibana sur logs K8s | ❌ | ❌ | ❌ |
| 16 juil | Tampon technique | Selon trous | Absorber le dérapage le plus probable (ELK/CircleCI) | ❌ | — | — |
| 17 juil | Phase 5 — Doc archi | Toutes | Schéma d'architecture complet + repo Git propre | — | ❌ | — |
| 20 juil | Phase 5 — Copie A1+A2 | A1 · A2 | Rédaction copie, Activités 1 et 2 | — | ❌ | ❌ |
| 21 juil | Phase 5 — Copie A3 | A3 | Rédaction copie A3 + relecture globale | — | ❌ | ❌ |
| 22 juil (matin) | Phase 5 — Tampon final | Selon trous | Rattrapages avant le run, vérif des 3 livrables | — | ❌ | ❌ |
| 22 juil (après-midi) | Finalisation | Toutes | Run complet (destroy+rebuild sans intervention manuelle) + dépôt | ❌ | ❌ | ❌ |
