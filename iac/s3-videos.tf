
# Bucket para almacenar videos de cursos
resource "aws_s3_bucket" "videos_bucket" {
  bucket = "${var.s3_bucket_video_prefix}-videos-${random_id.videos_bucket_suffix.hex}"
  tags = var.common_tags
}
resource "random_id" "videos_bucket_suffix" {
  byte_length = 6
}

# Configuración de versionado para videos
resource "aws_s3_bucket_versioning" "videos_versioning" {
  bucket = aws_s3_bucket.videos_bucket.id
  versioning_configuration {
    status = var.enable_s3_versioning ? "Enabled" : "Disabled"
  }
}

# Bloquear acceso público
resource "aws_s3_bucket_public_access_block" "videos_block" {
  bucket = aws_s3_bucket.videos_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Encriptación del bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "videos_encryption" {
  bucket = aws_s3_bucket.videos_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_videos_key.arn
      sse_algorithm     = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

# Configuración de lifecycle para optimizar costos
resource "aws_s3_bucket_lifecycle_configuration" "videos_lifecycle" {
  bucket = aws_s3_bucket.videos_bucket.id
  
  rule {
    id     = "video_lifecycle"
    status = "Enabled"
    
    filter {
      prefix = ""  
    }
    
    
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    
 
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    
    # Eliminar versiones antiguas después de 365 días
    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

# CORS para permitir uploads desde el frontend
resource "aws_s3_bucket_cors_configuration" "videos_cors" {
  bucket = aws_s3_bucket.videos_bucket.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "POST", "PUT", "DELETE", "HEAD"]
    allowed_origins = ["*"] 
    expose_headers  = ["ETag"]
    max_age_seconds = 3000
  }
}

# Notificaciones S3 para procesar videos subidos
resource "aws_s3_bucket_notification" "videos_notification" {
  bucket = aws_s3_bucket.videos_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.upload_video.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
    filter_suffix       = ""
  }

  depends_on = [aws_lambda_permission.allow_s3_videos]
}

# Clave KMS para encriptar videos
resource "aws_kms_key" "s3_videos_key" {
  description             = "Clave KMS para encriptar videos de cursos"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        }
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_kms_alias" "s3_videos_key_alias" {
  name          = "alias/s3-videos-key"
  target_key_id = aws_kms_key.s3_videos_key.key_id
}

# Política IAM para acceso a videos S3
resource "aws_iam_policy" "videos_s3_policy" {
  name        = "VideosS3Policy"
  description = "Permisos para acceder al bucket de videos"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket",
          "s3:GetObjectVersion"
        ],
        Resource = [
          aws_s3_bucket.videos_bucket.arn,
          "${aws_s3_bucket.videos_bucket.arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ],
        Resource = [aws_kms_key.s3_videos_key.arn]
      }
    ]
  })
}

# Outputs
output "videos_bucket_name" {
  value = aws_s3_bucket.videos_bucket.bucket
}

output "videos_bucket_arn" {
  value = aws_s3_bucket.videos_bucket.arn
}

output "videos_bucket_domain" {
  value = aws_s3_bucket.videos_bucket.bucket_regional_domain_name
}

output "videos_kms_key_arn" {
  value = aws_kms_key.s3_videos_key.arn
}