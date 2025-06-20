# outputs.tf (Root Module)
output "alb_dns_name" {
  description = "The DNS name of the shared Application Load Balancer."
  value       = module.alb.alb_dns_name
}