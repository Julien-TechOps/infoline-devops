resource "aws_ecr_repository" "api" {
  name                 = "infoline-api"
  image_tag_mutability = "IMMUTABLE"   # <- remplace par la valeur réelle trouvée à l'étape 1

  image_scanning_configuration {
    scan_on_push = false             # <- idem, valeur réelle
  }
}

import {
  to = aws_ecr_repository.api
  id = "infoline-api"
}