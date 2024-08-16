# ALB resource (already defined)
resource "aws_alb" "alb" {
  name            = "browny-app-load-balancer"
  subnets         = aws_subnet.public.*.id
  security_groups = [aws_security_group.alb-sg.id]
}

# HTTP Target Group
resource "aws_alb_target_group" "browny-app_tg" {
  name        = "browny-app-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.browny_vpc.id

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    protocol            = "HTTP"
    matcher             = "200"
    path                = var.health_check_path
    interval            = 30
  }
}

# Fetch Route 53 hosted zone
data "aws_route53_zone" "public" {
  name         = "devopsadvance.com"
  private_zone = false
}

# Request SSL/TLS Certificate for your domain
resource "aws_acm_certificate" "devops_cert" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  tags = {
    Name = "devopsadvance_cert"
  }
}

# Route 53 DNS validation for the certificate
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.devops_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      type   = dvo.resource_record_type
      record = dvo.resource_record_value
    }
  }

  zone_id = data.aws_route53_zone.public.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# Wait for certificate validation
resource "aws_acm_certificate_validation" "devops_cert_validation" {
  certificate_arn         = aws_acm_certificate.devops_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Alias Record for the ALB in Route 53
resource "aws_route53_record" "alb_alias" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "devopsadvance.com" # Root domain
  type    = "A"

  alias {
    name                   = aws_alb.alb.dns_name
    zone_id                = aws_alb.alb.zone_id
    evaluate_target_health = true
  }
}

# HTTP Listener - Redirect HTTP to HTTPS
resource "aws_alb_listener" "browny-app-http" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      host         = "#{host}"
      path         = "/#{path}"
      port         = "443"
      protocol     = "HTTPS"
      query        = "#{query}"
    }
  }
}

# HTTPS Listener - Forward traffic to the target group
resource "aws_alb_listener" "browny-app-https" {
  load_balancer_arn = aws_alb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate_validation.devops_cert_validation.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.browny-app_tg.arn
  }

  depends_on = [aws_acm_certificate_validation.devops_cert_validation]
}

# Output ALB DNS name
output "custom_domain" {
  value = "https://${aws_acm_certificate.devops_cert.domain_name}/ping"
}