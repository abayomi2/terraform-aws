# modules/rds/variables.tf
variable "project_name" {
  description = "The project name for tagging."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging."
  type        = string
}

variable "vpc_id" {
  description = "The ID of the VPC."
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for the RDS DB Subnet Group."
  type        = list(string)
}

variable "is_production" {
  description = "Flag to enable production settings for RDS (multi-AZ, backups)."
  type        = bool
}