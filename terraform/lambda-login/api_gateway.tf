# ---------------------------------------------------------------------------
# API Gateway HTTP API (v2) : declencheur de la Lambda. Choisie plutot qu'une
# REST API (v1) - moins de ressources a gerer, moins chere a l'usage, ce qui
# colle au budget limite d'InfoLine.
# ---------------------------------------------------------------------------
resource "aws_apigatewayv2_api" "login" {
  name          = "${var.function_name}-api"
  protocol_type = "HTTP"
  tags          = var.tags
}

resource "aws_apigatewayv2_integration" "login" {
  api_id                 = aws_apigatewayv2_api.login.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.login.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "login" {
  api_id    = aws_apigatewayv2_api.login.id
  route_key = "ANY ${var.route_path}"
  target    = "integrations/${aws_apigatewayv2_integration.login.id}"
}

# Stage $default + auto_deploy : pas de ressource de deploiement manuelle,
# chaque apply republie automatiquement.
resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.login.id
  name        = "$default"
  auto_deploy = true
  tags        = var.tags
}

# Sans cette permission, API Gateway ne peut pas invoquer la Lambda
# (erreur 500 silencieuse cote client sinon).
resource "aws_lambda_permission" "apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.login.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.login.execution_arn}/*/*"
}
