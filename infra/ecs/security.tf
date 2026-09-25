resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allows internet traffic to the ECS load balancer"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260: HTTP-only access is intentional for the development environment.
  security_group_id = aws_security_group.alb.id
  description       = "HTTP from the internet"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  count             = var.enable_https ? 1 : 0
  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from the internet"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "task" {
  name        = "${var.project_name}-${var.environment}-task-sg"
  description = "Allows the ECS ALB and required private service access"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-task-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_vpc_security_group_ingress_rule" "task_from_alb" {
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = aws_security_group.alb.id
  description                  = "Frontend traffic from the ECS ALB"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "alb_to_task" {
  security_group_id            = aws_security_group.alb.id
  referenced_security_group_id = aws_security_group.task.id
  description                  = "Frontend traffic to ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 8080
  to_port                      = 8080
}

resource "aws_vpc_security_group_egress_rule" "task_to_database" {
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = data.terraform_remote_state.application.outputs.database_security_group_id
  description                  = "MySQL to the private RDS database"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_ingress_rule" "database_from_task" {
  security_group_id            = data.terraform_remote_state.application.outputs.database_security_group_id
  referenced_security_group_id = aws_security_group.task.id
  description                  = "MySQL from ECS application tasks"
  ip_protocol                  = "tcp"
  from_port                    = 3306
  to_port                      = 3306
}

resource "aws_vpc_security_group_egress_rule" "task_to_endpoints" {
  security_group_id            = aws_security_group.task.id
  referenced_security_group_id = data.terraform_remote_state.application.outputs.private_endpoints_security_group_id
  description                  = "HTTPS to private AWS service endpoints"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}

resource "aws_vpc_security_group_egress_rule" "task_to_s3" {
  security_group_id = aws_security_group.task.id
  description       = "HTTPS to S3 through the gateway endpoint"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  prefix_list_id    = data.aws_prefix_list.s3.id
}

resource "aws_vpc_security_group_ingress_rule" "endpoints_from_task" {
  security_group_id            = data.terraform_remote_state.application.outputs.private_endpoints_security_group_id
  referenced_security_group_id = aws_security_group.task.id
  description                  = "HTTPS from ECS tasks"
  ip_protocol                  = "tcp"
  from_port                    = 443
  to_port                      = 443
}
