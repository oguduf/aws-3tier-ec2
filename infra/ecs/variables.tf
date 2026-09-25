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

variable "image_tag" {
  description = "Immutable commit SHA tag built by the application workflow"
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

variable "certificate_arn" {
  description = "ACM certificate ARN for the ECS ALB HTTPS listener"
  type        = string
  default     = ""

  validation {
    condition     = !var.enable_https || length(var.certificate_arn) > 0
    error_message = "Set certificate_arn when enable_https is true."
  }
}
