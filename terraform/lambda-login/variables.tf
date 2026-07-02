variable "aws_region" {
  description = "Region AWS. Reprendre la meme valeur que terraform/eks/terraform.tfvars pour rester coherent avec le reste de l'infra InfoLine."
  type        = string
}

variable "function_name" {
  description = "Nom de la fonction Lambda."
  type        = string
  default     = "infoline-login"
}

variable "jar_path" {
  description = "Chemin du jar Lambda build par Maven, relatif a terraform/lambda-login/. A construire au prealable avec `mvn -f ../../lambda-login package`."
  type        = string
  default     = "../../lambda-login/target/lambda-login.jar"
}

variable "route_path" {
  description = "Chemin de la route API Gateway qui declenche la Lambda."
  type        = string
  default     = "/login"
}

variable "tags" {
  description = "Tags communs appliques aux ressources."
  type        = map(string)
  default = {
    Project   = "InfoLine"
    Bloc      = "A1"
    Composant = "login-serverless"
  }
}
