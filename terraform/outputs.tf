output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_1" {
  description = "Public Subnet 1"
  value       = aws_subnet.public1.id
}

output "public_subnet_2" {
  description = "Public Subnet 2"
  value       = aws_subnet.public2.id
}

output "internet_gateway_id" {
  description = "Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "ecr_repository_url" {
  description = "ECR Repository URL"
  value       = aws_ecr_repository.repo.repository_url
}

output "ecs_cluster_name" {
  description = "ECS Cluster"
  value       = aws_ecs_cluster.cluster.name
}

output "load_balancer_dns" {
  description = "ALB DNS"
  value       = aws_lb.alb.dns_name
}
output "ecs_service_name" {
  value = aws_ecs_service.angular_service.name
}

