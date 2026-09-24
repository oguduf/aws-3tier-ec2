#trivy:ignore:AVD-AWS-0053: This is the intentional public HTTPS entry point; application servers and database remain private.
resource "aws_lb" "main" {
  #checkov:skip=CKV_AWS_91: ALB access logging needs a dedicated log-delivery bucket; add it with the production logging account.
  #checkov:skip=CKV2_AWS_28: WAF is intentionally deferred because it has recurring cost; do not expose production before adding it.
  name                       = "${var.project_name}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb.id]
  subnets                    = data.terraform_remote_state.network.outputs.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = true

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_target_group" "app" {
  #checkov:skip=CKV_AWS_378: TLS terminates at the ALB; ALB-to-private-EC2 traffic stays within the VPC.
  name     = "${var.project_name}-${var.environment}-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-app-tg"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_lb_listener" "http" {
  #checkov:skip=CKV_AWS_2: This listener only redirects HTTP requests to HTTPS.
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
