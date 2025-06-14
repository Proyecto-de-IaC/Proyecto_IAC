# =============================================================================
# VARIABLES PRINCIPALES DEL PROYECTO
# =============================================================================

variable "project_name" {
  description = "aprendeya"
  type        = string
  default     = "courses-system"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "El nombre del proyecto solo puede contener letras minúsculas, números y guiones."
  }
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "El entorno debe ser: development, staging o production."
  }
}

variable "aws_region" {
  description = "Región de AWS donde se desplegará la infraestructura"
  type        = string
  default     = "us-east-2"
}

# =============================================================================
# VARIABLES DE SERVICIOS EXTERNOS
# =============================================================================

variable "stripe_secret_key" {
  description = "Clave secreta de Stripe para procesar pagos"
  type        = string
  sensitive   = true
  
  validation {
    condition     = can(regex("^sk_", var.stripe_secret_key))
    error_message = "La clave de Stripe debe comenzar con 'sk_'."
  }
}

variable "ses_email_identity" {
  description = "Dirección de email verificada en Amazon SES para envío de correos"
  type        = string
  default     = "juanvaleriano97@gmail.com"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.ses_email_identity))
    error_message = "Debe ser una dirección de email válida."
  }
}

# =============================================================================
# VARIABLES DE CONFIGURACIÓN DE LAMBDA
# =============================================================================

variable "lambda_runtime" {
  description = "Runtime de Node.js para las funciones Lambda"
  type        = string
  default     = "nodejs16.x"
  
  validation {
    condition     = contains(["nodejs16.x", "nodejs18.x", "nodejs20.x"], var.lambda_runtime)
    error_message = "Runtime debe ser nodejs16.x, nodejs18.x o nodejs20.x."
  }
}

variable "lambda_timeout" {
  description = "Timeout de la función Lambda en segundos (máximo 900 segundos = 15 minutos)"
  type        = number
  default     = 300 # Este es el timeout de la función Lambda en sí
  validation {
    condition     = var.lambda_timeout >= 1 && var.lambda_timeout <= 900
    error_message = "El timeout de Lambda debe estar entre 1 y 900 segundos."
  }
}

variable "lambda_memory_size" {
  description = "Memoria asignada a las funciones Lambda (en MB)"
  type        = number
  default     = 512
  
  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "La memoria debe estar entre 128 y 10240 MB."
  }
}

variable "upload_video_timeout" {
  description = "Timeout específico para la función de upload de videos (en segundos, para la función Lambda, no para API GW)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.upload_video_timeout >= 30 && var.upload_video_timeout <= 900
    error_message = "El timeout para upload de videos debe estar entre 30 y 900 segundos."
  }
}

variable "log_level" {
  description = "Nivel de logging para las funciones Lambda"
  type        = string
  default     = "INFO"
  
  validation {
    condition     = contains(["DEBUG", "INFO", "WARN", "ERROR"], var.log_level)
    error_message = "Log level debe ser: DEBUG, INFO, WARN o ERROR."
  }
}

# =============================================================================
# VARIABLES DE ALMACENAMIENTO
# =============================================================================

variable "max_file_size" {
  description = "Tamaño máximo de archivo para uploads (en bytes)"
  type        = number
  default     = 104857600  # 100MB
  
  validation {
    condition     = var.max_file_size > 0 && var.max_file_size <= 5368709120  # 5GB max
    error_message = "El tamaño máximo debe ser mayor a 0 y menor o igual a 5GB."
  }
}

variable "enable_s3_versioning" {
  description = "Habilitar versionado en buckets S3"
  type        = bool
  default     = true
}
variable "s3_bucket_video_prefix" {
  description = "course"
  type        = string
  default     = "courses-system"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.s3_bucket_video_prefix))
    error_message = "El prefijo solo puede contener letras minúsculas, números y guiones."
  }
}
variable "s3_bucket_prefix" {
  description = "certificates"
  type        = string
  default     = "courses-system"
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.s3_bucket_prefix))
    error_message = "El prefijo solo puede contener letras minúsculas, números y guiones."
  }
}

# =============================================================================
# VARIABLES DE BASE DE DATOS
# =============================================================================

