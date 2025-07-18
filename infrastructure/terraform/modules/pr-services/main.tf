# infrastructure/terraform/modules/pr-services/main.tf
# Simplified version without service discovery

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
  tags              = var.tags
}

resource "aws_cloudwatch_log_group" "mongodb" {
  name              = "/ecs/mongodb-pr-${var.pr_number}"
  retention_in_days = 7
  tags              = var.tags
}

# Security Groups with simplified rules
resource "aws_security_group" "django" {
  name        = "django-pr-${var.pr_number}"
  description = "Security group for Django service PR ${var.pr_number}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [var.alb_security_group_id]
    description     = "ALB to Django"
  }

  # Allow all outbound traffic (simplified)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "django-sg-pr-${var.pr_number}"
  })
}

resource "aws_security_group" "mongodb" {
  name        = "mongodb-pr-${var.pr_number}"
  description = "Security group for MongoDB service PR ${var.pr_number}"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
    description = "MongoDB access from VPC"
  }

  # Allow all outbound traffic (simplified)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = merge(var.tags, {
    Name = "mongodb-sg-pr-${var.pr_number}"
  })
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

# MongoDB Task Definition
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

# MongoDB ECS Service
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

  tags = var.tags
}

# Wait for MongoDB service to be stable
resource "time_sleep" "wait_for_mongodb" {
  depends_on      = [aws_ecs_service.mongodb]
  create_duration = "60s"
}

# Django Task Definition (created after MongoDB)
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
          value = "host.docker.internal" # Fallback - will be updated via null_resource
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

      essential = true
    }
  ])

  depends_on = [time_sleep.wait_for_mongodb]
  tags       = var.tags
}

# Django ECS Service
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

  depends_on = [aws_ecs_service.mongodb, aws_lb_listener_rule.django, time_sleep.wait_for_mongodb]
  tags       = var.tags
}

# Wait for services to be running
resource "time_sleep" "wait_for_services" {
  depends_on      = [aws_ecs_service.django, aws_ecs_service.mongodb]
  create_duration = "120s"
}

# Null resource to update Django with MongoDB IP after deployment
resource "null_resource" "update_django_with_mongodb_ip" {
  depends_on = [time_sleep.wait_for_services]

  provisioner "local-exec" {
    command = <<-EOT
      # Wait for MongoDB to be running and get its IP
      echo "Waiting for MongoDB to be running..."
      for i in {1..20}; do
        MONGODB_TASK=$(aws ecs list-tasks --cluster ${var.cluster_id} --service-name mongodb-pr-${var.pr_number} --desired-status RUNNING --query 'taskArns[0]' --output text --region ${data.aws_region.current.name})
        if [ "$MONGODB_TASK" != "None" ] && [ "$MONGODB_TASK" != "" ]; then
          MONGODB_IP=$(aws ecs describe-tasks --cluster ${var.cluster_id} --tasks $MONGODB_TASK --query 'tasks[0].attachments[0].details[?name==`privateIPv4Address`].value' --output text --region ${data.aws_region.current.name})
          if [ "$MONGODB_IP" != "" ] && [ "$MONGODB_IP" != "None" ]; then
            echo "Found MongoDB IP: $MONGODB_IP"
            
            # Update Django task definition with MongoDB IP
            aws ecs register-task-definition \
              --family django-pr-${var.pr_number} \
              --network-mode awsvpc \
              --requires-compatibilities FARGATE \
              --cpu 256 \
              --memory 512 \
              --execution-role-arn ${var.execution_role_arn} \
              --container-definitions "[{
                \"name\": \"django\",
                \"image\": \"${var.django_image}\",
                \"portMappings\": [{\"containerPort\": 8000, \"protocol\": \"tcp\"}],
                \"environment\": [
                  {\"name\": \"MONGODB_HOST\", \"value\": \"$MONGODB_IP\"},
                  {\"name\": \"MONGODB_PORT\", \"value\": \"27017\"},
                  {\"name\": \"MONGODB_DATABASE\", \"value\": \"mercor_pr_${var.pr_number}\"},
                  {\"name\": \"DEBUG\", \"value\": \"True\"},
                  {\"name\": \"PR_NUMBER\", \"value\": \"${var.pr_number}\"}
                ],
                \"logConfiguration\": {
                  \"logDriver\": \"awslogs\",
                  \"options\": {
                    \"awslogs-group\": \"${aws_cloudwatch_log_group.django.name}\",
                    \"awslogs-region\": \"${data.aws_region.current.name}\",
                    \"awslogs-stream-prefix\": \"ecs\"
                  }
                },
                \"essential\": true
              }]" \
              --region ${data.aws_region.current.name}
            
            # Get latest task definition revision
            LATEST_REVISION=$(aws ecs describe-task-definition --task-definition django-pr-${var.pr_number} --query 'taskDefinition.revision' --output text --region ${data.aws_region.current.name})
            
            # Update Django service to use new task definition (without waiting)
            aws ecs update-service \
              --cluster ${var.cluster_id} \
              --service django-pr-${var.pr_number} \
              --task-definition django-pr-${var.pr_number}:$LATEST_REVISION \
              --force-new-deployment \
              --region ${data.aws_region.current.name}
            
            echo "✅ Updated Django service with MongoDB IP: $MONGODB_IP"
            echo "🎉 Automation completed! Django will restart with the correct MongoDB IP."
            break
          fi
        fi
        echo "Attempt $i: MongoDB not ready, waiting 10 seconds..."
        sleep 10
      done
    EOT
  }

  # Trigger this resource when services change
  triggers = {
    mongodb_service = aws_ecs_service.mongodb.id
    django_service  = aws_ecs_service.django.id
  }
}