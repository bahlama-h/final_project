# ECS Cluster
resource "aws_ecs_cluster" "browny_cluster" {
  name = "browny_cluster"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "browny-app_log_group" {
  name              = "/ecs/browny-app"
  retention_in_days = 30

  tags = {
    Name = "cw-log-group"
  }
}

# CloudWatch Log Stream
resource "aws_cloudwatch_log_stream" "browny-app_log_stream" {
  name           = "browny-log-stream"
  log_group_name = aws_cloudwatch_log_group.browny-app_log_group.name
}

# Template File Data Source
data "template_file" "browny-app" {
  template = file("./templates/image/image.json")

  vars = {
    app_image      = var.app_image
    app_port       = var.app_port
    fargate_cpu    = var.fargate_cpu
    fargate_memory = var.fargate_memory
    aws_region     = var.aws_region
  }
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "browny-app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.fargate_cpu
  memory                   = var.fargate_memory

  container_definitions = jsonencode([
    {
      name      = "browny-app"
      image     = var.app_image
      cpu       = 1024
      memory    = 2048
      portMappings = [
        {
          containerPort = var.app_port
          hostPort      = var.app_port
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/ecs/browny-app"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}
  # container_definitions    = data.template_file.browny-app.rendered

# ECS Service
resource "aws_ecs_service" "browny_service" {
  name            = "browny-app-service"
  cluster         = aws_ecs_cluster.browny_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = var.app_count
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.ecs_sg.id]
    subnets          = aws_subnet.private.*.id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.browny-app_tg.arn
    container_name   = "browny-app"
    container_port   = var.app_port
  }

  depends_on = [
    aws_alb_listener.browny-app-https,
    aws_cloudwatch_log_group.browny-app_log_group,
    aws_cloudwatch_log_stream.browny-app_log_stream
  ]
}