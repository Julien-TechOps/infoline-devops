# Phase 1 — A1 : Cluster EKS via Terraform

Cette config provisionne :
- un **VPC** dédié (2 AZ, sous-réseaux publics + privés, NAT Gateway) ;
- un **cluster EKS** managé, avec un **node group** de 2 instances `t3.medium`.

Elle répond à la première moitié de la question A1 du sujet ECF :
> *« écrivez le code qui prépare un kube kubernetes »*

## Pré-requis

- AWS CLI configuré (`aws configure`) avec un compte ayant les droits IAM/EC2/EKS/VPC.
- Terraform >= 1.6 installé.
- `kubectl` installé.

## Étapes

```bash
# 1. Copier et adapter les variables si besoin
cp terraform.tfvars.example terraform.tfvars

# 2. Initialiser (télécharge les modules + le provider AWS)
terraform init

# 3. Vérifier ce qui va être créé
terraform plan

# 4. Appliquer (compter ~12-15 min, EKS est lent à provisionner)
terraform apply

# 5. Configurer kubectl avec le cluster fraîchement créé
aws eks update-kubeconfig --region eu-west-3 --name infoline-eks

# 6. Vérifier que les nodes répondent
kubectl get nodes
```

## Points à documenter dans la copie (A1-Q1)

- Capture de `terraform apply` qui se termine sans erreur.
- Capture de `kubectl get nodes` montrant les 2 nodes en `Ready`.
- 2-3 lignes sur le **pourquoi** : VPC dédié avec subnets privés pour les
  nodes (pas d'exposition directe Internet), module officiel plutôt que
  ressources brutes (fiabilité, moins de code à maintenir), node group managé
  par AWS (auto-remplacement des instances défaillantes, mise à jour facilitée).

## Nettoyage (important pour le budget AWS)

```bash
terraform destroy
```
EKS facture le control plane à l'heure même inutilisé — à détruire en dehors
des sessions de travail si le budget est serré.

## Prochaine étape

Une fois ce cluster validé, la brique suivante de la Phase 1 est la **Lambda
serverless** (login InfoLine) provisionnée elle aussi en Terraform — dossier
séparé pour garder une séparation claire entre les deux livrables A1.
