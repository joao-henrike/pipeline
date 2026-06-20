# =============================================================================
# MODULO EC2 MONITORING (subnet PUBLICA)
# Instala: Docker CE + Docker Compose
# Sobe stack: Prometheus + Grafana + Alertmanager + Node Exporter + cAdvisor
# =============================================================================

data "aws_ami" "al2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "monitoring" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 40
    delete_on_termination = true
    encrypted             = true
    tags = { Name = "vol-monitoring-${var.student_name}" }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    student_name        = var.student_name
    github_repo_url     = var.github_repo_url
    backend_private_ip  = var.backend_private_ip
    frontend_private_ip = var.frontend_private_ip
    azure_vm_ip         = var.azure_vm_ip
    grafana_password    = var.grafana_password
  }))

  tags = {
    Name  = "ec2-monitoring-${var.student_name}"
    Role  = "Monitoring"
    Stack = "Prometheus+Grafana+Docker"
  }
}
