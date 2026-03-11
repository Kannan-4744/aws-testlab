resource "aws_eks_cluster" "eks_cluster" {

  name = var.cluster_name

  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {

    subnet_ids = [
      aws_subnet.private1.id,
      aws_subnet.private2.id
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_policy
  ]
}