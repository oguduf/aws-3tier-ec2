resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "application" {
  family                   = "${var.project_name}-${var.environment}-application"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  execution_role_arn       = aws_iam_role.task_execution.arn
  task_role_arn            = aws_iam_role.task.arn

  container_definitions = jsonencode([
    {
      name      = "backend"
      image     = var.backend_image
      essential = true
      cpu       = 384
      memory    = 512
      environment = [
        { name = "DATABASE_HOST", value = data.terraform_remote_state.application.outputs.database_endpoint },
        { name = "DATABASE_PORT", value = "3306" },
        { name = "DATABASE_NAME", value = "task_manager" }
      ]
      secrets = [
        { name = "DATABASE_USER", valueFrom = "${data.terraform_remote_state.application.outputs.database_secret_arn}:username::" },
        { name = "DATABASE_PASSWORD", valueFrom = "${data.terraform_remote_state.application.outputs.database_secret_arn}:password::" }
      ]
      healthCheck = {
        command     = ["CMD-SHELL", "python -c \"import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/healthz')\""]
        interval    = 30
        timeout     = 5
        retries     = 3
        startPeriod = 60
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    },
    {
      name      = "frontend"
      image     = var.frontend_image
      essential = true
      cpu       = 128
      memory    = 256
      portMappings = [{
        containerPort = 8080
        protocol      = "tcp"
      }]
      dependsOn = [{
        containerName = "backend"
        condition     = "HEALTHY"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.application.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "application" {
  name                              = "${var.project_name}-${var.environment}-application"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.application.arn
  desired_count                     = var.service_desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 120
  enable_execute_command            = true

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  network_configuration {
    subnets          = data.terraform_remote_state.network.outputs.private_subnet_ids
    security_groups  = [aws_security_group.task.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.frontend.arn
    container_name   = "frontend"
    container_port   = 8080
  }
}
