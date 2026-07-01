# Sujet ECF — TP Administrateur Système DevOps

> Source : énoncé officiel Studi — Hiver 2025
> Durée indicative : 90 h — Documents autorisés : annexes

---

## Présentation de l'entreprise

InfoLine est une nouvelle agence qui souhaite gagner le marché dans le domaine de l'actualité des technologies sportives. L'objectif est de développer un site qui permet de montrer les actualités des outils sportifs connectés à la technologie. Le site doit permettre la promotion et la vente de certains produits. InfoLine souhaite distinguer entre deux types de clients : visiteurs, utilisateurs. Le visiteur n'est pas obligé de s'inscrire ou se connecter pour voir les annonces. Par contre, pour acheter un produit, il faut s'inscrire sur le site. Les produits sont gérés côté backoffice par des administrateurs qui peuvent ajouter/supprimer un produit.

Après une réunion des actionnaires InfoLine, la direction a décidé de démarrer par un budget limité dans un premier temps avec la possibilité d'augmenter la capacité si besoin.

Cela implique forcément d'aller au cloud vers des solutions qui offrent la scalabilité des ressources. L'équipe technique a décidé de séparer les applications pour diminuer le risque d'être hors service de l'application :

- API en Java à dockeriser et déployer sur Kubernetes
- Java function pour le login des utilisateurs/admin en serverless (ex. : AWS Lambda)
- Deux applications front-end en Angular (principale et backoffice)
- Database en PostgreSQL

Deux équipes sont montées, une pour le développement et l'autre pour la DevOps. Vous faites partie de l'équipe DevOps et on vous donne toute la responsabilité pour établir l'infrastructure. Vous avez décidé de passer par IaaS (Infrastructure As A Service) pour l'automatisation de la mise en place. Vous faites en sorte, avec l'équipe de développement, de mettre CI/CD pour les applications. Vu la sensibilité de l'application, la direction vous demande de monitorer l'état des applications et d'envoyer des notifications en cas de dysfonctionnement.

---

## Activité type 1 — Automatisation du déploiement d'infrastructure dans le Cloud

**A1-Q1** : Sur le fournisseur de votre choix, écrivez le code qui prépare :
- un cluster Kubernetes
- un service serverless (ex. : Lambda)

---

## Activité type 2 — Déploiement d'une application en continu

**A2-Q1** : Créez une application Java Spring Boot (hello world) à partir d'une image docker Java Spring Boot et exposez-la sur un port (de votre choix)

**A2-Q2** : Dockerisez votre application Java Spring Boot

**A2-Q3** : Écrivez le script qui build/test le Java Spring Boot et déployez-le sur le cluster Kubernetes créé

**A2-Q4** : Créez une application Angular (hello world)

**A2-Q5** : Écrivez le script qui build/test Angular (CircleCI est accepté)

---

## Activité Type 3 — Supervision des services déployés

**A3-Q1** : Mettez en place un Elasticsearch et connectez-le au Kubernetes

**A3-Q2** : Mettez en place un Kibana et connectez-le à Elasticsearch. Montrez des exemples de recherches sur les logs (Kibana queries)

---

## Livrables attendus

1. **Le lien Git** pour tout code écrit
2. **Une documentation technique** de vos solutions proposées
3. **La copie à rendre** avec les captures d'écran qui justifient vos démarches
   - Nommage : `ECF_BDOps_Hiver2025_copiearendre_NOM_Prenom`

---

## Correspondance questions ↔ phases projet

| Question ECF | Intitulé | Phase projet | Captures |
|---|---|---|---|
| A1-Q1 (partie 1) | Cluster Kubernetes en IaC | Phase 1 — EKS | A1-Q1_terraform-apply..., A1-Q1_eks-console.png, A1-Q1_terraform-destroy... |
| A1-Q1 (partie 2) | Serverless Lambda en IaC | Phase 1 — Lambda | À produire |
| A2-Q1 | Spring Boot hello world exposé sur un port | Phase 2 — Spring Boot | À produire |
| A2-Q2 | Dockerisation Spring Boot | Phase 2 — Spring Boot | À produire |
| A2-Q3 | CI/CD build/test/deploy Spring Boot → EKS | Phase 3 — CI/CD | À produire |
| A2-Q4 | Angular hello world | Phase 2 — Angular | À produire |
| A2-Q5 | CI/CD build/test Angular (CircleCI) | Phase 3 — CI/CD | À produire |
| A3-Q1 | Elasticsearch connecté à Kubernetes | Phase 4 — ELK | À produire |
| A3-Q2 | Kibana + exemples de queries sur logs | Phase 4 — ELK | À produire |
