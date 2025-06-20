# modules/ecs_service/main.tf
# ECR Repository (Each service gets its own ECR repo)
resource "aws_ecr_repository" "this" {
  name                 = "${lower(var.project_name)}/${lower(var.name)}" # Convert both to lowercase
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-ecr"
    Environment = var.environment
    Project     = var.project_name
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "this" {
  name              = "/ecs/${var.name}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-logs"
    Environment = var.environment
    Project     = var.project_name
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "${var.project_name}-${var.environment}-${var.name}-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-ecs-task-execution-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# IAM Role for ECS Task (application-specific permissions)
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-${var.environment}-${var.name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-ecs-task-role"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_iam_role_policy" "ecs_secrets_manager_policy" {
  name = "${var.project_name}-${var.environment}-${var.name}-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = var.db_secrets_arn
      },
    ]
  })
}

# ECS Service Security Group
resource "aws_security_group" "ecs_sg" {
  name        = "${var.project_name}-${var.environment}-${var.name}-ecs-sg"
  description = "Allow inbound connections from ALB for ${var.name} ECS Fargate service"
  vpc_id      = var.vpc_id

  # Inbound from ALB
  ingress {
    from_port = var.container_port
    to_port   = var.container_port
    protocol  = "tcp"
    # This rule cannot directly reference the ALB's SG because the ALB's SG is in a different module.
    # The actual rule allowing ALB to talk to ECS needs to be created in the root module or ALB module,
    # referencing this ECS SG.
    # For simplicity, we'll allow all traffic from within the VPC here, and rely on ALB rule.
    cidr_blocks = ["10.0.0.0/16"] # Allow from within VPC, refine later if needed
    description = "Allow traffic from within VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-ecs-sg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.name}-${var.environment}"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name        = "${var.name}-container"
      image       = "${aws_ecr_repository.this.repository_url}:latest"
      cpu         = 256
      memory      = 512
      essential   = true
      portMappings = [
        {
          containerPort = var.container_port
          hostPort      = var.container_port
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = var.name == "analytical-app" ? "AnalyticalApp" : "ReportingApp"
        }
      }
      environment = [
        {
          name  = "DB_HOST"
          value = var.db_host
        },
        {
          name  = "DB_PORT"
          value = tostring(var.db_port)
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USERNAME"
          value = var.db_username
        },
        {
          name  = "DB_PASSWORD_SECRET_ARN"
          value = var.db_secrets_arn
        },
        {
          name  = "AWS_REGION"
          value = var.aws_region
        }
      ]
    }
  ])

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-task-def"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "this" {
  name        = "${var.project_name}-${var.environment}-${var.name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    path                = var.health_check_path
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_listener_rule" "this" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  condition {
    path_pattern {
      values = var.alb_path_patterns
    }
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-alb-rule"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_ecs_service" "this" {
  name            = "${var.name}-service-${var.environment}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.private_subnet_ids
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = "${var.name}-container"
    container_port   = var.container_port
  }

  depends_on = [
    aws_lb_listener_rule.this,
    aws_lb_target_group.this,
  ]

  tags = {
    Name        = "${var.project_name}-${var.environment}-${var.name}-service"
    Environment = var.environment
    Project     = var.project_name
  }
}