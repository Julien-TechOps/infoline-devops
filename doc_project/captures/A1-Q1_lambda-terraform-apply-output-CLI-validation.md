julien@Julien:~/infoline-devops/terraform/lambda-login$ terraform apply
data.aws_iam_policy_document.assume_role: Reading...
data.aws_iam_policy_document.assume_role: Read complete after 0s [id=2690255455]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create

Terraform will perform the following actions:

  # aws_apigatewayv2_api.login will be created
  + resource "aws_apigatewayv2_api" "login" {
      + api_endpoint                 = (known after apply)
      + api_key_selection_expression = "$request.header.x-api-key"
      + arn                          = (known after apply)
      + execution_arn                = (known after apply)
      + id                           = (known after apply)
      + ip_address_type              = (known after apply)
      + name                         = "infoline-login-api"
      + protocol_type                = "HTTP"
      + route_selection_expression   = "$request.method $request.path"
      + tags                         = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + tags_all                     = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
    }

  # aws_apigatewayv2_integration.login will be created
  + resource "aws_apigatewayv2_integration" "login" {
      + api_id                                    = (known after apply)
      + connection_type                           = "INTERNET"
      + id                                        = (known after apply)
      + integration_response_selection_expression = (known after apply)
      + integration_type                          = "AWS_PROXY"
      + integration_uri                           = (known after apply)
      + payload_format_version                    = "2.0"
      + timeout_milliseconds                      = (known after apply)
    }

  # aws_apigatewayv2_route.login will be created
  + resource "aws_apigatewayv2_route" "login" {
      + api_id             = (known after apply)
      + api_key_required   = false
      + authorization_type = "NONE"
      + id                 = (known after apply)
      + route_key          = "ANY /login"
      + target             = (known after apply)
    }

  # aws_apigatewayv2_stage.default will be created
  + resource "aws_apigatewayv2_stage" "default" {
      + api_id        = (known after apply)
      + arn           = (known after apply)
      + auto_deploy   = true
      + deployment_id = (known after apply)
      + execution_arn = (known after apply)
      + id            = (known after apply)
      + invoke_url    = (known after apply)
      + name          = "$default"
      + tags          = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + tags_all      = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
    }

  # aws_iam_role.lambda_exec will be created
  + resource "aws_iam_role" "lambda_exec" {
      + arn                   = (known after apply)
      + assume_role_policy    = jsonencode(
            {
              + Statement = [
                  + {
                      + Action    = "sts:AssumeRole"
                      + Effect    = "Allow"
                      + Principal = {
                          + Service = "lambda.amazonaws.com"
                        }
                    },
                ]
              + Version   = "2012-10-17"
            }
        )
      + create_date           = (known after apply)
      + force_detach_policies = false
      + id                    = (known after apply)
      + managed_policy_arns   = (known after apply)
      + max_session_duration  = 3600
      + name                  = "infoline-login-exec-role"
      + name_prefix           = (known after apply)
      + path                  = "/"
      + tags                  = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + tags_all              = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + unique_id             = (known after apply)

      + inline_policy (known after apply)
    }

  # aws_iam_role_policy_attachment.lambda_logs will be created
  + resource "aws_iam_role_policy_attachment" "lambda_logs" {
      + id         = (known after apply)
      + policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
      + role       = "infoline-login-exec-role"
    }

  # aws_lambda_function.login will be created
  + resource "aws_lambda_function" "login" {
      + architectures                  = (known after apply)
      + arn                            = (known after apply)
      + code_sha256                    = (known after apply)
      + filename                       = "./../../lambda-login/target/lambda-login.jar"
      + function_name                  = "infoline-login"
      + handler                        = "com.infoline.login.LoginHandler::handleRequest"
      + id                             = (known after apply)
      + invoke_arn                     = (known after apply)
      + last_modified                  = (known after apply)
      + memory_size                    = 256
      + package_type                   = "Zip"
      + publish                        = false
      + qualified_arn                  = (known after apply)
      + qualified_invoke_arn           = (known after apply)
      + reserved_concurrent_executions = -1
      + role                           = (known after apply)
      + runtime                        = "java21"
      + signing_job_arn                = (known after apply)
      + signing_profile_version_arn    = (known after apply)
      + skip_destroy                   = false
      + source_code_hash               = "RJj+eW4orTxvROpTRhhaj192lv+IUIb8ch9gnE1agQE="
      + source_code_size               = (known after apply)
      + tags                           = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + tags_all                       = {
          + "Bloc"      = "A1"
          + "Composant" = "login-serverless"
          + "Project"   = "InfoLine"
        }
      + timeout                        = 10
      + version                        = (known after apply)

      + ephemeral_storage (known after apply)

      + logging_config (known after apply)

      + tracing_config (known after apply)
    }

  # aws_lambda_permission.apigw will be created
  + resource "aws_lambda_permission" "apigw" {
      + action              = "lambda:InvokeFunction"
      + function_name       = "infoline-login"
      + id                  = (known after apply)
      + principal           = "apigateway.amazonaws.com"
      + source_arn          = (known after apply)
      + statement_id        = "AllowAPIGatewayInvoke"
      + statement_id_prefix = (known after apply)
    }

