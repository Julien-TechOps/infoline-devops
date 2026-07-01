terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }
  }

  # Optionnel mais recommandé : stocker le state à distance (S3 + DynamoDB lock)
  # plutôt qu'en local, pour éviter de le perdre / le versionner par erreur.
  # A configurer une fois le bucket S3 créé manuellement (chicken-and-egg classique) :
  #
  # backend "s3" {
  #   bucket         = "infoline-terraform-state"
  #   key            = "phase1/eks-lambda/terraform.tfstate"
  #   region         = "eu-west-3"
  #   dynamodb_table = "infoline-terraform-locks"
  #   encrypt        = true
  # }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "InfoLine"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
