# Empaquetado del código fuente de la Lambda
data "archive_file" "lambda_certificates" {
  type        = "zip"
  source_dir  = "${path.module}/../certificates"
  output_path = "${path.module}/bin/certificates.zip"
}

# CloudWatch Log Group para la Lambda
resource "aws_cloudwatch_log_group" "certificates_logs" {
  name              = "/aws/lambda/${var.project_name}-certificates"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}


# Política IAM para logs
resource "aws_iam_policy" "certificates_logs_policy" {
  name        = "${var.project_name}-certificates-logs-policy"
  description = "Permite a Lambda escribir logs en CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = [
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-certificates:*"
      ]
    }]
  })
}

# Función Lambda principal
resource "aws_lambda_function" "certificates" {
  function_name    = "${var.project_name}-certificates"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_certificates_exec_role.arn
  filename         = data.archive_file.lambda_certificates.output_path
  source_code_hash = data.archive_file.lambda_certificates.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size

  environment {
    variables = {
      CERTIFICATES_TABLE = "${var.project_name}-certificates"
      LOG_LEVEL          = var.log_level
    }
  }

  depends_on = [aws_cloudwatch_log_group.certificates_logs]
  tags       = var.common_tags
}

# Política para acceso a SQS 
resource "aws_iam_policy" "certificates_sqs_policy" {
  name        = "${var.project_name}-certificates-sqs-policy"
  description = "Permite acceso a SQS para certificados"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:ChangeMessageVisibility",
          "sqs:GetQueueAttributes",
          "sqs:SendMessage" 
        ],
        
        Resource = [
          aws_sqs_queue.certificates_queue.arn,
          var.enable_sqs_dlq ? aws_sqs_queue.certificates_dlq[0].arn : null # Incluye DLQ si está habilitada
        ]
      }
    ]
  })
}

# Adjuntar política SQS corregida al rol de la Lambda de certificados
resource "aws_iam_role_policy_attachment" "certificates_sqs_attach" {
  role       = aws_iam_role.lambda_certificates_exec_role.name
  policy_arn = aws_iam_policy.certificates_sqs_policy.arn
}
# Attach de políticas a rol
resource "aws_iam_role_policy_attachment" "certificates_logs_attach" {
  role       = aws_iam_role.lambda_certificates_exec_role.name
  policy_arn = aws_iam_policy.certificates_logs_policy.arn
}

