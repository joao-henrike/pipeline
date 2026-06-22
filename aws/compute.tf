data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "ec2_frontend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_frontend.id]
  key_name               = aws_key_pair.generated_key.key_name
  iam_instance_profile   = "LabInstanceProfile"
  user_data = templatefile("${path.module}/scripts/frontend.tftpl", {
    alb_dns = aws_lb.main_alb.dns_name
  })
  tags = { Name = "techstock-ec2-frontend" }
}

resource "aws_instance" "ec2_backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_backend.id]
  key_name               = aws_key_pair.generated_key.key_name
  iam_instance_profile   = "LabInstanceProfile"
  user_data = templatefile("${path.module}/scripts/backend.tftpl", {
    db_host     = aws_db_instance.postgres.address
    db_name     = aws_db_instance.postgres.db_name
    db_user     = aws_db_instance.postgres.username
    db_password = aws_db_instance.postgres.password
    alb_dns     = aws_lb.main_alb.dns_name
  })
  tags = { Name = "techstock-ec2-backend" }
}

resource "aws_instance" "ec2_monitoring" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sg_frontend.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = "LabInstanceProfile"

  user_data = templatefile("${path.module}/scripts/monitoring.tftpl", {
    alb_dns          = aws_lb.main_alb.dns_name
    backend_ip       = aws_instance.ec2_backend.private_ip
    grafana_password = "TechStock@2026!"
    github_raw_url   = "https://raw.githubusercontent.com/SEU_USUARIO/pipeline/main/monitoring/grafana/dashboards"
  })
  tags = { Name = "techstock-ec2-monitoring" }
}
