terraform {
  backend "s3" {
    bucket         = "eks-angular-terraform-state"
    key            = "eks-lab/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}
