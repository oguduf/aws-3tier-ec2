data "aws_route53_zone" "site" {
  count        = length(var.domain_name) > 0 ? 1 : 0
  name         = "${var.domain_name}."
  private_zone = false
}

resource "aws_acm_certificate" "site" {
  count             = length(var.domain_name) > 0 ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-certificate"
    Project     = var.project_name
    Environment = var.environment
  }
}

resource "aws_route53_record" "certificate_validation" {
  count = length(var.domain_name) > 0 ? 1 : 0

  zone_id = data.aws_route53_zone.site[0].zone_id
  name    = aws_acm_certificate.site[0].domain_validation_options[0].resource_record_name
  type    = aws_acm_certificate.site[0].domain_validation_options[0].resource_record_type
  records = [aws_acm_certificate.site[0].domain_validation_options[0].resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "site" {
  count = length(var.domain_name) > 0 ? 1 : 0

  certificate_arn         = aws_acm_certificate.site[0].arn
  validation_record_fqdns = [aws_route53_record.certificate_validation[0].fqdn]
}

resource "aws_route53_record" "site" {
  count = length(var.domain_name) > 0 ? 1 : 0

  zone_id = data.aws_route53_zone.site[0].zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
