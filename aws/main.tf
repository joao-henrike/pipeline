terraform {
  backend "s3" {
    bucket = "techstock-tfstate-joao-7733" # O bucket do laboratório
    key    = "aws/terraform.tfstate"
    region = "us-east-1"
  }
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 5.0" }
    tls = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

provider "aws" { region = "us-east-1" }

# ==========================================
# GERAÇÃO DA CHAVE SSH
# ==========================================
resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "chave-vms-joao"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

# ==========================================
# REDE E SUBNETS
# ==========================================
resource "aws_vpc" "main" {
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "vpc-multicloud-joao" }
}

resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.1.0/24"
  availability_zone = "us-east-1a"
  tags = { Name = "subnet-privada-a-joao" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1b"
  tags = { Name = "subnet-privada-b-joao" }
}

# ==========================================
# FIREWALL (SECURITY GROUPS)
# ==========================================
resource "aws_security_group" "sg_eice" {
  name   = "sg-eice-joao"
  vpc_id = aws_vpc.main.id
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
}

resource "aws_security_group" "sg_vms" {
  name   = "sg-vms-joao"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_eice.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sg_rds" {
  name   = "sg-rds-joao"
  vpc_id = aws_vpc.main.id
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_vms.id]
  }
}

# ==========================================
# COMPUTE (EICE & EC2)
# ==========================================
resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id          = aws_subnet.private_a.id
  security_group_ids = [aws_security_group.sg_eice.id]
  preserve_client_ip = false
  tags = { Name = "eice-joao" }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_instance" "vm_aws" {
  ami             = data.aws_ami.ubuntu.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private_a.id
  security_groups = [aws_security_group.sg_vms.id]
  key_name        = aws_key_pair.generated_key.key_name
  associate_public_ip_address = false
  tags = { Name = "vm-aws-joao" }
}

# ==========================================
# STORAGE (S3 FRONTEND)
# ==========================================
resource "aws_s3_bucket" "frontend" {
  bucket = "techstock-frontend-joao"
  tags   = { Name = "bucket-frontend-joao" }
}

resource "aws_s3_bucket_website_configuration" "frontend_web" {
  bucket = aws_s3_bucket.frontend.id
  index_document { suffix = "index.html" }
}

# ==========================================
# DATABASE (RDS)
# ==========================================
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group-joao"
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
}

resource "aws_db_instance" "techstock_db" {
  identifier             = "techstock-db-joao"
  engine                 = "postgres"
  engine_version         = "15"
  instance_class         = "db.t3.micro"
  allocated_storage      = 20
  db_name                = "techstock_estoque"
  username               = "admin_joao"
  password               = "TechStock#2026!Joao"
  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.sg_rds.id]
  publicly_accessible    = false
  skip_final_snapshot    = true
  tags = { Name = "rds-banco-joao" }
}
