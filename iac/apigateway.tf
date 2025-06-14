resource "aws_api_gateway_rest_api" "certificates_api" {
  name        = "${var.project_name}-api"
  description = "API para gestión de certificados y registros - ${var.environment}"

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  })
}

resource "aws_api_gateway_resource" "certificates_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "certificados"
}

resource "aws_api_gateway_method" "certificates_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.certificates_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "certificates_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.certificates_resource.id
  http_method             = aws_api_gateway_method.certificates_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.certificates.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO: Usando la nueva variable
}

resource "aws_api_gateway_resource" "registrations_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "registros"
}

resource "aws_api_gateway_method" "registrations_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.registrations_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "registrations_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.registrations_resource.id
  http_method             = aws_api_gateway_method.registrations_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.registrations.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO
}

resource "aws_api_gateway_resource" "create_course_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "create-course"
}

resource "aws_api_gateway_method" "create_course_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.create_course_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "create_course_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.create_course_resource.id
  http_method             = aws_api_gateway_method.create_course_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.create_course.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO
}

resource "aws_api_gateway_resource" "get_courses_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "get-courses"
}

resource "aws_api_gateway_method" "get_courses_get" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.get_courses_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "get_courses_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.get_courses_resource.id
  http_method             = aws_api_gateway_method.get_courses_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_courses.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO
}

# New resources - Upload Video (con timeout específico)
resource "aws_api_gateway_resource" "upload_video_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "upload-video"
}

resource "aws_api_gateway_method" "upload_video_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.upload_video_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "upload_video_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.upload_video_resource.id
  http_method             = aws_api_gateway_method.upload_video_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.upload_video.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO: Usando la nueva variable, ya que 300s seguía siendo mucho
}


resource "aws_api_gateway_resource" "purchase_course_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "purchase-course"
}

resource "aws_api_gateway_method" "purchase_course_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.purchase_course_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "purchase_course_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.purchase_course_resource.id
  http_method             = aws_api_gateway_method.purchase_course_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.purchase_course.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO
}


resource "aws_api_gateway_resource" "track_progress_resource" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  parent_id   = aws_api_gateway_rest_api.certificates_api.root_resource_id
  path_part   = "track-progress"
}

resource "aws_api_gateway_method" "track_progress_post" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.track_progress_resource.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "track_progress_get" {
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = aws_api_gateway_resource.track_progress_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "track_progress_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.track_progress_resource.id
  http_method             = aws_api_gateway_method.track_progress_post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.track_progress.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CAMBIADO
}

resource "aws_api_gateway_integration" "track_progress_get_lambda" {
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  resource_id             = aws_api_gateway_resource.track_progress_resource.id
  http_method             = aws_api_gateway_method.track_progress_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.track_progress.invoke_arn
  timeout_milliseconds    = var.api_gateway_integration_timeout_ms # CORREGIDO: Faltaba * 1000 y ahora usa la nueva variable
}


locals {
  cors_resources = {
    "certificates"      = aws_api_gateway_resource.certificates_resource.id
    "registrations"     = aws_api_gateway_resource.registrations_resource.id
    "create_course"     = aws_api_gateway_resource.create_course_resource.id
    "get_courses"       = aws_api_gateway_resource.get_courses_resource.id
    "upload_video"      = aws_api_gateway_resource.upload_video_resource.id
    "purchase_course"   = aws_api_gateway_resource.purchase_course_resource.id
    "track_progress"    = aws_api_gateway_resource.track_progress_resource.id
  }
}

resource "aws_api_gateway_method" "cors_method" {
  for_each = local.cors_resources

  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  resource_id   = each.value
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "cors_integration" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  resource_id = each.value
  http_method = "OPTIONS"
  type        = "MOCK"

  request_templates = {
    "application/json" = jsonencode({
      statusCode = 200
    })
  }
}

resource "aws_api_gateway_method_response" "cors_method_response" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  resource_id = each.value
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "cors_integration_response" {
  for_each = local.cors_resources

  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  resource_id = each.value
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST,PUT,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
  
  depends_on = [
    aws_api_gateway_integration.cors_integration,
    aws_api_gateway_method_response.cors_method_response
  ]
}

