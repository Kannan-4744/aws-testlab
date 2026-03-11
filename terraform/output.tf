output "cluster_name" {

  value = aws_eks_cluster.eks_cluster.name
}

output "cluster_endpoint" {

  value = aws_eks_cluster.eks_cluster.endpoint
}

output "ecr_repository_url" {

  value = aws_ecr_repository.app_repo.repository_url
}