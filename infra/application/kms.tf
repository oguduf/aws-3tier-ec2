data "aws_caller_identity" "current" {}

resource "aws_kms_key" "application" {
  description             = "Encrypts application images and logs"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "EnableAccountIAMPolicies"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

resource "aws_kms_alias" "application" {
  name          = "alias/${var.project_name}-${var.environment}-application"
  target_key_id = aws_kms_key.application.key_id
}
