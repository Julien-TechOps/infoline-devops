# Backlog — ECF DevOps InfoLine (miroir de Roadmap_ECF_DevOps_v4)

**Dernière mise à jour :** Mer 1 juil 2026

## Légende
✅ fait et vérifié · 🔶 en cours / partiel · ❌ pas commencé · — non applicable à cette étape

## Livrables finaux (jury)
- [ ] Lien Git de tout le code (commit à chaque session, repo public/accessible)
- [ ] Documentation technique (architecture.md + schéma d'architecture)
- [ ] Copie à rendre + captures (nomenclature : ECF_BDOps_Hiver2025_copiearendre_NOM_Prenom)

## Où j'en suis / prochaine action
Phase 1 A1 terminée : VPC + cluster EKS + node group provisionnés, 2 nodes Ready v1.34, destroy propre confirmé.
Prochaine session (Jeu 2 juil) : Lambda + API Gateway en Terraform.

## Avancement par phase

| Date | Phase | Objectif (PRO) | Fiche(s) | Infra | Doc | Captures |
|---|---|---|---|---|---|---|
| 18-19 juin | Phase 0 — Socle | AWS + Terraform + Docker réactivés | B1 P3, P7 · B2 P3 | ✅ | ✅ | ✅ |
| Mer 1 juil | Phase 1 — EKS | Cluster EKS provisionné par Terraform | B1 P4, P7 | ✅ | ✅ | ❌ |
| Jeu 2 juil | Phase 1 — Lambda | Lambda + API Gateway en Terraform | B1 P4, P7 | ❌ | ❌ | ❌ |
| Ven 3 juil | Phase 2 — Spring Boot | API Spring Boot dockerisée | B2 P3 | ❌ | ❌ | ❌ |
| Lun 6 juil | Phase 2 — Angular | App Angular dockerisée | B2 P3 | ❌ | ❌ | ❌ |
| 7-10 juil | Phase 3 — CI/CD | Pipelines CircleCI build/test/deploy sur EKS | B2 P1, P3, P4 · B1 P1 | ❌ | ❌ | ❌ |
| 13-15 juil | Phase 4 — ELK | Elasticsearch + Kibana sur logs K8s | B3 P1-P4 | ❌ | ❌ | ❌ |
| 16 juil | Tampon technique | Absorber le dérapage le plus probable (ELK/CircleCI) | Selon trous | ❌ | — | — |
| 17 juil | Phase 5 — Doc archi | Schéma d'architecture complet + repo Git propre | B1 P1 | — | ❌ | — |
| 20 juil | Phase 5 — Copie A1+A2 | Rédaction copie, Activités 1 et 2 | B1, B2 | — | ❌ | ❌ |
| 21 juil | Phase 5 — Copie A3 | Rédaction copie A3 + relecture globale | B3 · Toutes | — | ❌ | ❌ |
| 22 juil (matin) | Phase 5 — Tampon final | Rattrapages avant le run, vérif des 3 livrables | Selon trous | — | ❌ | ❌ |
| 22 juil (après-midi) | Finalisation | Run complet (destroy+rebuild sans intervention manuelle) + dépôt | Toutes | ❌ | ❌ | ❌ |
