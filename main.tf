provider "aws" {
  region = "us-east-2"
  access_key = ""
  secret_key = ""
}


# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get subnets from default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group
resource "aws_security_group" "mail_sg" {
  name        = "jenkins-mail-sg"
  description = "Security group for Jenkins EC2 Auto Scaling"
  vpc_id      = data.aws_vpc.default.id

  # SSH
  ingress {
    description = "SSH"
    from_port  = 22
    to_port    = 22
    protocol   = "tcp"
    cidr_blocks = ["49.43.225.171/32"]
  }

  # Jenkins
  ingress {
    description = "Jenkins"
    from_port  = 8080
    to_port    = 8080
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application
  ingress {
    description = "Application"
    from_port  = 9090
    to_port    = 9090
    protocol   = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound
  egress {
    from_port  = 0
    to_port    = 0
    protocol   = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-mail-sg"
  }
}

# AWS Key Pair
resource "aws_key_pair" "my_keypair" {
  key_name   = "my-keypair"
  public_key = file("${path.module}/mail-key.pem.pub")
}

# Launch Template
resource "aws_launch_template" "jenkins_lt" {
  name_prefix   = "jenkins-mail-lt-"
  image_id     = "ami-01e4a7224fcbfe81f"
  instance_type = "t3.large"

  key_name = aws_key_pair.my_keypair.key_name

  vpc_security_group_ids = [
    aws_security_group.mail_sg.id
  ]

  # Install Java 21 and Jenkins
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -eux

    dnf install -y java-21-amazon-corretto-devel fontconfig wget

    wget -O /etc/yum.repos.d/jenkins.repo \
      https://pkg.jenkins.io/rpm-stable/jenkins.repo

    rpm --import https://pkg.jenkins.io/rpm-stable/jenkins.io-2026.key

    dnf install -y jenkins

    systemctl enable jenkins
    systemctl start jenkins
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "jenkins-mail-asg"
    }
  }

  tag_specifications {
    resource_type = "volume"

    tags = {
      Name = "jenkins-mail-asg-volume"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "jenkins_asg" {
  name = "jenkins-mail-asg"

  min_size         = 1
  desired_capacity  = 1
  max_size          = 3

  vpc_zone_identifier = data.aws_subnets.default.ids

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.jenkins_lt.id
    version = "$Latest"
  }

  # Tags for launched instances
  tag {
    key                 = "Name"
    value               = "jenkins-mail-asg"
    propagate_at_launch = true
  }
}

# CPU Target Tracking Scaling Policy
resource "aws_autoscaling_policy" "cpu_scaling" {
  name                   = "jenkins-cpu-scaling"
  autoscaling_group_name  = aws_autoscaling_group.jenkins_asg.name
  policy_type             = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = 70.0
  }
}

# Outputs
output "autoscaling_group_name" {
  value = aws_autoscaling_group.jenkins_asg.name
}

output "launch_template_id" {
  value = aws_launch_template.jenkins_lt.id
}

output "subnet_ids" {
  value = data.aws_subnets.default.ids
}
