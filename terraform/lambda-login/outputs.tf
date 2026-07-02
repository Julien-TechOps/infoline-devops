output "function_name" {
  description = "Nom de la fonction Lambda deployee (utile pour aws lambda invoke)."
  value       = aws_lambda_function.login.function_name
}

output "function_arn" {
  description = "ARN de la fonction Lambda."
  value       = aws_lambda_function.login.arn
}

output "api_endpoint" {
  description = "URL de base de l'API Gateway (sans le chemin /login)."
  value       = aws_apigatewayv2_api.login.api_endpoint
}

output "invoke_url" {
  description = "URL complete a appeler pour tester la Lambda."
  value       = "${aws_apigatewayv2_stage.default.invoke_url}${var.route_path}"
}
