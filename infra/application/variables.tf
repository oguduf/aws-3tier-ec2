variable "project_name" {
  description = "Name used to label AWS resources"
  type        = string
  default     = "aws-3tier-ec2"
}

variable "environment" {
  description = "Deployment environment"
  type        = string

  validation {
    condition     = contains(["dev", "test", "production"], var.environment)
    error_message = "Environment must be dev, test, or production."
  }
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-2"
}

variable "db_name" {
  description = "Name of the MySQL database"
  type        = string
  default     = "task_manager"
}

variable "db_username" {
  description = "Username the application uses to connect to MySQL"
  type        = string
  default     = "task_app"
}

variable "instance_type" {
  description = "EC2 size for application servers"
  type        = string
  default     = "t3.micro"
}

variable "app_min_size" {
  description = "Minimum number of application servers"
  type        = number
  default     = 1
}

variable "app_max_size" {
  description = "Maximum number of application servers"
  type        = number
  default     = 2
}

variable "app_desired_capacity" {
  description = "Number of application servers to start with"
  type        = number
  default     = 1
}

variable "database_multi_az" {
  description = "Whether RDS has a synchronous standby in another Availability Zone"
  type        = bool
  default     = false
}

