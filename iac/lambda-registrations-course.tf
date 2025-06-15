# Empaquetado del código Lambda de inscripción a cursos
data "archive_file" "lambda_registrations_courses" {
  type        = "zip"
  source_dir  = "${path.module}/../registrations-courses"
  output_path = "${path.module}/bin/registrations-courses.zip"
}

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "registrations_courses_logs" {
  name              = "/aws/lambda/${var.project_name}-registrations-courses"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

# Política de logs específica
resource "aws_iam_policy" "registrations_courses_logs_policy" {
  name        = "${var.project_name}-registrations-courses_logs_policy"
  description = "Permisos para CloudWatch Logs de Registrations Courses"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-registrations-courses:*"
      ]
    }]
  })
}

resource "aws_iam_role" "lambda_registrations_courses_exec_role" {
  name = "${var.project_name}-registrations-courses-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}
resource "aws_lambda_function" "registrations_courses_lambda" {
  function_name = "${var.project_name}-registrations-courses"
  handler       = "index.handler" 
  runtime       = var.lambda_runtime
  role          = aws_iam_role.lambda_registrations_courses_exec_role.arn
  filename      = data.archive_file.lambda_registrations_courses.output_path
  source_code_hash = data.archive_file.lambda_registrations_courses.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  environment {
    variables = {
      COURSE_ENROLLMENTS_TABLE = aws_dynamodb_table.course_enrollments_table.name
      LOG_LEVEL           = var.log_level 
    }
  }

  tags = var.common_tags
  depends_on = [aws_cloudwatch_log_group.registrations_logs]
}


# Adjuntar política de logs
resource "aws_iam_role_policy_attachment" "registrations_courses_logs_attach" {
  role       = aws_iam_role.lambda_registrations_courses_exec_role.name
  policy_arn = aws_iam_policy.registrations_courses_logs_policy.arn
}
resource "aws_iam_role_policy_attachment" "registrations_courses_dynamodb_attach" {
  role       = aws_iam_role.lambda_registrations_courses_exec_role.name
  policy_arn = aws_iam_policy.registrations_courses_dynamodb_policy.arn
}

# Política básica de ejecución Lambda
resource "aws_iam_role_policy_attachment" "registrations_courses_basic_execution" {
  role       = aws_iam_role.lambda_registrations_courses_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}
