
resource "aws_iam_role" "lambda_get_courses_exec_role" {
  name = "${var.project_name}-lambda_get_courses_exec_role"
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


data "archive_file" "lambda_get_courses" {
  type        = "zip"
  source_dir  = "${path.module}/../get-courses"
  output_path = "${path.module}/bin/get-courses.zip"
}


resource "aws_cloudwatch_log_group" "get_courses_logs" {
  name              = "/aws/lambda/${var.project_name}-get_courses"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}


resource "aws_lambda_function" "get_courses" {
  function_name    = "${var.project_name}-get_courses"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_get_courses_exec_role.arn
  filename         = data.archive_file.lambda_get_courses.output_path
  source_code_hash = data.archive_file.lambda_get_courses.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      COURSES_TABLE         = aws_dynamodb_table.courses_table.name
      PURCHASES_TABLE       = aws_dynamodb_table.purchases_table.name
      COURSE_PROGRESS_TABLE = aws_dynamodb_table.course_progress_table.name
      LOG_LEVEL             = var.log_level
    }
  }
  
  tags       = var.common_tags
  depends_on = [aws_cloudwatch_log_group.get_courses_logs]
}

# Política para CloudWatch Logs (específica)
resource "aws_iam_policy" "get_courses_logs_policy" {
  name        = "${var.project_name}-get_courses_logs_policy"
  description = "Permisos para CloudWatch Logs de Get Courses"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-get_courses:*"
      ]
    }]
  })
}

# Adjuntar políticas al rol
resource "aws_iam_role_policy_attachment" "get_courses_logs_attach" {
  role       = aws_iam_role.lambda_get_courses_exec_role.name
  policy_arn = aws_iam_policy.get_courses_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_courses_dynamodb_attach" {
  role       = aws_iam_role.lambda_get_courses_exec_role.name
  policy_arn = aws_iam_policy.courses_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "get_courses_kms_attach" {
  role       = aws_iam_role.lambda_get_courses_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

# Política básica de ejecución Lambda
resource "aws_iam_role_policy_attachment" "get_courses_basic_execution" {
  role       = aws_iam_role.lambda_get_courses_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}