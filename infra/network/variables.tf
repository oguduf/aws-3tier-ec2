variable "project_name" {
  type    = string
  default = "aws-3tier-ec2"
}

variable "environment" {
  type = string

  validation {
    condition     = contains(["dev", "test", "production"], var.environment)
    error_message = "Environment must be dev, test, or production."
  }
}

variable "aws_region" {
  type    = string
  default = "us-east-2"
}

variable "vpc_cidr" {
  type = string
}
