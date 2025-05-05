provider "aws" {
  region = "il-central-1"
}

locals {
  subnets = [
    "subnet-01e6348062924d048",
   "subnet-088b7d937a4cd5d85",
  ]
}

# Retrieve the DB URL from SSM Parameter Store
data "aws_ssm_parameter" "db_url" {
  name           = "/dor/tf/db-url"
  with_decryption = true
}

# Retrieve the secret value (JSON) from Secrets Manager
data "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = "rds!db-777ab260-d218-40d6-8bff-a5f247435ce3"
}

# Decode the secret JSON and extract username and password
locals {
  secret_json = jsondecode(data.aws_secretsmanager_secret_version.db_credentials.secret_string)
  db_user     = local.secret_json.username
  db_password = local.secret_json.password
}

# Data source to fetch VPC ID from subnets
data "aws_subnet" "selected_subnets" {
  id = local.subnets[0]  # Using the first subnet to get the VPC ID
}

# Create the CloudWatch Log Group
resource "aws_cloudwatch_log_group" "nginx_logs" {
  name              = "/ecs/nginx-logs"
  retention_in_days = 7  # Optional: Set retention policy (e.g., 7 days)
}

variable "image" {
  type        = string
  description = "Docker image URI to be used in ECS task"
}

# ECS Task Definition for NGINX container with CloudWatch Logs
resource "aws_ecs_task_definition" "nginx_task" {
  family                   = "nginx-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = "arn:aws:iam::314525640319:role/ecsTaskExecutionRole"  # Using the provided role

  container_definitions = jsonencode([{
    name      = "nginx"
    image     = var.image
    essential = true
    environment = [
      {
        name  = "DB_URL"
        value = data.aws_ssm_parameter.db_url.value
      },
      {
        name  = "DB_USER"
        value = local.db_user
      },
      {
        name  = "DB_PASSWORD"
        value = local.db_password
      }
    ]
    portMappings = [
      {
        containerPort = 80
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = "/ecs/nginx-logs"
        "awslogs-region"        = "il-central-1"
        "awslogs-stream-prefix" = "nginx"
      }
    }
  }])
}

# Create a new target group of type IP
resource "aws_lb_target_group" "nginx_target_group" {
  name     = "dor-target-group"
  port     = 90
  protocol = "HTTP"
  vpc_id   = data.aws_subnet.selected_subnets.vpc_id  # Fetching VPC ID from the first subnet

  target_type = "ip"
}

# Add a listener on port 90 to the existing Load Balancer 'imtech'
resource "aws_lb_listener" "nginx_listener" {
  load_balancer_arn = "arn:aws:elasticloadbalancing:il-central-1:314525640319:loadbalancer/app/imtec/dd67eee2877975d6"  # Correct the ARN here
  port              = 8083
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
  }
}

# ECS Service using Fargate and connecting to the new target group
resource "aws_ecs_service" "nginx_service" {
  name            = "dor-service"
  cluster         = "imtech"  # Existing ECS cluster
  task_definition = aws_ecs_task_definition.nginx_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = local.subnets
    security_groups = ["sg-0ac3749215afde82a"]  # Replace with your security group ID
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.nginx_target_group.arn
    container_name   = "nginx"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.nginx_listener
  ]
}

