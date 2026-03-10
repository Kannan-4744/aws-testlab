resource "aws_lb" "alb" {

 name = "angular-devops-alb"

 internal = false

 load_balancer_type = "application"

 subnets = [
  aws_subnet.public1.id,
  aws_subnet.public2.id
 ]
}