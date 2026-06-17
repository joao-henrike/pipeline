resource "tls_private_key" "ssh_key" { algorithm = "RSA"; rsa_bits = 4096 }
resource "aws_key_pair" "generated_key" { key_name = "chave-vms-techstock"; public_key = tls_private_key.ssh_key.public_key_openssh }

resource "aws_security_group" "sg_eice" {
  name = "endpoint-conexao"
  vpc_id = aws_vpc.main.id
  egress { from_port = 22; to_port = 22; protocol = "tcp"; cidr_blocks = ["10.1.0.0/16"] }
}

resource "aws_security_group" "sg_alb" {
  name = "techstock-alb-sg"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; cidr_blocks = ["0.0.0.0/0"] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "sg_frontend" {
  name = "frontend-ui"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 22; to_port = 22; protocol = "tcp"; security_groups = [aws_security_group.sg_eice.id] }
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; security_groups = [aws_security_group.sg_alb.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "sg_backend" {
  name = "backend-api"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 22; to_port = 22; protocol = "tcp"; security_groups = [aws_security_group.sg_eice.id] }
  ingress { from_port = 3000; to_port = 3000; protocol = "tcp"; security_groups = [aws_security_group.sg_alb.id, aws_security_group.sg_frontend.id] }
  ingress { from_port = 9100; to_port = 9100; protocol = "tcp"; cidr_blocks = ["10.1.0.0/16"] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "sg_monitoramento" {
  name = "telemetria-grafana"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 22; to_port = 22; protocol = "tcp"; security_groups = [aws_security_group.sg_eice.id] }
  ingress { from_port = 80; to_port = 80; protocol = "tcp"; security_groups = [aws_security_group.sg_alb.id] }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
}

resource "aws_security_group" "sg_database" {
  name = "rds-estoque"
  vpc_id = aws_vpc.main.id
  ingress { from_port = 5432; to_port = 5432; protocol = "tcp"; security_groups = [aws_security_group.sg_backend.id] }
}

resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id = aws_subnet.public_ec2.id
  security_group_ids = [aws_security_group.sg_eice.id]
}