Plan: 8 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + api_endpoint  = (known after apply)
  + function_arn  = (known after apply)
  + function_name = "infoline-login"
  + invoke_url    = (known after apply)

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_iam_role.lambda_exec: Creating...
aws_apigatewayv2_api.login: Creating...
aws_apigatewayv2_api.login: Creation complete after 2s [id=<API_ID>]
aws_apigatewayv2_stage.default: Creating...
aws_iam_role.lambda_exec: Creation complete after 2s [id=infoline-login-exec-role]
aws_iam_role_policy_attachment.lambda_logs: Creating...
aws_lambda_function.login: Creating...
aws_iam_role_policy_attachment.lambda_logs: Creation complete after 1s [id=infoline-login-exec-role-20260702115524657000000001]
aws_apigatewayv2_stage.default: Creation complete after 2s [id=$default]
aws_lambda_function.login: Still creating... [00m08s elapsed]
aws_lambda_function.login: Creation complete after 17s [id=infoline-login]
aws_lambda_permission.apigw: Creating...
aws_apigatewayv2_integration.login: Creating...
aws_lambda_permission.apigw: Creation complete after 1s [id=AllowAPIGatewayInvoke]
aws_apigatewayv2_integration.login: Creation complete after 1s [id=chihn7h]
aws_apigatewayv2_route.login: Creating...
aws_apigatewayv2_route.login: Creation complete after 1s [id=dxtkm06]

Apply complete! Resources: 8 added, 0 changed, 0 destroyed.

Outputs:

