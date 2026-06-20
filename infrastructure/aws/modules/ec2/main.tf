data "aws_ami" "amazon_linux_2" {
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

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_key" {
  key_name   = "key-multicloud-${var.student_name}"
  public_key = tls_private_key.ec2_key.public_key_openssh
  tags       = { Name = "key-multicloud-${var.student_name}" }
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.ec2_key.private_key_pem
  filename        = "${path.root}/keys/key-multicloud-${var.student_name}.pem"
  file_permission = "0400"
}

resource "aws_instance" "private" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = var.ec2_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.ec2_sg_id]
  key_name               = aws_key_pair.ec2_key.key_name

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
    tags                  = { Name = "vol-ec2-private-${var.student_name}" }
  }

  user_data = base64encode(templatefile("${path.module}/userdata_ec2.sh", {
    student_name = var.student_name
  }))

  tags = {
    Name = "ec2-private-${var.student_name}"
    Role = "VPN-Target-Backend"
  }
}

resource "aws_instance" "bastion" {
  count                       = var.create_bastion ? 1 : 0
  ami                         = data.aws_ami.amazon_linux_2.id
  instance_type               = var.bastion_instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [var.bastion_sg_id]
  key_name                    = aws_key_pair.ec2_key.key_name
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    delete_on_termination = true
    encrypted             = true
    tags                  = { Name = "vol-bastion-${var.student_name}" }
  }

  user_data = base64encode(<<-EOF
    #!/bin/bash
    hostnamectl set-hostname "bastion-${var.student_name}"
    yum update -y
    yum install -y net-tools traceroute tcpdump nmap-ncat
  EOF
  )

  tags = {
    Name = "ec2-bastion-${var.student_name}"
    Role = "Bastion"
  }
}
