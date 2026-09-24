resource "aws_security_group" "alb" {
  name        = "${var.project_name}-${var.environment}-alb-sg"
  description = "Allows web traffic to the load balancer"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    #checkov:skip=CKV_AWS_260: Port 80 only redirects visitors to HTTPS.
    description = "HTTP redirect from the internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from the internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

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

  egress {
    description     = "HTTPS to approved AWS private endpoints"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.private_endpoints.id]
  }

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

resource "aws_security_group" "private_endpoints" {
  name        = "${var.project_name}-${var.environment}-endpoints-sg"
  description = "Allows application servers to reach AWS private endpoints"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
}

resource "aws_security_group" "database" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Allows MySQL traffic from application servers only"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    description     = "MySQL from application servers only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-sg"
    Project     = var.project_name
    Environment = var.environment
  }
}

