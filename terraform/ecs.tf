# ECS Cluster
resource "aws_ecs_cluster" "cluster" {
  name = "angular-devops-cluster"
}

# ECS Task Definition
resource "aws_ecs_task_definition" "angular_task" {

  family                   = "angular-devops-task"
  requires_compatibilities = ["FARGATE"]

  network_mode = "awsvpc"

  cpu    = "256"
  memory = "512"

  container_definitions = jsonencode([
    {
      name      = "angular-app"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true

      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "angular_service" {

  name            = "angular-devops-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.angular_task.arn

  desired_count = 1
  launch_type   = "FARGATE"

  network_configuration {

    subnets = [
      aws_subnet.public1.id,
      aws_subnet.public2.id
    ]

    assign_public_ip = true
  }
}