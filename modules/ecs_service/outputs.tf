# modules/ecs_service/outputs.tf
output "ecs_service_name" {
  description = "The name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "ecs_service_arn" {
  description = "The ARN of the ECS service."
  value       = aws_ecs_service.this.arn
}

output "ecs_security_group_id" {
  description = "The ID of the ECS service security group."
  value       = aws_security_group.ecs_sg.id
}