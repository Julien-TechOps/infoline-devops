# ---------------------------------------------------------------------------
# Packaging : le jar est construit en amont par Maven (mvn package dans
# ../../lambda-login/), pas par Terraform. source_code_hash force le
# redeploiement uniquement si le jar a change.
# ---------------------------------------------------------------------------
locals {
  jar_path = "${path.module}/${var.jar_path}"
}

# ---------------------------------------------------------------------------
# IAM - role assume par la Lambda. Principe du moindre privilege : seule la
# politique managee AWSLambdaBasicExecutionRole est attachee (ecriture des
# logs CloudWatch). Aucun droit large de type AdministratorAccess.
# ---------------------------------------------------------------------------
data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_exec" {
  name               = "${var.function_name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ---------------------------------------------------------------------------
# Fonction Lambda - hello world "login" (cf. doc_project/sujet_ECF.md :
# "java function pour le login... en serverless"). Jar construit par Maven
# depuis ../../lambda-login/ (com.infoline.login.LoginHandler).
# ---------------------------------------------------------------------------
resource "aws_lambda_function" "login" {
  function_name    = var.function_name
  filename         = local.jar_path
  source_code_hash = filebase64sha256(local.jar_path)
  handler          = "com.infoline.login.LoginHandler::handleRequest"
  runtime          = "java21"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 10
  memory_size      = 256

  tags = var.tags
}
