# Archivo ZIP de la función
data "archive_file" "lambda_track_progress" {
  type        = "zip"
  source_dir  = "${path.module}/../track-progress"
  output_path = "${path.module}/bin/track-progress.zip"
}

# Rol de ejecución
resource "aws_iam_role" "lambda_track_progress_exec_role" {
  name = "${var.project_name}-lambda_track_progress_exec_role"
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
resource "aws_cloudwatch_log_group" "track_progress_logs" {
  name              = "/aws/lambda/${var.project_name}-track-progress"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

# Función Lambda
resource "aws_lambda_function" "track_progress" {
  function_name    = "${var.project_name}-track-progress"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_track_progress_exec_role.arn
  filename         = data.archive_file.lambda_track_progress.output_path
  source_code_hash = data.archive_file.lambda_track_progress.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      PROGRESS_TABLE     = aws_dynamodb_table.course_progress_table.name
      COURSES_TABLE      = aws_dynamodb_table.courses_table.name
      CERTIFICATES_QUEUE = aws_sqs_queue.certificates_queue.url
      LOG_LEVEL          = var.log_level
    }
  }
  
  tags       = var.common_tags
  depends_on = [aws_cloudwatch_log_group.track_progress_logs]
}


# Política de logs específica
resource "aws_iam_policy" "track_progress_logs_policy" {
  name        = "${var.project_name}-track_progress_logs_policy"
  description = "Permisos para CloudWatch Logs de Track Progress"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-track-progress:*"
      ]
    }]
  })
}

# Adjuntar políticas al rol
resource "aws_iam_role_policy_attachment" "track_progress_logs" {
  role       = aws_iam_role.lambda_track_progress_exec_role.name
  policy_arn = aws_iam_policy.track_progress_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "track_progress_dynamodb" {
  role       = aws_iam_role.lambda_track_progress_exec_role.name
  policy_arn = aws_iam_policy.courses_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "track_progress_sqs" {
  role       = aws_iam_role.lambda_track_progress_exec_role.name
  policy_arn = aws_iam_policy.certificates_sqs_policy.arn
}

resource "aws_iam_role_policy_attachment" "track_progress_kms" {
  role       = aws_iam_role.lambda_track_progress_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

# Política básica de ejecución Lambda
resource "aws_iam_role_policy_attachment" "track_progress_basic_execution" {
  role       = aws_iam_role.lambda_track_progress_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}