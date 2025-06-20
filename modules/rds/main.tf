# modules/rds/main.tf
# This module sets up an RDS PostgreSQL database with a master user password stored in AWS Secrets Manager.
# It generates a random password for the database master user and stores it securely.

# --- Generate a random password for the database master user ---
resource "random_password" "db_master_password" {
  length           = 16
  special          = false # Equivalent to exclude_punctuation=True in CDK
  override_special = "!\"#$%&'()*+,-./:;<=>?@[\\]^_`{|}~" # Explicitly exclude common punctuation
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
}

# --- Store the generated password in AWS Secrets Manager ---
resource "aws_secretsmanager_secret" "db_password_secret" {
  name                    = "${var.project_name}-${var.environment}-DBPassword"
  description             = "Database master user password for ${var.project_name}"
  recovery_window_in_days = 0 # Corresponds to RemovalPolicy.DESTROY

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-password"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_secretsmanager_secret_version" "db_password_secret_version" {
  secret_id     = aws_secretsmanager_secret.db_password_secret.id
  secret_string = jsonencode({
    username = "postgresadmin",
    password = random_password.db_master_password.result
  })
}

# --- Reference the secret string for RDS ---
resource "aws_db_instance" "this" {
  engine                 = "postgres"
  engine_version         = "17.4"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "mypostgresdb"
  username               = "postgresadmin"
  password               = jsondecode(aws_secretsmanager_secret_version.db_password_secret_version.secret_string)["password"]
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot    = var.is_production ? false : true
  final_snapshot_identifier = var.is_production ? "${var.project_name}-${var.environment}-final-snapshot" : null

  multi_az                 = var.is_production
  backup_retention_period  = var.is_production ? 7 : 0
  delete_automated_backups = var.is_production ? false : true

  tags = {
    Name        = "${var.project_name}-${var.environment}-postgres-db"
    Environment = var.environment
    Project     = var.project_name
  }
}

# ... (rest of your modules/rds/main.tf, like aws_db_subnet_group and aws_security_group.rds_sg) ...
resource "aws_db_subnet_group" "this" {
  name = "${lower(var.project_name)}-${lower(var.environment)}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name        = "${var.project_name}-${var.environment}-db-subnet-group"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "${var.project_name}-${var.environment}-rds-sg"
  description = "Allow inbound connections to RDS from ECS Fargate"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-rds-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}