output "vpc_id" {
  description = "ID of the project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_endpoint" {
  description = "MySQL database address for the application"
  value       = aws_db_instance.main.address
}

output "frontend_ecr_repository_url" {
  description = "ECR address for the frontend Docker image"
  value       = aws_ecr_repository.frontend.repository_url
}

output "backend_ecr_repository_url" {
  description = "ECR address for the backend Docker image"
  value       = aws_ecr_repository.backend.repository_url
}