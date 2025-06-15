# Data source para obtener información de la cuenta actual
data "aws_caller_identity" "current" {}

# Clave KMS para cifrado de DynamoDB
resource "aws_kms_key" "dynamodb_key" {
  description             = "Clave KMS para DynamoDB"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = var.enable_kms_key_rotation
  policy                  = data.aws_iam_policy_document.kms_policy.json

  tags = var.common_tags
}

resource "aws_kms_alias" "dynamodb_key_alias" {
  name          = "alias/dynamodb-${var.project_name}"
  target_key_id = aws_kms_key.dynamodb_key.key_id
}

# Política para la clave KMS
data "aws_iam_policy_document" "kms_policy" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
      "kms:DescribeKey"
    ]
    resources = [aws_kms_key.dynamodb_key.arn]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.lambda_certificates_exec_role.arn,
        aws_iam_role.lambda_registrations_exec_role.arn
      ]
    }
  }
}

# ============================================================================
# TABLAS DYNAMODB
# ============================================================================

# Tabla para Cursos
resource "aws_dynamodb_table" "courses_table" {
  name                        = "Courses"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "courseId"
  deletion_protection_enabled = var.dynamodb_deletion_protection
  
  attribute {
    name = "courseId"
    type = "S"
  }

  attribute {
    name = "instructorId"
    type = "S"
  }

  attribute {
    name = "category"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "creationDate"
    type = "N"
  }

  global_secondary_index {
    name            = "InstructorIndex"
    hash_key        = "instructorId"
    range_key       = "creationDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "CategoryIndex"
    hash_key        = "category"
    range_key       = "creationDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "creationDate"
    projection_type = "INCLUDE"
    non_key_attributes = ["courseId", "title", "price", "instructorId"]
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = var.common_tags
}

# Tabla para Compras/Transacciones
resource "aws_dynamodb_table" "purchases_table" {
  name                        = "Purchases"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "purchaseId"
  deletion_protection_enabled = var.dynamodb_deletion_protection
  
  attribute {
    name = "purchaseId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "courseId"
    type = "S"
  }

  attribute {
    name = "purchaseDate"
    type = "N"
  }

  attribute {
    name = "status"
    type = "S"
  }

  global_secondary_index {
    name            = "UserIndex"
    hash_key        = "userId"
    range_key       = "purchaseDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "CourseIndex"
    hash_key        = "courseId"
    range_key       = "purchaseDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "purchaseDate"
    projection_type = "INCLUDE"
    non_key_attributes = ["purchaseId", "userId", "courseId", "amount"]
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = var.common_tags
}

# Tabla para seguimiento de progreso de cursos
resource "aws_dynamodb_table" "course_progress_table" {
  name                        = "CourseProgress"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "userId"
  range_key                   = "courseId"
  deletion_protection_enabled = var.dynamodb_deletion_protection
  
  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "courseId"
    type = "S"
  }

  attribute {
    name = "lastAccessed"
    type = "N"
  }

  attribute {
    name = "progressPercentage"
    type = "N"
  }

  global_secondary_index {
    name            = "CourseProgressIndex"
    hash_key        = "courseId"
    range_key       = "progressPercentage"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "LastAccessedIndex"
    hash_key        = "userId"
    range_key       = "lastAccessed"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = var.common_tags
}

# Tabla para Certificados
resource "aws_dynamodb_table" "certificates_table" {
  name                        = "Certificates"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "certificateId"
  deletion_protection_enabled = var.dynamodb_deletion_protection
  
  attribute {
    name = "certificateId"
    type = "S"
  }

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "status"
    type = "S"
  }

  attribute {
    name = "expirationDate"
    type = "N"
  }

  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "userId"
    range_key       = "expirationDate"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "StatusIndex"
    hash_key        = "status"
    range_key       = "expirationDate"
    projection_type = "INCLUDE"
    non_key_attributes = ["certificateId", "userId"]
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  ttl {
    attribute_name = "expirationDate"
    enabled        = true
  }

  tags = var.common_tags
}

# Tabla para Registros de Usuarios
resource "aws_dynamodb_table" "registrations_table" {
  name                        = "Registrations"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "userId"
  range_key                   = "email"
  deletion_protection_enabled = var.dynamodb_deletion_protection

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "accountType"
    type = "S"
  }

  global_secondary_index {
    name            = "EmailIndex"
    hash_key        = "email"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "AccountTypeIndex"
    hash_key        = "accountType"
    range_key       = "email"
    projection_type = "KEYS_ONLY"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = var.common_tags
}
# 
resource "aws_dynamodb_table" "course_enrollments_table" {
  name                        = "${var.project_name}-course-enrollments"
  billing_mode                = var.dynamodb_billing_mode
  hash_key                    = "userId"
  range_key                   = "courseId"
  deletion_protection_enabled = var.dynamodb_deletion_protection

  attribute {
    name = "userId"
    type = "S"
  }

  attribute {
    name = "courseId"
    type = "S"
  }

  global_secondary_index {
    name            = "CourseIndex"
    hash_key        = "courseId"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb_key.arn
  }

  point_in_time_recovery {
    enabled = var.enable_dynamodb_point_in_time_recovery
  }

  tags = var.common_tags
}
# ============================================================================
# ROLES Y POLÍTICAS IAM
# ============================================================================

# Roles de ejecución para Lambda
resource "aws_iam_role" "lambda_certificates_exec_role" {
  name = "${var.project_name}-certificates-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role" "lambda_registrations_exec_role" {
  name = "${var.project_name}-registrations-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })

  tags = var.common_tags
}

# Políticas DynamoDB
resource "aws_iam_policy" "courses_dynamodb_policy" {
  name        = "${var.project_name}-CoursesDynamoDBPolicy"
  description = "Acceso a las tablas de cursos, compras y progreso"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "CoursesTableAccess",
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      Resource = [
        aws_dynamodb_table.courses_table.arn,
        "${aws_dynamodb_table.courses_table.arn}/index/*",
        aws_dynamodb_table.purchases_table.arn,
        "${aws_dynamodb_table.purchases_table.arn}/index/*",
        aws_dynamodb_table.course_progress_table.arn,
        "${aws_dynamodb_table.course_progress_table.arn}/index/*"
      ]
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "certificates_dynamodb_policy" {
  name        = "${var.project_name}-CertificatesDynamoDBPolicy"
  description = "Acceso a la tabla de Certificados"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "FullDynamoDBAccess",
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan",
        "dynamodb:BatchGetItem",
        "dynamodb:BatchWriteItem"
      ],
      Resource = [
        aws_dynamodb_table.certificates_table.arn,
        "${aws_dynamodb_table.certificates_table.arn}/index/*"
      ]
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "registrations_dynamodb_policy" {
  name        = "${var.project_name}-RegistrationsDynamoDBPolicy"
  description = "Acceso a la tabla de Registros"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid    = "FullDynamoDBAccess",
      Effect = "Allow",
      Action = [
        "dynamodb:GetItem",
        "dynamodb:PutItem",
        "dynamodb:UpdateItem",
        "dynamodb:DeleteItem",
        "dynamodb:Query",
        "dynamodb:Scan"
      ],
      Resource = [
        aws_dynamodb_table.registrations_table.arn,
        "${aws_dynamodb_table.registrations_table.arn}/index/*"
      ]
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "registrations_courses_dynamodb_policy" {
  name        = "${var.project_name}-registrations-courses-dynamodb-policy"
  description = "Permisos para registrar inscripciones en la tabla course_enrollments"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:UpdateItem",
        "dynamodb:Query"
      ],
      Resource = [
        aws_dynamodb_table.course_enrollments_table.arn,
        "${aws_dynamodb_table.course_enrollments_table.arn}/index/*"
      ]

    }]
  })
}


