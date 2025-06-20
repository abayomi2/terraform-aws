# modules/ecs_service/variables.tf
variable "name" {
  description = "The unique name for this specific ECS service (e.g., 'analytical-app', 'reporting-app')."
  type        = string
}

variable "project_name" {
  description = "The project name for tagging."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging."
  type        = string
}

variable "cluster_id" {
  description = "The ID of the ECS cluster."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "db_secrets_arn" {
  description = "The ARN of the Secrets Manager secret for the database password."
  type        = string
}

variable "db_host" {
  description = "The database host address."
  type        = string
}

variable "db_port" {
  description = "The database port."
  type        = number
}

variable "db_name" {
  description = "The database name."
  type        = string
}

variable "db_username" {
  description = "The database username."
  type        = string
}

variable "aws_region" {
  description = "The AWS region."
  type        = string
}

variable "container_port" {
  description = "The port the container listens on."
  type        = number
}

variable "image_name" {
  description = "The name of the ECR repository that holds the Docker image for this service."
  type        = string
}

variable "alb_listener_arn" {
  description = "The ARN of the shared ALB listener to attach this service to."
  type        = string
}

variable "alb_path_patterns" {
  description = "List of path patterns for ALB routing."
  type        = list(string)
}

variable "alb_priority" {
  description = "The priority of the ALB listener rule for this service."
  type        = number
}

variable "health_check_path" {
  description = "The path for the ALB target group health check."
  type        = string
  default     = "/"
}