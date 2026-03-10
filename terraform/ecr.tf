resource "aws_ecr_repository" "repo" {

 name = "angular-devops-repo"

 image_tag_mutability = "MUTABLE"
}