variable "aws_region" {
  default     = "us-aest-1"
  description = "aws region where our resources going to create choose"
}

variable "az_count" {
  type        = number
  default     = "2"
  description = "number of availability zones in above region"
}

variable "ecs_task_execution_role" {
  default     = "myECcsTaskExecutionRole"
  type        = string
  description = "ECS task execution role name"
}

variable "app_image" {
  type        = string
  default     = "bahmah2024/browny-app:3.0.0"
  description = "docker image to run in this ECS cluster"
}

variable "app_port" {
  type        = number
  default     = "80"
  description = "portexposed on the docker image"
}

variable "app_count" {
  type        = number
  default     = "2" #choose 2 bcz i have choosen 2 AZ
  description = "numer of docker containers to run"
}

variable "health_check_path" {
  default = "/"
}

variable "fargate_cpu" {
  type        = number
  default     = "1024"
  description = "fargate instacne CPU units to provision,my requirent 1 vcpu so gave 1024"
}

variable "fargate_memory" {
  type        = number
  default     = "2048"
  description = "Fargate instance memory to provision (in MiB) not MB"
}

# Add the domain name variable
variable "domain_name" {
  description = "The domain name for the application"
  type        = string
  default     = "devopsadvance.com"
}

# Update or add the app_port variable to support both HTTP and HTTPS
variable "https_port" {
  description = "The port on which the application will run"
  type        = number
  default     = 443
}