data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ==========================================
# 1. EC2 FRONTEND
# ==========================================
resource "aws_instance" "frontend_ui" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_ec2.id
  vpc_security_group_ids      = [aws_security_group.sg_frontend.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true
  tags = { Name = "vm-frontend-techstock" }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip python3-venv docker.io docker-compose-v2
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF
}

# ==========================================
# 2. EC2 BACKEND
# ==========================================
resource "aws_instance" "backend_api" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_ec2.id
  vpc_security_group_ids      = [aws_security_group.sg_backend.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true
  tags = { Name = "vm-backend-techstock" }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y python3 python3-pip python3-venv docker.io docker-compose-v2
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu
              EOF
}

# ==========================================
# 3. EC2 MONITORAMENTO (Com Grafana/Prometheus)
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
              apt-get install -y python3 python3-pip python3-venv docker.io docker-compose-v2
              systemctl start docker
              systemctl enable docker
              usermod -aG docker ubuntu

              # Prepara o ambiente de telemetria
              mkdir -p /opt/monitoramento
              
              # Cria a configuracao do Prometheus
              cat << 'EOT' > /opt/monitoramento/prometheus.yml
              global:
                scrape_interval: 15s
              scrape_configs:
                - job_name: 'prometheus'
                  static_configs:
                    - targets: ['localhost:9090']
              EOT

              # Cria o manifesto do Docker Compose
              cat << 'EOT' > /opt/monitoramento/docker-compose.yml
              version: '3.8'
              services:
                prometheus:
                  image: prom/prometheus:latest
                  container_name: prometheus
                  ports:
                    - "9090:9090"
                  restart: unless-stopped
                  volumes:
                    - ./prometheus.yml:/etc/prometheus/prometheus.yml
                grafana:
                  image: grafana/grafana:latest
                  container_name: grafana
                  ports:
                    - "3000:3000"
                  restart: unless-stopped
              EOT

              # Inicia os servicos
              cd /opt/monitoramento
              docker compose up -d
              EOF
}
