# Create ECS Cluster
resource "aws_ecs_cluster" "demo_cluster" {
  name = var.cluster_name
}

resource "aws_ecs_task_definition" "task_definitions" {
  count                    = length(var.services)
  family                   = "${var.services[count.index].name}_task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.services[count.index].cpu
  memory                   = var.services[count.index].memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn

  container_definitions = jsonencode([
    {
      name      = var.services[count.index].container_name
      image     = var.services[count.index].image
      essential = true
      portMappings = [
        {
          containerPort = var.services[count.index].container_port
          hostPort      = var.services[count.index].host_port
        }
      ]
    }
  ])
}

# Create ECS Service
resource "aws_ecs_service" "services" {
  count           = length(var.services)
  name            = var.services[count.index].name
  cluster         = aws_ecs_cluster.demo_cluster.id
  task_definition = aws_ecs_task_definition.task_definitions[count.index].arn
  desired_count   = var.services[count.index].desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tgs[count.index].arn
    container_name   = var.services[count.index].container_name
    container_port   = var.services[count.index].container_port
  }

  depends_on = [aws_lb_listener.app_lb_listener]
}

# # Create target groups dynamically
# resource "aws_lb_target_group" "app_tgs" {
#   count       = length(var.services)
#   name        = "${var.services[count.index].name}-tg"
#   port        = var.services[count.index].container_port
#   protocol    = "HTTP"
#   vpc_id      = aws_vpc.main.id
#   target_type = "ip"

#   health_check {
#     healthy_threshold   = "3"
#     interval            = "30"
#     protocol            = "HTTP"
#     matcher             = "200"
#     timeout             = "3"
#     path                = "/"
#     unhealthy_threshold = "2"
#   }
# }