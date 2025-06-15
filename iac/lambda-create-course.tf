# Rol IAM para Lambda Create Course
resource "aws_iam_role" "lambda_create_course_exec_role" {
  name = "${var.project_name}-lambda_create_course_exec_role"
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

# Empaquetado del código Lambda
data "archive_file" "lambda_create_course" {
  type        = "zip"
  source_dir  = "${path.module}/../create-course"
  output_path = "${path.module}/bin/create-course.zip"
}

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "create_course_logs" {
  name              = "/aws/lambda/${var.project_name}-create_course"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

# Función Lambda Create Course
resource "aws_lambda_function" "create_course" {
  function_name    = "${var.project_name}-create_course"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_create_course_exec_role.arn
  filename         = data.archive_file.lambda_create_course.output_path
  source_code_hash = data.archive_file.lambda_create_course.output_base64sha256
  timeout          = var.lambda_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      COURSES_TABLE = aws_dynamodb_table.courses_table.name
      VIDEOS_BUCKET = aws_s3_bucket.videos_bucket.bucket
      LOG_LEVEL     = var.log_level
    }
  }
  
  tags     = var.common_tags
  depends_on = [aws_cloudwatch_log_group.create_course_logs]
}
resource "aws_iam_policy" "create_course_logs_policy" {
  name        = "${var.project_name}-create_course_logs_policy"
  description = "Permisos para CloudWatch Logs de Create Course"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-create_course:*"
      ]
    }]
  })
}

# Adjuntar políticas al rol
resource "aws_iam_role_policy_attachment" "create_course_logs_attach" {
  role       = aws_iam_role.lambda_create_course_exec_role.name
  policy_arn = aws_iam_policy.create_course_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "create_course_dynamodb_attach" {
  role       = aws_iam_role.lambda_create_course_exec_role.name
  policy_arn = aws_iam_policy.courses_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "create_course_s3_attach" {
  role       = aws_iam_role.lambda_create_course_exec_role.name
  policy_arn = aws_iam_policy.videos_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "create_course_kms_attach" {
  role       = aws_iam_role.lambda_create_course_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "create_course_basic_execution" {
  role       = aws_iam_role.lambda_create_course_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}