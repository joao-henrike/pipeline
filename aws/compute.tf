data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
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
  iam_instance_profile   = "LabInstanceProfile" # Bypass do Vocareum para CloudWatch
  tags                   = { Name = "techstock-ec2-frontend" }
}

resource "aws_instance" "ec2_backend" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_backend.id]
  key_name               = aws_key_pair.generated_key.key_name
  iam_instance_profile   = "LabInstanceProfile" # Bypass do Vocareum para CloudWatch
  tags                   = { Name = "techstock-ec2-backend" }
}

resource "aws_instance" "ec2_monitoring" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.sg_frontend.id]
  key_name               = aws_key_pair.generated_key.key_name
  iam_instance_profile   = "LabInstanceProfile" # Bypass do Vocareum para CloudWatch
  tags                   = { Name = "techstock-ec2-monitoring" }
}
