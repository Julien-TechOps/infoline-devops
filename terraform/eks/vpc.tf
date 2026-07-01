# Le VPC est un prérequis EKS : il faut des sous-réseaux publics (pour les
# load balancers / NAT) ET privés (pour que les nodes ne soient pas exposés
# directement sur Internet). On utilise le module officiel plutôt que de
# tout écrire à la main : c'est la référence de facto pour ce pattern,
# maintenue par la communauté + AWS.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.8"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  private_subnets = var.private_subnets
  public_subnets  = var.public_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true # un seul NAT Gateway = moins cher, suffisant pour un ECF
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Tags obligatoires pour qu'EKS et le contrôleur d'Ingress AWS Load Balancer
  # sachent quels sous-réseaux utiliser automatiquement.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                     = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = "1"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}
