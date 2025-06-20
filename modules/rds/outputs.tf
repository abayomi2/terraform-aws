# modules/rds/outputs.tf

output "db_instance_address" {
  description = "The address of the RDS database instance."
  value       = aws_db_instance.this.address
}

output "db_instance_port" {
  description = "The port of the RDS database instance."
  value       = aws_db_instance.this.port
}

output "db_instance_name" {
  description = "The name of the database."
  value       = aws_db_instance.this.db_name
}

output "db_master_username" {
  description = "The master username for the database."
  value       = aws_db_instance.this.username
}

output "db_password_secret_arn" {
  description = "The ARN of the Secrets Manager secret for the database password."
  value       = aws_secretsmanager_secret.db_password_secret.arn
}

output "rds_security_group_id" {
  description = "The ID of the RDS security group."
  value       = aws_security_group.rds_sg.id
}

# New output to expose the actual password (if needed by other modules directly)
# but it's generally better to pass the ARN and let the consuming service get the secret.
/*
output "db_master_password_plain" {
  description = "The generated database master password (use with caution - sensitive)."
  value       = random_password.db_master_password.result
  sensitive   = true # Mark as sensitive
}
*/