api_endpoint = "https://<API_ID>.execute-api.eu-west-3.amazonaws.com"
function_arn = "arn:aws:lambda:eu-west-3:<ACCOUNT_ID>:function:infoline-login"
function_name = "infoline-login"
invoke_url = "https://<API_ID>.execute-api.eu-west-3.amazonaws.com//login"
julien@Julien:~/infoline-devops/terraform/lambda-login$ terraform output invoke_url
"https://<API_ID>.execute-api.eu-west-3.amazonaws.com//login"
julien@Julien:~/infoline-devops/terraform/lambda-login$ terraform output function_name
"infoline-login"
julien@Julien:~/infoline-devops/terraform/lambda-login$ curl -s "$(terraform output -raw invoke_url)"
{"message":"Hello from the InfoLine login service (serverless)","service":"login","method":"GET","path":"/login","timestamp":"2026-0
julien@Julien:~/infoline-devops/terraform/lambda-login$ aws lambda invoke --function-name "$(terraform output -raw function_name)" \ 
  --payload '{}' --cli-binary-format raw-in-base64-out response.json && cat response.json
{
    "StatusCode": 200,
    "ExecutedVersion": "$LATEST"
}
{"headers":{"Content-Type":"application/json"},"body":"{\"message\":\"Hello from the InfoLine login service (serverless)\",\"service\":\"login\",\"method\":\"N/A\",\"path\":\"N/A\",\"timestamp\":\"2026-07-02T11:56:50.897739980Z\"}","statusCode":200}julien@Julien:~/infoline-devops/terraform/lambda-login$ terraform state list
data.aws_iam_policy_document.assume_role
aws_apigatewayv2_api.login
aws_apigatewayv2_integration.login
aws_apigatewayv2_route.login
aws_apigatewayv2_stage.default
aws_iam_role.lambda_exec
aws_iam_role_policy_attachment.lambda_logs
aws_lambda_function.login
aws_lambda_permission.apigw
julien@Julien:~/infoline-devops/terraform/lambda-login$ aws lambda get-function --function-name infoline-login --no-cli-pager
{
    "Configuration": {
        "FunctionName": "infoline-login",
        "FunctionArn": "arn:aws:lambda:eu-west-3:<ACCOUNT_ID>:function:infoline-login",
        "Runtime": "java21",
        "Role": "arn:aws:iam::<ACCOUNT_ID>:role/infoline-login-exec-role",
        "Handler": "com.infoline.login.LoginHandler::handleRequest",
        "CodeSize": 3182,
        "Description": "",
        "Timeout": 10,
        "MemorySize": 256,
        "LastModified": "2026-07-02T11:55:32.787+0000",
        "CodeSha256": "RJj+eW4orTxvROpTRhhaj192lv+IUIb8ch9gnE1agQE=",
        "Version": "$LATEST",
        "TracingConfig": {
            "Mode": "PassThrough"
        },
        "RevisionId": "503e74ae-2ba4-4c69-b24c-c1864eda9525",
        "State": "Active",
        "LastUpdateStatus": "Successful",
        "PackageType": "Zip",
        "Architectures": [
            "x86_64"
        ],
        "EphemeralStorage": {
            "Size": 512
        },
        "SnapStart": {
            "ApplyOn": "None",
            "OptimizationStatus": "Off"
        },
        "RuntimeVersionConfig": {
            "RuntimeVersionArn": "arn:aws:lambda:eu-west-3::runtime:9545bebf9b674e58101bf1ee53f999b7dd7fed2f7a93b34f48936163a2cdf4cd"
        },
        "LoggingConfig": {
            "LogFormat": "Text",
            "LogGroup": "/aws/lambda/infoline-login"
        }
    }
}
julien@Julien:~/infoline-devops/terraform/lambda-login$ aws iam get-role --role-name infoline-login-exec-role --no-cli-pager
{
    "Role": {
        "Path": "/",
        "RoleName": "infoline-login-exec-role",
        "RoleId": "AROATTN7HYBYMPK3FGJZP",
        "Arn": "arn:aws:iam::<ACCOUNT_ID>:role/infoline-login-exec-role",
        "CreateDate": "2026-07-02T11:55:21+00:00",
        "AssumeRolePolicyDocument": {
            "Version": "2012-10-17",
            "Statement": [
                {
                    "Effect": "Allow",
                    "Principal": {
                        "Service": "lambda.amazonaws.com"
                    },
                    "Action": "sts:AssumeRole"
                }
            ]
        },
        "MaxSessionDuration": 3600,
        "Tags": [
            {
                "Key": "Project",
                "Value": "InfoLine"
            },
            {
                "Key": "Composant",
                "Value": "login-serverless"
            },
            {
                "Key": "Bloc",
                "Value": "A1"
            }
        ],
        "RoleLastUsed": {
            "LastUsedDate": "2026-07-02T12:38:13+00:00",
            "Region": "eu-west-3"
        }
    }
}
julien@Julien:~/infoline-devops/terraform/lambda-login$ aws iam list-attached-role-policies --role-name infoline-login-exec-role --no-cli-pager
{
    "AttachedPolicies": [
        {
            "PolicyName": "AWSLambdaBasicExecutionRole",
            "PolicyArn": "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
        }
    ]
}
julien@Julien:~/infoline-devops/terraform/lambda-login$ aws apigatewayv2 get-apis --query "Items[?Name=='infoline-login-api']" --no-cli-pager
[
    {
        "ApiEndpoint": "https://<API_ID>.execute-api.eu-west-3.amazonaws.com",
        "ApiId": "<API_ID>",
        "ApiKeySelectionExpression": "$request.header.x-api-key",
        "CreatedDate": "2026-07-02T11:55:21+00:00",
        "DisableExecuteApiEndpoint": false,
        "IpAddressType": "ipv4",
        "Name": "infoline-login-api",
        "ProtocolType": "HTTP",
        "RouteSelectionExpression": "$request.method $request.path",
        "Tags": {
            "Bloc": "A1",
            "Project": "InfoLine",
            "Composant": "login-serverless"
        }
    }
]
julien@Julien:~/infoline-devops/terraform/lambda-login$
