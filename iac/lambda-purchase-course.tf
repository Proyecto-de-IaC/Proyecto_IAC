data "archive_file" "lambda_purchase_course" {
  type        = "zip"
  source_dir  = "${path.module}/../purchase-course"
  output_path = "${path.module}/bin/purchase-course.zip"
}

resource "aws_iam_role" "lambda_purchase_course_exec_role" {
  name = "${var.project_name}-lambda_purchase_course_exec_role"
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

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "purchase_course_logs" {
  name              = "/aws/lambda/${var.project_name}-purchase-course"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

resource "aws_lambda_function" "purchase_course" {
  function_name    = "${var.project_name}-purchase-course"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_purchase_course_exec_role.arn
  filename         = data.archive_file.lambda_purchase_course.output_path
  source_code_hash = data.archive_file.lambda_purchase_course.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      PURCHASES_TABLE   = aws_dynamodb_table.purchases_table.name
      COURSES_TABLE     = aws_dynamodb_table.courses_table.name
      STRIPE_SECRET_KEY = var.stripe_secret_key
      EMAIL_QUEUE_URL   = aws_sqs_queue.email_queue.url
      LOG_LEVEL         = var.log_level
    }
  }
  
  tags       = var.common_tags
  depends_on = [aws_cloudwatch_log_group.purchase_course_logs]
}



# Política de logs específica
resource "aws_iam_policy" "purchase_course_logs_policy" {
  name        = "${var.project_name}-purchase_course_logs_policy"
  description = "Permisos para CloudWatch Logs de Purchase Course"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-purchase-course:*"
      ]
    }]
  })
}

# Política SQS mejorada
resource "aws_iam_policy" "purchase_course_sqs_policy" {
  name        = "${var.project_name}-PurchaseCourseSQSPolicy"
  description = "Permisos para enviar mensajes a SQS"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["sqs:SendMessage"],
      Resource = [aws_sqs_queue.email_queue.arn]
    }]
  })
}

# Adjuntar políticas al rol
resource "aws_iam_role_policy_attachment" "purchase_course_logs" {
  role       = aws_iam_role.lambda_purchase_course_exec_role.name
  policy_arn = aws_iam_policy.purchase_course_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "purchase_course_dynamodb" {
  role       = aws_iam_role.lambda_purchase_course_exec_role.name
  policy_arn = aws_iam_policy.courses_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "purchase_course_kms" {
  role       = aws_iam_role.lambda_purchase_course_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "purchase_course_basic_execution" {
  role       = aws_iam_role.lambda_purchase_course_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
resource "aws_iam_role_policy_attachment" "purchase_course_sqs" {
  role       = aws_iam_role.lambda_purchase_course_exec_role.name
  policy_arn = aws_iam_policy.email_sqs_policy.arn
}