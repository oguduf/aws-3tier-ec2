variable "state_bucket_name" {
  description = "Shared S3 bucket containing Terraform state"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "test", "production"], var.environment)
    error_message = "Environment must be dev, test, or production."
  }
}

variable "project_name" {
  description = "Name used to label ECS resources"
  type        = string
  default     = "aws-3tier-ecs"
}

variable "backend_image" {
  description = "Immutable backend image URI retrieved by the ECS workflow"
  type        = string
}

variable "frontend_image" {
  description = "Immutable ECS frontend image URI retrieved by the ECS workflow"
  type        = string
}

variable "task_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 512
}

variable "task_memory" {
  description = "Fargate task memory in MiB"
  type        = number
  default     = 1024
}

variable "service_desired_count" {
  description = "Initial number of ECS tasks"
  type        = number
  default     = 1
}

variable "service_min_count" {
  description = "Minimum number of ECS tasks"
  type        = number
  default     = 1
}

variable "service_max_count" {
  description = "Maximum number of ECS tasks"
  type        = number
  default     = 2
}

variable "enable_https" {
  description = "Whether the public ALB should expose HTTPS"
  type        = bool
  default     = true
}

variable "domain_name" {
  description = "Public DNS name managed in Route 53 for this ECS ALB, for example app.example.com"
  type        = string
  default     = ""
}

variable "certificate_arn" {
  description = "Existing ACM certificate ARN. Leave empty when domain_name lets this stack create and validate a certificate."
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_https || length(var.certificate_arn) > 0 || length(var.domain_name) > 0
    error_message = "Set certificate_arn or domain_name when enable_https is true."
  }
}
