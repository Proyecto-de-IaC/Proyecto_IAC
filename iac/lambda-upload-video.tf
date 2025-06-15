# Rol IAM para Lambda Upload Video
resource "aws_iam_role" "lambda_upload_video_exec_role" {
  name = "${var.project_name}-lambda_upload_video_exec_role"
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
data "archive_file" "lambda_upload_video" {
  type        = "zip"
  source_dir  = "${path.module}/../upload-video"
  output_path = "${path.module}/bin/upload-video.zip"
}

# Grupo de logs con retención configurable
resource "aws_cloudwatch_log_group" "upload_video_logs" {
  name              = "/aws/lambda/${var.project_name}-upload_video"
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = var.common_tags
}

# Función Lambda Upload Video
resource "aws_lambda_function" "upload_video" {
  function_name    = "${var.project_name}-upload_video"
  handler          = "index.handler"
  runtime          = var.lambda_runtime
  role             = aws_iam_role.lambda_upload_video_exec_role.arn
  filename         = data.archive_file.lambda_upload_video.output_path
  source_code_hash = data.archive_file.lambda_upload_video.output_base64sha256
  timeout          = var.upload_video_timeout
  memory_size      = var.lambda_memory_size
  
  environment {
    variables = {
      VIDEOS_BUCKET   = aws_s3_bucket.videos_bucket.bucket
      COURSES_TABLE   = aws_dynamodb_table.courses_table.name
      LOG_LEVEL       = var.log_level
      MAX_FILE_SIZE   = tostring(var.max_file_size)
    }
  }
  
  tags       = var.common_tags
  depends_on = [aws_cloudwatch_log_group.upload_video_logs]
}

# Política específica para operaciones de video (mejorada)
resource "aws_iam_policy" "upload_video_policy" {
  name        = "${var.project_name}-upload_video_policy"
  description = "Permisos específicos para upload de videos"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ],
        Resource = [
          aws_s3_bucket.videos_bucket.arn,
          "${aws_s3_bucket.videos_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        Resource = [aws_kms_key.s3_videos_key.arn]
      }
    ]
  })
}

# Política para CloudWatch Logs (específica)
resource "aws_iam_policy" "upload_video_logs_policy" {
  name        = "${var.project_name}-upload_video_logs_policy"
  description = "Permisos para CloudWatch Logs de Upload Video"
  
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
        "arn:aws:logs:${var.aws_region}:*:log-group:/aws/lambda/${var.project_name}-upload_video:*"
      ]
    }]
  })
}

# Permiso para que S3 invoque la función Lambda
resource "aws_lambda_permission" "allow_s3_videos" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.upload_video.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.videos_bucket.arn
}

# Adjuntar políticas al rol
resource "aws_iam_role_policy_attachment" "upload_video_logs_attach" {
  role       = aws_iam_role.lambda_upload_video_exec_role.name
  policy_arn = aws_iam_policy.upload_video_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "upload_video_s3_attach" {
  role       = aws_iam_role.lambda_upload_video_exec_role.name
  policy_arn = aws_iam_policy.upload_video_policy.arn
}

resource "aws_iam_role_policy_attachment" "upload_video_dynamodb_attach" {
  role       = aws_iam_role.lambda_upload_video_exec_role.name
  policy_arn = aws_iam_policy.courses_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "upload_video_kms_attach" {
  role       = aws_iam_role.lambda_upload_video_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

# Política básica de ejecución Lambda
resource "aws_iam_role_policy_attachment" "upload_video_basic_execution" {
  role       = aws_iam_role.lambda_upload_video_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}