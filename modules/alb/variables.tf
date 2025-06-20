# modules/alb/variables.tf
variable "project_name" {
  description = "The project name for tagging."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be created."
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for the ALB."
  type        = list(string)
}