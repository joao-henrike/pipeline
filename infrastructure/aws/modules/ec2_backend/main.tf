# =============================================================================
# MODULO EC2 BACKEND (subnet PRIVADA)
# Instala: Python 3.x + pip + Docker CE + Docker Compose + Node Exporter
# Clona o repositorio e sobe o backend FastAPI via uvicorn (systemd) e Docker.
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

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.al2.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.sg_id]
  key_name               = var.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
    tags = { Name = "vol-backend-${var.student_name}" }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    student_name    = var.student_name
    github_repo_url = var.github_repo_url
    aws_region      = var.aws_region
    azure_vm_ip     = var.azure_vm_ip
    monitoring_ip   = var.monitoring_ip
    cloud_provider  = "AWS"
  }))

  tags = {
    Name  = "ec2-backend-${var.student_name}"
    Role  = "Backend"
    Stack = "Docker+Python+FastAPI"
  }
}
