# RUNBOOK — Build / Destroy / Redeploy

## Prérequis

## Build complet (from scratch)

## Destroy (fin de session / soir / week-end)

## Vérification post-déploiement

---

## Cluster EKS — Cycle de vie

### Déployer
```bash
cd terraform/eks
terraform init          # une seule fois, ou après changement de module
terraform plan -no-color -out=tfplan
terraform show -no-color tfplan > plan.txt   # relire avant d'appliquer
terraform apply tfplan
aws eks update-kubeconfig --region eu-west-3 --name infoline-eks
kubectl get nodes       # vérifier 2 nodes Ready
```

### Vérifier les versions disponibles (à faire si version.tf n'a pas été touché depuis longtemps)
```bash
aws eks describe-cluster-versions \
  --query "clusterVersions[?status=='STANDARD_SUPPORT'].clusterVersion" \
  --output table
```

### Détruire (fin de session — obligatoire)
```bash
cd terraform/eks
terraform destroy
terraform state list    # doit être vide
aws eks list-clusters --region eu-west-3          # doit être vide
aws ec2 describe-nat-gateways --region eu-west-3 \
  --filter "Name=state,Values=available"          # doit être vide
```

### En cas de "deposed object"
Normal. Correspond à un cycle create-before-destroy interrompu. Le prochain `apply` nettoie automatiquement. Ne pas lancer de `terraform destroy` en panique.
