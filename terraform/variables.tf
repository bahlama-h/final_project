# variables.tf

variable "aws_region" {
  description = "The AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name of the ECS cluster"
  type        = string
  default     = "demo_cluster"
}

variable "services" {
  description = "List of services to create"
  type = list(object({
    name              = string
    container_name    = string
    image             = string
    cpu               = string
    memory            = string
    container_port    = number
    host_port         = number
    desired_count     = number
    health_check_path = string
  }))
  default = [
    {
      name              = "htmldemo"
      container_name    = "htmldemo"
      image             = "htmldemo/hightech:1.0.1"
      cpu               = "256"
      memory            = "512"
      container_port    = 80
      host_port         = 80
      desired_count     = 1
      health_check_path = "/"
    }
    # You can add more services here
  ]
}

variable "lb_name" {
  description = "Name of the load balancer"
  type        = string
  default     = "app-lb"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "availability_zones" {
  description = "Availability Zones to use"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "environment" {
  description = "Environment name for tagging"
  type        = string
  default     = "dev"
}

variable "ecs_task_execution_role_name" {
  description = "ECS task execution role name"
  type        = string
  default     = "ecs_task_execution_role"
}

variable "ecs_task_role_name" {
  description = "ECS task role name"
  type        = string
  default     = "ecs_task_role"
}

variable "logs_retention_in_days" {
  description = "Retention period for CloudWatch logs"
  type        = number
  default     = 7
}