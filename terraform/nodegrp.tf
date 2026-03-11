resource "aws_eks_node_group" "node_group" {

  cluster_name = aws_eks_cluster.eks_cluster.name

  node_group_name = "angular-node-group"

  node_role_arn = aws_iam_role.node_role.arn

  subnet_ids = [
    aws_subnet.private1.id,
    aws_subnet.private2.id
  ]

  instance_types = [var.node_instance_type]

  scaling_config {

    desired_size = 2
    min_size     = 1
    max_size     = 3
  }
}