# Políticas adicionales
resource "aws_iam_policy" "lambda_kms_policy" {
  name        = "${var.project_name}-LambdaKMSPolicy"
  description = "Permisos para KMS"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["kms:Decrypt", "kms:GenerateDataKey"],
      Resource = [aws_kms_key.dynamodb_key.arn]
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_policy" "lambda_logs_policy" {
  name        = "${var.project_name}-LambdaLogsPolicy"
  description = "Permisos para CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      Resource = "*"
    }]
  })

  tags = var.common_tags
}

# Adjuntar políticas a roles
resource "aws_iam_role_policy_attachment" "certificates_dynamodb" {
  role       = aws_iam_role.lambda_certificates_exec_role.name
  policy_arn = aws_iam_policy.certificates_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "registrations_dynamodb" {
  role       = aws_iam_role.lambda_registrations_exec_role.name
  policy_arn = aws_iam_policy.registrations_dynamodb_policy.arn
}

resource "aws_iam_role_policy_attachment" "certificates_kms" {
  role       = aws_iam_role.lambda_certificates_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "registrations_kms" {
  role       = aws_iam_role.lambda_registrations_exec_role.name
  policy_arn = aws_iam_policy.lambda_kms_policy.arn
}

resource "aws_iam_role_policy_attachment" "certificates_logs" {
  role       = aws_iam_role.lambda_certificates_exec_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

resource "aws_iam_role_policy_attachment" "registrations_logs" {
  role       = aws_iam_role.lambda_registrations_exec_role.name
  policy_arn = aws_iam_policy.lambda_logs_policy.arn
}

# ============================================================================
# OUTPUTS
# ============================================================================

output "courses_table_name" {
  description = "Nombre de la tabla de cursos"
  value       = aws_dynamodb_table.courses_table.name
}

output "courses_table_arn" {
  description = "ARN de la tabla de cursos"
  value       = aws_dynamodb_table.courses_table.arn
}

output "purchases_table_name" {
  description = "Nombre de la tabla de compras"
  value       = aws_dynamodb_table.purchases_table.name
}

output "purchases_table_arn" {
  description = "ARN de la tabla de compras"
  value       = aws_dynamodb_table.purchases_table.arn
}

output "course_progress_table_name" {
  description = "Nombre de la tabla de progreso de cursos"
  value       = aws_dynamodb_table.course_progress_table.name
}

output "course_progress_table_arn" {
  description = "ARN de la tabla de progreso de cursos"
  value       = aws_dynamodb_table.course_progress_table.arn
}

output "certificates_table_name" {
  description = "Nombre de la tabla de certificados"
  value       = aws_dynamodb_table.certificates_table.name
}

output "certificates_table_arn" {
  description = "ARN de la tabla de certificados"
  value       = aws_dynamodb_table.certificates_table.arn
}

output "registrations_table_name" {
  description = "Nombre de la tabla de registros"
  value       = aws_dynamodb_table.registrations_table.name
}

output "registrations_table_arn" {
  description = "ARN de la tabla de registros"
  value       = aws_dynamodb_table.registrations_table.arn
}

output "dynamodb_kms_key_arn" {
  description = "ARN de la clave KMS para DynamoDB"
  value       = aws_kms_key.dynamodb_key.arn
}

output "dynamodb_kms_key_id" {
  description = "ID de la clave KMS para DynamoDB"
  value       = aws_kms_key.dynamodb_key.key_id
}

output "lambda_certificates_role_arn" {
  description = "ARN del rol de ejecución para Lambda de certificados"
  value       = aws_iam_role.lambda_certificates_exec_role.arn
}

output "lambda_registrations_role_arn" {
  description = "ARN del rol de ejecución para Lambda de registros"
  value       = aws_iam_role.lambda_registrations_exec_role.arn
}