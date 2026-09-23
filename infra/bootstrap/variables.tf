variable "state_bucket_name" {
  description = "Globally unique S3 bucket used for Terraform state"
  type        = string
}

variable "aws_region" {
  description = "AWS region for the state bucket"
  type        = string
  default     = "us-east-2"
}
