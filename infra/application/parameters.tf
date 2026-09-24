resource "aws_ssm_parameter" "frontend_image" {
  name   = "/task-manager/${var.environment}/frontend-image"
  type   = "SecureString"
  key_id = aws_kms_key.application.arn
  value  = "not-deployed"

  lifecycle {
    ignore_changes = [value]
  }
}

resource "aws_ssm_parameter" "backend_image" {
  name   = "/task-manager/${var.environment}/backend-image"
  type   = "SecureString"
  key_id = aws_kms_key.application.arn
  value  = "not-deployed"

  lifecycle {
    ignore_changes = [value]
  }
}
