# Rol de ejecución para Lambda
resource "aws_iam_role" "lambda_send_email_exec_role" {
  name = "${var.project_name}-lambda_send_email_exec_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Archivo ZIP del código Lambda
data "archive_file" "lambda_send_email" {
  type        = "zip"
  source_dir  = "${path.module}/../envio"
  output_path = "${path.module}/bin/envio.zip"
}

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "send_email_logs" {
  name              = "/aws/lambda/${var.project_name}-send_email"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

# Cola SQS para procesamiento de emails
resource "aws_sqs_queue" "email_queue" {
  name                      = "${var.project_name}-email-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600  # 4 días
  receive_wait_time_seconds = 10
  visibility_timeout_seconds = var.lambda_timeout * 6  # 6 veces el timeout del lambda

  # Configuración de Dead Letter Queue
  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.email_queue_dlq.arn
    maxReceiveCount     = 3
  })

  tags = var.common_tags
}

# Dead Letter Queue para mensajes fallidos
resource "aws_sqs_queue" "email_queue_dlq" {
  name                      = "${var.project_name}-email-queue-dlq"
  message_retention_seconds = 1209600  # 14 días

  tags = var.common_tags
}

# Función Lambda
resource "aws_lambda_function" "send_email" {
  function_name    = "${var.project_name}-send_email"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role            = aws_iam_role.lambda_send_email_exec_role.arn
  filename        = data.archive_file.lambda_send_email.output_path
  source_code_hash = data.archive_file.lambda_send_email.output_base64sha256
  timeout         = var.lambda_timeout
  memory_size     = var.lambda_memory_size
  
  environment {
    variables = {
      SES_EMAIL_IDENTITY = var.ses_email_identity
      LOG_LEVEL         = var.log_level
      SQS_QUEUE_URL     = aws_sqs_queue.email_queue.url
    }
  }
  
  depends_on = [aws_cloudwatch_log_group.send_email_logs]
}

# Política de logs específica para esta función
resource "aws_iam_policy" "send_email_logs_policy" {
  name        = "${var.project_name}-send_email_logs_policy"
  description = "Permisos para CloudWatch Logs de Send Email"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Effect = "Allow",
      Resource = [
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-send_email:*"
      ]
    }]
  })
}

# Política SES para envío de emails
resource "aws_iam_policy" "send_email_ses_policy" {
  name = "${var.project_name}-send_email_ses_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = ["ses:SendEmail", "ses:SendRawEmail"],
      Resource = "arn:aws:ses:${var.aws_region}:*:identity/${var.ses_email_identity}"
    }]
  })
}

# Política IAM para operaciones SQS
resource "aws_iam_policy" "sqs_send_message_policy" {
  name        = "${var.project_name}-sqs_send_message_policy"
  description = "Permisos para enviar mensajes a la cola SQS"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ],
        Resource = [
          aws_sqs_queue.email_queue.arn,
          aws_sqs_queue.email_queue_dlq.arn
        ]
      }
    ]
  })
}

# Attachments de políticas IAM
resource "aws_iam_role_policy_attachment" "send_email_logs_attach" {
  role       = aws_iam_role.lambda_send_email_exec_role.name
  policy_arn = aws_iam_policy.send_email_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "send_email_ses_attach" {
  role       = aws_iam_role.lambda_send_email_exec_role.name
  policy_arn = aws_iam_policy.send_email_ses_policy.arn
}

resource "aws_iam_role_policy_attachment" "send_email_basic_execution" {
  role       = aws_iam_role.lambda_send_email_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "send_email_sqs_attach" {
  role       = aws_iam_role.lambda_send_email_exec_role.name
  policy_arn = aws_iam_policy.email_sqs_policy.arn
}