# CloudFront Distribution usando variables del archivo variables.tf
resource "aws_cloudfront_distribution" "app_distribution" {
  enabled     = true
  comment     = "Distribución para ${var.project_name}"
  price_class = "PriceClass_100" 
  # Origen para API Gateway
  origin {
    domain_name = "${aws_api_gateway_rest_api.certificates_api.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_path = "/${var.api_gateway_stage_name}"
    origin_id   = "api-gateway"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # Origen para S3
  origin {
    domain_name = aws_s3_bucket.web_app.bucket_regional_domain_name
    origin_id   = "s3-origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.s3_oai.cloudfront_access_identity_path
    }
  }

  # Comportamiento por defecto (S3)
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  # Comportamiento para API (/api/*)
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "api-gateway"
    viewer_protocol_policy = "https-only"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0

    forwarded_values {
      query_string = true
      headers      = ["Origin", "Authorization"]
      cookies {
        forward = "all"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true 
  }

  tags = var.common_tags
}

# Data source para obtener la región actual
data "aws_region" "current" {}