# variables.tf (Root Module)
variable "aws_region" {
  description = "The AWS region where resources will be deployed."
  type        = string
  default     = "ap-southeast-2"
}

variable "project_name" {
  description = "A tag for all resources, typically the project or application name."
  type        = string
  default     = "MyWebApp"
}

variable "environment" {
  description = "The deployment environment (e.g., dev, prod)."
  type        = string
  default     = "dev"
}

variable "is_production" {
  description = "Set to true for production-grade settings (e.g., multi-AZ RDS, backups)."
  type        = bool
  default     = false
}