variable "dynamodb_billing_mode" {
  description = "Modo de facturación para tablas DynamoDB"
  type        = string
  default     = "PAY_PER_REQUEST"
  
  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "Billing mode debe ser PAY_PER_REQUEST o PROVISIONED."
  }
}

variable "enable_dynamodb_point_in_time_recovery" {
  description = "Habilitar Point-in-Time Recovery para DynamoDB"
  type        = bool
  default     = true
}

variable "dynamodb_deletion_protection" {
  description = "Habilitar protección contra eliminación en tablas DynamoDB"
  type        = bool
  default     = true
}

# =============================================================================
# VARIABLES DE COLAS SQS
# =============================================================================

variable "sqs_visibility_timeout" {
  description = "Timeout de visibilidad para colas SQS (en segundos)"
  type        = number
  default     = 300
  
  validation {
    condition     = var.sqs_visibility_timeout >= 0 && var.sqs_visibility_timeout <= 43200
    error_message = "El visibility timeout debe estar entre 0 y 43200 segundos."
  }
}

variable "sqs_message_retention_seconds" {
  description = "Tiempo de retención de mensajes en SQS (en segundos)"
  type        = number
  default     = 1209600  # 14 días
  
  validation {
    condition     = var.sqs_message_retention_seconds >= 60 && var.sqs_message_retention_seconds <= 1209600
    error_message = "La retención debe estar entre 60 segundos y 14 días."
  }
}

variable "enable_sqs_dlq" {
  description = "Habilitar Dead Letter Queue para colas SQS"
  type        = bool
  default     = true
}

# =============================================================================
# VARIABLES DE API GATEWAY
# =============================================================================

variable "api_gateway_stage_name" {
  description = "RecursosAPI"
  type        = string
  default     = "v1"
}

variable "enable_api_gateway_logging" {
  description = "Habilitar logging en API Gateway"
  type        = bool
  default     = true
}

variable "api_throttle_rate_limit" {
  description = "Límite de rate para API Gateway (requests por segundo)"
  type        = number
  default     = 1000
  
  validation {
    condition     = var.api_throttle_rate_limit > 0
    error_message = "El rate limit debe ser mayor a 0."
  }
}

variable "api_throttle_burst_limit" {
  description = "Límite de burst para API Gateway"
  type        = number
  default     = 2000
  
  validation {
    condition     = var.api_throttle_burst_limit > 0
    error_message = "El burst limit debe ser mayor a 0."
  }
}

variable "api_gateway_integration_timeout_ms" {
  description = "Timeout para las integraciones de API Gateway en milisegundos (entre 50 y 29000 ms)."
  type        = number
  default     = 29000 # Máximo permitido
  validation {
    condition     = var.api_gateway_integration_timeout_ms >= 50 && var.api_gateway_integration_timeout_ms <= 29000
    error_message = "El timeout de la integración de API Gateway debe estar entre 50 ms y 29000 ms."
  }
}

# =============================================================================
# VARIABLES DE SEGURIDAD
# =============================================================================

variable "enable_kms_key_rotation" {
  description = "Habilitar rotación automática de claves KMS"
  type        = bool
  default     = true
}

variable "kms_key_deletion_window" {
  description = "Ventana de eliminación para claves KMS (en días)"
  type        = number
  default     = 7
  
  validation {
    condition     = var.kms_key_deletion_window >= 7 && var.kms_key_deletion_window <= 30
    error_message = "La ventana de eliminación debe estar entre 7 y 30 días."
  }
}

# =============================================================================
# VARIABLES DE MONITOREO
# =============================================================================

variable "cloudwatch_log_retention_days" {
  description = "Días de retención para logs de CloudWatch"
  type        = number
  default     = 14
  
  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653
    ], var.cloudwatch_log_retention_days)
    error_message = "Los días de retención deben ser un valor válido de CloudWatch."
  }
}

variable "enable_xray_tracing" {
  description = "Habilitar AWS X-Ray tracing para Lambda"
  type        = bool
  default     = false
}

# =============================================================================
# TAGS COMUNES
# =============================================================================

variable "common_tags" {
  description = "Tags comunes aplicados a todos los recursos"
  type        = map(string)
  default = {
    Project     = "courses-system"
    ManagedBy   = "terraform"
    Owner       = "platform-team"
  }
}

