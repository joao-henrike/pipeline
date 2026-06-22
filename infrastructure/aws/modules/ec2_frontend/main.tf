# =============================================================================
# MODULO EC2 FRONTEND (subnet PUBLICA)
# Instala: Node.js 20 LTS + Nginx + Git + PM2
# Clona o repositorio GitHub e serve o dashboard na porta 80 via Nginx.
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

resource "aws_instance" "frontend" {
  ami                         = data.aws_ami.al2.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.sg_id]
  key_name                    = var.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    tags                  = { Name = "vol-frontend-${var.student_name}" }
  }

  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    student_name       = var.student_name
    github_repo_url    = var.github_repo_url
    backend_private_ip = var.backend_private_ip
  }))

  tags = {
    Name  = "ec2-frontend-${var.student_name}"
    Role  = "Frontend"
    Stack = "Node.js+Nginx"
  }
}
