# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "alb-sg" {
  name        = "projectapp-load-balancer-security-group"
  description = "controls access to the ALB"
  vpc_id      = aws_vpc.browny_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    protocol    = "tcp"
    from_port   = 80   
    to_port     = 80    
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ECS Security Group: Traffic to the ECS cluster should only come from the ALB
resource "aws_security_group" "ecs_sg" {
  name        = "projectapp-ecs-tasks-security-group"
  description = "allow inbound access from the ALB only"
  vpc_id      = aws_vpc.browny_vpc.id

  ingress {
    protocol        = "tcp"
    from_port       = var.app_port # Ensure this matches your variable in variables.tf
    to_port         = var.app_port # Ensure this matches your variable in variables.tf
    security_groups = [aws_security_group.alb-sg.id]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}