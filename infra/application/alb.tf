#trivy:ignore:AVD-AWS-0053: The public ALB is intentional; application servers and database remain private.
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
  #checkov:skip=CKV_AWS_378: HTTP is intentional inside the private VPC; HTTPS is optional at the public ALB.
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
  #checkov:skip=CKV_AWS_2: HTTP-only access is intentional for dev; test and production redirect to HTTPS.
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = var.enable_https ? "redirect" : "forward"
    target_group_arn = var.enable_https ? null : aws_lb_target_group.app.arn

    dynamic "redirect" {
      for_each = var.enable_https ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }
}

resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn   = length(local.ec2_domain_name) > 0 ? aws_acm_certificate_validation.site[0].certificate_arn : var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
