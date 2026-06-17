data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "backend_api" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_ec2.id
  vpc_security_group_ids      = [aws_security_group.sg_backend.id]
  key_name                    = aws_key_pair.generated_key.key_name
  
  # Parâmetros obrigatórios para o ambiente AWS Academy
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true

  tags = { Name = "vm-backend-techstock" }
}
