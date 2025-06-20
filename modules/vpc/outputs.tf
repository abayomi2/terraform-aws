# modules/vpc/outputs.tf
output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.this.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = aws_subnet.private[*].id
}

output "vpc_internal_sg_id" {
  description = "ID of the internal VPC security group."
  value       = aws_security_group.vpc_internal_sg.id
}