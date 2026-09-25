output "load_balancer_dns_name" {
  description = "Public address of the ECS Task Manager application"
  value       = aws_lb.main.dns_name
}

output "website_url" {
  description = "HTTPS address of the custom domain when one is configured"
  value       = length(var.domain_name) > 0 ? "https://${var.domain_name}" : null
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.application.name
}
