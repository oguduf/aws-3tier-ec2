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

output "database_secret_arn" {
  description = "AWS Secrets Manager ARN containing the RDS credentials"
  value       = aws_db_instance.main.master_user_secret[0].secret_arn
}

output "load_balancer_dns_name" {
  description = "Public address of the Task Manager website"
  value       = aws_lb.main.dns_name
}

output "auto_scaling_group_name" {
  description = "Auto Scaling Group that runs the application servers"
  value       = aws_autoscaling_group.app.name
}

output "website_url" {
  description = "HTTPS address of the EC2 application when a Route 53 domain is configured"
  value       = length(local.ec2_domain_name) > 0 ? "https://${local.ec2_domain_name}" : null
}

output "private_endpoints_security_group_id" {
  description = "Security group attached to the shared private AWS service endpoints"
  value       = aws_security_group.private_endpoints.id
}

output "database_security_group_id" {
  description = "Security group attached to the private RDS database"
  value       = aws_security_group.database.id
}
