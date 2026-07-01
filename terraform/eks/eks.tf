# Le module officiel EKS gère pour nous : le control plane, les rôles IAM
# nécessaires, le node group managé, et l'intégration OIDC (utile plus tard
# pour IRSA si on donne des permissions IAM fines aux pods). On reste volontairement
# simple ici : un seul node group géré, suffisant pour le périmètre du sujet.

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Accès public à l'API du cluster pour pouvoir lancer kubectl/CI depuis
  # son poste sans VPN. A restreindre par CIDR en prod réelle.
  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  eks_managed_node_group_defaults = {
    instance_types = var.node_instance_types
  }

  eks_managed_node_groups = {
    main = {
      min_size     = var.node_min_size
      max_size     = var.node_max_size
      desired_size = var.node_desired_size

      instance_types = var.node_instance_types
      capacity_type  = "ON_DEMAND"
    }
  }
}
