resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allows web traffic to the load balancer"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group" "app" {
  name        = "${var.project_name}-${var.environment}-app-sg"
  description = "Allows traffic from the load balancer to EC2 application servers"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "alb_to_app" {
  type                     = "egress"
  description              = "HTTP to application servers"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "alb_http" {
  #checkov:skip=CKV_AWS_260: HTTP is retained only to redirect clients to HTTPS.
  type              = "ingress"
  description       = "HTTP from the internet for HTTPS redirects"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

import {
  to = aws_security_group_rule.alb_http
  id = "${aws_security_group.alb.id}_ingress_tcp_80_80_0.0.0.0/0"
}

resource "aws_security_group_rule" "alb_https" {
  count             = var.enable_https ? 1 : 0
  type              = "ingress"
  description       = "HTTPS from the internet"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.alb.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  description              = "HTTP from the load balancer only"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "app_to_private_endpoints" {
  type                     = "ingress"
  description              = "HTTPS from application servers"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.private_endpoints.id
  source_security_group_id = aws_security_group.app.id
}

resource "aws_security_group_rule" "app_to_private_endpoints_egress" {
  type                     = "egress"
  description              = "HTTPS to approved AWS private endpoints"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.private_endpoints.id
}

import {
  to = aws_security_group_rule.app_to_private_endpoints_egress
  id = "${aws_security_group.app.id}_egress_tcp_443_443_${aws_security_group.private_endpoints.id}"
}

resource "aws_security_group" "private_endpoints" {
  name        = "${var.project_name}-${var.environment}-endpoints-sg"
  description = "Allows application servers to reach AWS private endpoints"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
}

data "aws_prefix_list" "s3" {
  name = "com.amazonaws.${var.aws_region}.s3"
}

resource "aws_security_group_rule" "app_to_s3" {
  type              = "egress"
  description       = "HTTPS to Amazon S3 through the VPC gateway endpoint"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.app.id
  prefix_list_ids   = [data.aws_prefix_list.s3.id]
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allows MySQL traffic from application servers only"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "app_to_database" {
  type                     = "egress"
  description              = "MySQL from application servers to the database"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.database.id
}

resource "aws_security_group_rule" "database_from_app" {
  type                     = "ingress"
  description              = "MySQL from EC2 application servers"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.database.id
  source_security_group_id = aws_security_group.app.id
}

import {
  to = aws_security_group_rule.database_from_app
  id = "${aws_security_group.database.id}_ingress_tcp_3306_3306_${aws_security_group.app.id}"
}

