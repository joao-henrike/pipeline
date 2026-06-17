data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ==========================================
# 1. FRONTEND WITH TARGET GROUP
# ==========================================
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "frontend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_frontend.id]
  }

  iam_instance_profile { name = "LabInstanceProfile" }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip docker.io docker-compose-v2
              systemctl start docker && systemctl enable docker
              usermod -aG docker ubuntu
              EOF
  )
}

resource "aws_autoscaling_group" "frontend_asg" {
  name                = "asg-frontend-techstock"
  vpc_zone_identifier = [aws_subnet.public_ec2.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  
  # Conexao com o Load Balancer
  target_group_arns   = [aws_lb_target_group.frontend_tg.arn]

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "frontend_scale_up" {
  name                   = "frontend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}

# ==========================================
# 2. BACKEND WITH TARGET GROUP
# ==========================================
resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_backend.id]
  }

  iam_instance_profile { name = "LabInstanceProfile" }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip docker.io docker-compose-v2
              systemctl start docker && systemctl enable docker
              usermod -aG docker ubuntu
              EOF
  )
}

resource "aws_autoscaling_group" "backend_asg" {
  name                = "asg-backend-techstock"
  vpc_zone_identifier = [aws_subnet.public_ec2.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  
  # Conexao com o Load Balancer
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "backend_scale_up" {
  name                   = "backend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}

# ==========================================
# 3. MONITORAMENTO (FIXO)
# ==========================================
resource "aws_instance" "monitoramento" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_ec2.id
  vpc_security_group_ids      = [aws_security_group.sg_monitoramento.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true
  tags = { Name = "vm-monitoramento-techstock" }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip docker.io docker-compose-v2
              systemctl start docker && systemctl enable docker
              usermod -aG docker ubuntu

              mkdir -p /opt/monitoramento
              cat << 'EOT' > /opt/monitoramento/prometheus.yml
              global: { scrape_interval: 15s }
              scrape_configs:
                - job_name: 'prometheus'
                  static_configs: [ { targets: ['localhost:9090'] } ]
              EOT

              cat << 'EOT' > /opt/monitoramento/docker-compose.yml
              version: '3.8'
              services:
                prometheus:
                  image: prom/prometheus:latest
                  ports: ["9090:9090"]
                  volumes: ["./prometheus.yml:/etc/prometheus/prometheus.yml"]
                grafana:
                  image: grafana/grafana:latest
                  ports: ["3000:3000"]
              EOT

              cd /opt/monitoramento && docker compose up -d
              EOF
}
