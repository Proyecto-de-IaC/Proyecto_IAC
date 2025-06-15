# Empaquetado del código Lambda
data "archive_file" "lambda_registrations" {
  type        = "zip"
  source_dir  = "${path.module}/../registrations"
  output_path = "${path.module}/bin/registrations.zip"
}

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "registrations_logs" {
  name              = "/aws/lambda/${var.project_name}-registrations"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

resource "aws_iam_policy" "registrations_logs_policy" {
  name        = "${var.project_name}-registrations_logs_policy"
  description = "Permisos para CloudWatch Logs de Registrations"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Effect   = "Allow",
      Resource = [
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-registrations:*"
      ]
    }]
  })
}

resource "aws_lambda_function" "registrations" {
  function_name    = "${var.project_name}-registrations"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_registrations_exec_role.arn
  filename         = data.archive_file.lambda_registrations.output_path
  source_code_hash = data.archive_file.lambda_registrations.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      REGISTRATIONS_TABLE = aws_dynamodb_table.registrations_table.name
      LOG_LEVEL           = var.log_level  # Variable de nivel de logs
    }
  }
  
  tags       = var.common_tags
  depends_on = [aws_cloudwatch_log_group.registrations_logs]
}

resource "aws_iam_role_policy_attachment" "registrations_logs_attach" {
  role       = aws_iam_role.lambda_registrations_exec_role.name
  policy_arn = aws_iam_policy.registrations_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "registrations_basic_execution" {
  role       = aws_iam_role.lambda_registrations_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}