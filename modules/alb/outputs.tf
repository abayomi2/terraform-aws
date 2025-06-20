# modules/alb/outputs.tf
output "alb_dns_name" {
  description = "The DNS name of the shared Application Load Balancer."
  value       = aws_lb.this.dns_name
}

output "alb_listener_arn" {
  description = "The ARN of the public ALB listener."
  value       = aws_lb_listener.public_listener.arn
}

output "alb_security_group_id" {
  description = "The ID of the ALB security group."
  value       = aws_security_group.alb_sg.id
}