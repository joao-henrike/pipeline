data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "backend_api" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.public_ec2.id
  security_groups = [aws_security_group.sg_backend.id]
  key_name        = aws_key_pair.generated_key.key_name
  
  tags = { Name = "vm-backend-techstock" }
}
