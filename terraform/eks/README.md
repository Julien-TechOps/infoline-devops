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

## Documentation

Rationale complète dans `architecture.md` (section "Cluster Kubernetes — Amazon EKS"),
synthèse pour la copie dans `doc_project/A1-Q1_synthese.md`.

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
