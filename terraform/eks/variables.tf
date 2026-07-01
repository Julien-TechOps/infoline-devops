variable "aws_region" {
  description = "Région AWS où provisionner l'infrastructure"
  type        = string
  default     = "eu-west-3" # Paris
}

variable "environment" {
  description = "Nom de l'environnement (dev / staging / prod)"
  type        = string
  default     = "dev"
}

variable "cluster_name" {
  description = "Nom du cluster EKS"
  type        = string
  default     = "infoline-eks"
}

variable "cluster_version" {
  description = "Version de Kubernetes pour le cluster EKS"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "Bloc CIDR du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Zones de disponibilité utilisées"
  type        = list(string)
  default     = ["eu-west-3a", "eu-west-3b"]
}

variable "private_subnets" {
  description = "CIDR des sous-réseaux privés (nodes EKS)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "public_subnets" {
  description = "CIDR des sous-réseaux publics (load balancers, NAT)"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24"]
}

variable "node_instance_types" {
  description = "Types d'instance EC2 pour le node group"
  type        = list(string)
  default     = ["t3.micro"]
}

variable "node_desired_size" {
  description = "Nombre de nodes souhaité"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Nombre de nodes minimum"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Nombre de nodes maximum"
  type        = number
  default     = 3
}
