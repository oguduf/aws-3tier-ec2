variable "state_bucket_name" {
  description = "Shared S3 bucket containing Terraform state"
  type        = string
}

data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.state_bucket_name
    key    = "network/${var.environment}/terraform.tfstate"
    region = var.aws_region
  }
}

resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-db-subnets"
  subnet_ids = data.terraform_remote_state.network.outputs.private_subnet_ids
}
