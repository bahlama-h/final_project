# Define the ECS service auto scaling target
resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.browny_cluster.name}/${aws_ecs_service.browny_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

# Policy to automatically scale capacity up by one
resource "aws_appautoscaling_policy" "ecs_policy_up" {
  name               = "scale-up"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.browny_cluster.name}/${aws_ecs_service.browny_service.name}"
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

# Policy to automatically scale capacity down by one
resource "aws_appautoscaling_policy" "ecs_policy_down" {
  name               = "scale-down"
  policy_type        = "StepScaling"
  resource_id        = "service/${aws_ecs_cluster.browny_cluster.name}/${aws_ecs_service.browny_service.name}"
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}