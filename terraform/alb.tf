# Create Load Balancer
resource "aws_lb" "app_lb" {
  name               = var.lb_name
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  enable_deletion_protection = false

  tags = {
    Name        = var.lb_name
    Environment = var.environment
  }
}

# Create Target Groups dynamically
resource "aws_lb_target_group" "app_tgs" {
  count       = length(var.services)
  name        = "${var.services[count.index].name}-tg"
  port        = var.services[count.index].container_port
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/*"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200-399"
  }

  tags = {
    Name        = "${var.services[count.index].name}-tg"
    Environment = var.environment
  }
}

# Create Listener for Load Balancer
resource "aws_lb_listener" "app_lb_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "No routes matched"
      status_code  = "404"
    }
  }
}

# Create Listener Rules for each service
resource "aws_lb_listener_rule" "service_rules" {
  count        = length(var.services)
  listener_arn = aws_lb_listener.app_lb_listener.arn
  priority     = 100 + count.index

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tgs[count.index].arn
  }

  condition {
    path_pattern {
      values = ["/${var.services[count.index].name}", "/${var.services[count.index].name}/*"]
    }
  }
}

# Output the DNS name of the load balancer
output "load_balancer_dns" {
  value       = aws_lb.app_lb.dns_name
  description = "The DNS name of the load balancer"
}

# Output the ARNs of the target groups
output "target_group_arns" {
  value       = aws_lb_target_group.app_tgs[*].arn
  description = "The ARNs of the target groups"
}