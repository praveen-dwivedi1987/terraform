resource "aws_lb" "jenkins-lb" {
  provider = aws.region-master
  name               = "jenkins-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb-sg]
  subnets            = [aws_subnet.subnet_1, aws_subnet.subnet_2]

  tags = {
    Environment = "production"
  }
}


resource "aws_lb_target_group" "jenkins-tg" {
  provider = aws.region-master
  name     = "tf-example-lb-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_master
  health_check {
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200-299, 400-499"
    path                = "/"
    port                = 8080
    protocol            = "HTTP"
    unhealthy_threshold = 2


  }
}

resource "aws_lb_listener" "alb_listener" {
  provider = aws.region-master
  load_balancer_arn = aws_lb.jenkins-lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.jenkins-tg.arn
  }
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
    provider = aws.region-master
  target_group_arn = aws_lb_target_group.jenkins-tg.arn
  target_id        = aws_instance.jenkins-master.id
  port             = 8080
}

