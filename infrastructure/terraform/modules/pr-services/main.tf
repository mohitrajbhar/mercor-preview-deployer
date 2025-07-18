data "aws_region" "current" {}

# Data source for shared infrastructure
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket         = "test-terraform-state-bucket-mohit"
    key            = "shared-infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "test-terraform-state-locks-mohit"
  }
}

# Service Discovery Namespace for this PR
resource "aws_service_discovery_private_dns_namespace" "pr" {
  name = "pr-${var.pr_number}.local"
  vpc  = var.vpc_id

  tags = var.tags
}

resource "aws_service_discovery_service" "django" {
  name = "django"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.pr.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  tags = var.tags
}

resource "aws_service_discovery_service" "mongodb" {
  name = "mongodb"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.pr.id
    dns_records {
      ttl  = 10
      type = "A"
    }
    routing_policy = "MULTIVALUE"
  }

  tags = var.tags
}

# EFS Access Point for this PR
resource "aws_efs_access_point" "mongodb" {
  file_system_id = var.efs_id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/pr-${var.pr_number}"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "0755"
    }
  }

  tags = merge(var.tags, {
    Name = "mongodb-pr-${var.pr_number}"
  })
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "django" {
  name              = "/ecs/django-pr-${var.pr_number}"
  retention_in_days = 7

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "mongodb" {
  name              = "/ecs/mongodb-pr-${var.pr_number}"
  retention_in_days = 7

  tags = var.tags
}

# Security Groups (without circular dependencies)
resource "aws_security_group" "django" {
  name        = "django-pr-${var.pr_number}"
  description = "Security group for Django service PR ${var.pr_number}"
  vpc_id      = var.vpc_id

  # Ingress: Allow ALB to reach Django
  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "ALB to Django"
  }

  # Egress: Allow HTTPS for package downloads, API calls
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for package downloads and API calls"
  }

  # Egress: Allow HTTP for redirects and package downloads
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound for redirects and package downloads"
  }

  # Egress: Allow DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  tags = merge(var.tags, {
    Name = "django-sg-pr-${var.pr_number}"
  })
}

resource "aws_security_group" "mongodb" {
  name        = "mongodb-pr-${var.pr_number}"
  description = "Security group for MongoDB service PR ${var.pr_number}"
  vpc_id      = var.vpc_id

  # Egress: Allow HTTPS for Docker image pulls
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for Docker image pulls"
  }

  # Egress: Allow HTTP for Docker image pulls and redirects
  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP outbound for Docker image pulls"
  }

  # Egress: Allow DNS resolution
  egress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "DNS resolution"
  }

  # Egress: Allow EFS access (if we add persistent storage later)
  egress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.efs_security_group_id]
    description     = "EFS access for persistent storage"
  }

  tags = merge(var.tags, {
    Name = "mongodb-sg-pr-${var.pr_number}"
  })
}

# Separate security group rules to avoid circular dependency
resource "aws_security_group_rule" "django_to_mongodb" {
  type                     = "egress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.django.id
  source_security_group_id = aws_security_group.mongodb.id
  description              = "Django to MongoDB communication"
}

resource "aws_security_group_rule" "mongodb_from_django" {
  type                     = "ingress"
  from_port                = 27017
  to_port                  = 27017
  protocol                 = "tcp"
  security_group_id        = aws_security_group.mongodb.id
  source_security_group_id = aws_security_group.django.id
  description              = "MongoDB accepts connections from Django"
}

# ALB Target Group
resource "aws_lb_target_group" "django" {
  name        = "django-pr-${var.pr_number}"
  port        = 8000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    path                = "/health/"
    matcher             = "200"
    protocol            = "HTTP"
    port                = "traffic-port"
  }

  tags = var.tags
}

# ALB Listener Rule
resource "aws_lb_listener_rule" "django" {
  listener_arn = var.alb_listener_arn
  priority     = var.pr_number

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.django.arn
  }

  condition {
    host_header {
      values = ["pr-${var.pr_number}.${var.domain_name}"]
    }
  }
}

# Route53 DNS Record
resource "aws_route53_record" "pr" {
  zone_id = var.hosted_zone_id
  name    = "pr-${var.pr_number}.${var.domain_name}"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}

# Task Definitions
resource "aws_ecs_task_definition" "mongodb" {
  family                   = "mongodb-pr-${var.pr_number}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "mongodb"
      image = var.mongodb_image

      portMappings = [
        {
          containerPort = 27017
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MONGO_INITDB_DATABASE"
          value = "mercor_pr_${var.pr_number}"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.mongodb.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      essential = true
    }
  ])

  tags = var.tags
}

resource "aws_ecs_task_definition" "django" {
  family                   = "django-pr-${var.pr_number}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arn

  container_definitions = jsonencode([
    {
      name  = "django"
      image = var.django_image

      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "MONGODB_HOST"
          value = "mongodb.pr-${var.pr_number}.local"
        },
        {
          name  = "MONGODB_PORT"
          value = "27017"
        },
        {
          name  = "MONGODB_DATABASE"
          value = "mercor_pr_${var.pr_number}"
        },
        {
          name  = "DEBUG"
          value = "True"
        },
        {
          name  = "PR_NUMBER"
          value = tostring(var.pr_number)
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.django.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }

      healthCheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8000/health/ || exit 1"]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
    }
  ])

  tags = var.tags
}

# ECS Services
resource "aws_ecs_service" "mongodb" {
  name            = "mongodb-pr-${var.pr_number}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.mongodb.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.mongodb.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.mongodb.arn
  }

  tags = var.tags
}

resource "aws_ecs_service" "django" {
  name            = "django-pr-${var.pr_number}"
  cluster         = var.cluster_id
  task_definition = aws_ecs_task_definition.django.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnets
    security_groups  = [aws_security_group.django.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.django.arn
    container_name   = "django"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.django.arn
  }

  depends_on = [aws_ecs_service.mongodb, aws_lb_listener_rule.django]

  tags = var.tags
}