resource "aws_lambda_permission" "apigw_certificates" {
  statement_id  = "AllowAPIGatewayInvokeCertificates"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.certificates.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_registrations" {
  statement_id  = "AllowAPIGatewayInvokeRegistrations"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.registrations.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_create_course" {
  statement_id  = "AllowAPIGatewayInvokeCreateCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.create_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_get_courses" {
  statement_id  = "AllowAPIGatewayInvokeGetCourses"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_courses.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_upload_video" {
  statement_id  = "AllowAPIGatewayInvokeUploadVideo"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_video.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_purchase_course" {
  statement_id  = "AllowAPIGatewayInvokePurchaseCourse"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.purchase_course.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "apigw_track_progress" {
  statement_id  = "AllowAPIGatewayInvokeTrackProgress"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.track_progress.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.certificates_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  
  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.certificates_resource.id,
      aws_api_gateway_method.certificates_post.id,
      aws_api_gateway_integration.certificates_lambda.id,
      aws_api_gateway_resource.registrations_resource.id,
      aws_api_gateway_method.registrations_post.id,
      aws_api_gateway_integration.registrations_lambda.id,
      aws_api_gateway_resource.create_course_resource.id,
      aws_api_gateway_method.create_course_post.id,
      aws_api_gateway_integration.create_course_lambda.id,
      aws_api_gateway_resource.get_courses_resource.id,
      aws_api_gateway_method.get_courses_get.id,
      aws_api_gateway_integration.get_courses_lambda.id,
      aws_api_gateway_resource.upload_video_resource.id,
      aws_api_gateway_method.upload_video_post.id,
      aws_api_gateway_integration.upload_video_lambda.id,
      aws_api_gateway_resource.purchase_course_resource.id,
      aws_api_gateway_method.purchase_course_post.id,
      aws_api_gateway_integration.purchase_course_lambda.id,
      aws_api_gateway_resource.track_progress_resource.id,
      aws_api_gateway_method.track_progress_post.id,
      aws_api_gateway_method.track_progress_get.id,
      aws_api_gateway_integration.track_progress_lambda.id,
      aws_api_gateway_integration.track_progress_get_lambda.id,
      aws_api_gateway_method.cors_method,
      aws_api_gateway_integration.cors_integration,
      aws_api_gateway_method_response.cors_method_response,
      aws_api_gateway_integration_response.cors_integration_response,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "prod" {
  stage_name    = var.api_gateway_stage_name
  rest_api_id   = aws_api_gateway_rest_api.certificates_api.id
  deployment_id = aws_api_gateway_deployment.deployment.id

  dynamic "access_log_settings" {
    for_each = var.enable_api_gateway_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.api_gateway[0].arn
      format = jsonencode({
        requestId      = "$context.requestId"
        ip             = "$context.identity.sourceIp"
        caller         = "$context.identity.caller"
        user           = "$context.identity.user"
        requestTime    = "$context.requestTime"
        httpMethod     = "$context.httpMethod"
        resourcePath   = "$context.resourcePath"
        status         = "$context.status"
        protocol       = "$context.protocol"
        responseLength = "$context.response.header.Content-Length" # CORREGIDO para mejor precisión
      })
    }
  }

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-api-${var.api_gateway_stage_name}"
    Environment = var.environment
  })
}

# Configuración de throttling a nivel de stage
resource "aws_api_gateway_method_settings" "throttling" {
  rest_api_id = aws_api_gateway_rest_api.certificates_api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name
  method_path = "*/*"

  settings {
    throttling_rate_limit  = var.api_throttle_rate_limit
    throttling_burst_limit = var.api_throttle_burst_limit
    logging_level          = var.enable_api_gateway_logging ? "INFO" : "OFF"
    data_trace_enabled     = var.enable_api_gateway_logging
    metrics_enabled        = true
  }
}

# CloudWatch Log Group para API Gateway (condicional)
resource "aws_cloudwatch_log_group" "api_gateway" {
  count             = var.enable_api_gateway_logging ? 1 : 0
  name              = "/aws/apigateway/${var.project_name}-api"
  retention_in_days = var.cloudwatch_log_retention_days

  tags = merge(var.common_tags, {
    Name        = "${var.project_name}-api-logs"
    Environment = var.environment
  })
}

# Output 
output "api_url" {
  description = "URL base de la API"
  value       = "https://${aws_api_gateway_rest_api.certificates_api.id}.execute-api.${var.aws_region}.amazonaws.com/${var.api_gateway_stage_name}"
}

output "api_stage" {
  value       = aws_api_gateway_stage.prod.stage_name
  description = "Nombre del stage de la API"
}

output "api_id" {
  value       = aws_api_gateway_rest_api.certificates_api.id
  description = "ID de la API Gateway"
}

resource "aws_iam_role" "api_gateway_cloudwatch_logs" {
  name = "${var.project_name}-apigateway-cloudwatch-logs-role" # Asegúrate de que este nombre sea único y descriptivo

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
        Sid = ""
      },
    ]
  })
}

resource "aws_iam_policy" "api_gateway_cloudwatch_logs_policy" {
  name        = "${var.project_name}-apigateway-cloudwatch-logs-policy"
  description = "Permite a API Gateway escribir logs en CloudWatch"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
          "logs:GetResourcePolicy",
          "logs:PutResourcePolicy"
        ],
        Effect   = "Allow",
        Resource = "*" 
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch_logs_attachment" {
  role       = aws_iam_role.api_gateway_cloudwatch_logs.name
  policy_arn = aws_iam_policy.api_gateway_cloudwatch_logs_policy.arn
}

output "api_gateway_cloudwatch_logs_role_arn" {
  value = aws_iam_role.api_gateway_cloudwatch_logs.arn
}