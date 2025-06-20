# modules/ecs_cluster/outputs.tf
output "cluster_id" {
  description = "The ID of the ECS cluster."
  value       = aws_ecs_cluster.this.id
}