# Le VPC est un prérequis EKS : il faut des sous-réseaux publics (pour les
# load balancers / NAT) ET privés (pour que les nodes ne soient pas exposés
# directement sur Internet). On utilise le module officiel plutôt que de
# tout écrire à la main : c'est la référence de facto pour ce pattern,
# maintenue par la communauté + AWS.

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"   # module communautaire (pas écrit à la main)
  version = "~> 5.8"                          # version épinglée, pas "latest"

  name = "${var.cluster_name}-vpc"            # → "infoline-eks-vpc" (cluster_name vient de tfvars)
  cidr = var.vpc_cidr                         # → "10.0.0.0/16" (DÉFAUT — jamais surchargé)

  azs             = var.azs                   # → ["eu-west-3a", "eu-west-3b"] (DÉFAUT)
  private_subnets = var.private_subnets       # → ["10.0.1.0/24", "10.0.2.0/24"] (DÉFAUT)
  public_subnets  = var.public_subnets        # → ["10.0.101.0/24", "10.0.102.0/24"] (DÉFAUT)

  enable_nat_gateway   = true
  single_nat_gateway   = true                 # ← un seul NAT Gateway = moins cher, suffisant pour un ECF
  enable_dns_hostnames = true                 # nécessaire pour que les nodes EKS aient un hostname résoluble
  enable_dns_support   = true                 # active la résolution DNS interne du VPC (Route 53 Resolver)

  # Tags obligatoires pour qu'EKS et le contrôleur d'Ingress AWS Load Balancer
  # sachent quels sous-réseaux utiliser automatiquement.
  public_subnet_tags = {
    "kubernetes.io/role/elb"                     = "1"          # ← "pose les LB publics ici"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"     # ← "ce subnet appartient à infoline-eks"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"            = "1"          # ← "pose les LB internes ici"
    "kubernetes.io/cluster/${var.cluster_name}"  = "shared"
  }
}
