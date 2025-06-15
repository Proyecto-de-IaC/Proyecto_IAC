# Cognito User Pool básico
resource "aws_cognito_user_pool" "main" {
  name = "${var.project_name}-user-pool"
  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "OFF"
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = false
    require_uppercase = true
  }
}

resource "aws_cognito_user_pool_client" "main" {
  name         = "${var.project_name}-user-pool-client"
  user_pool_id = aws_cognito_user_pool.main.id
  generate_secret = false
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
  allowed_oauth_flows_user_pool_client = false
}

resource "aws_api_gateway_authorizer" "cognito" {
  name                    = "cognito-authorizer"
  rest_api_id             = aws_api_gateway_rest_api.certificates_api.id
  authorizer_uri          = null
  authorizer_credentials  = null
  type                    = "COGNITO_USER_POOLS"
  provider_arns           = [aws_cognito_user_pool.main.arn]
  identity_source         = "method.request.header.Authorization"
}
