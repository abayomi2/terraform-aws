# modules/ecs_cluster/variables.tf
variable "project_name" {
  description = "The project name for tagging."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC where the cluster will be created."
  type        = string
}