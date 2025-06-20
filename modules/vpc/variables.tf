# modules/vpc/variables.tf
variable "project_name" {
  description = "The project name for tagging."
  type        = string
}

variable "environment" {
  description = "The environment name for tagging."
  type        = string
}

variable "aws_region" {
  description = "The AWS region."
  type        = string
}

variable "nat_gateway_count" {
  description = "Number of NAT Gateways to deploy."
  type        = number
  default     = 1
}