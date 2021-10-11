# Backend setup
terraform {
  backend "s3" {
    key = "img-mgr.tfstate"
  }
}

# Provider and access setup
provider "aws" {
  version = ">= 3.62.0"
  region = "${var.region}"
}
# These are data and resources
data "terraform_remote_state" "vpc-ref" {
  backend = "s3"
  config = {
    bucket = "matt1069-img-mgr-vpc-tf-stat-terraformstatebucket-yli8s8b780v4"
    region = "us-east-1"
    key = "env:/vpc/vpc.tfstate"
  }
}

resource "aws_s3_bucket" "imgr-mgr-bucket" {
  bucket = "${var.bucket}"
  acl = "private"
}


resource "aws_iam_role" "img-mgr-iam-role" {
  name = "img-mgr-role-v2"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "img-mgr-iam-policy" {
  name = "img-mgr-server-policy"
  role = aws_iam_role.img-mgr-iam-role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_s3_bucket.imgr-mgr-bucket.arn}",
        "${aws_s3_bucket.imgr-mgr-bucket.arn}/*"
        ]
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "img-mgr-instance-profile" {
  name = "img-mgr-instance-profilev2"
  role = aws_iam_role.img-mgr-iam-role.name
}

resource "aws_iam_policy_attachment" "iam-attach" {
  name       = "test-attachment"
  roles      = [aws_iam_role.img-mgr-iam-role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
}

resource "aws_security_group" "LbSg" {
  name        = "lb_sg_80"
  description = "Allow http,ssh,icmp"
  vpc_id = data.terraform_remote_state.vpc-ref.outputs.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "myweb_sg"
  }
}

resource "aws_security_group" "serverSG" {
  name        = "server_sg"
  description = "Allow http,ssh,icmp"
  vpc_id      = data.terraform_remote_state.vpc-ref.outputs.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [
      aws_security_group.LbSg.id
    ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "myweb_sg"
  }
}

resource "aws_elb" "img-mgr-lb" {
  name               = "img-mgr-lb"
  subnets            = data.terraform_remote_state.vpc-ref.outputs.public_subnets

 listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  security_groups    = [ aws_security_group.LbSg.id ]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "img-mgr-elb"
  }
}

resource "aws_launch_template" "img-mgr-launch-temp" {
  name = "TOP-keys"
  image_id = "${var.ami}"
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.small"
  key_name = "TOP-keys"
  update_default_version = true
  vpc_security_group_ids = [aws_security_group.serverSG.id]
  iam_instance_profile {
    name = aws_iam_instance_profile.img-mgr-instance-profile.name
  }
  user_data = base64encode(templatefile("${path.module}/img-mgr.sh", { S3Bucket = aws_s3_bucket.imgr-mgr-bucket.id }))
}

resource "aws_autoscaling_group" "img-mgr-asg" {
  vpc_zone_identifier = data.terraform_remote_state.vpc-ref.outputs.private_subnets
  desired_capacity   = 2
  max_size           = 2
  min_size           = 2
  load_balancers = [ aws_elb.img-mgr-lb.name ]
  launch_template {
    id      = aws_launch_template.img-mgr-launch-temp.id
    version = "$Latest"
  }
}
