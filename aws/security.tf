resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "chave-vms-techstock"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "aws_security_group" "sg_eice" {
  name        = "endpoint-conexao"
  description = "Permite tunel SSH interno"
  vpc_id      = aws_vpc.main.id
  egress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"]
  }
}

# ==========================================
# 1. FIREWALL DO FRONTEND (Vitrine)
# ==========================================
resource "aws_security_group" "sg_frontend" {
  name        = "frontend-ui"
  description = "Acesso de usuarios ao sistema web"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "SSH via Endpoint"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_eice.id]
  }
  
  ingress {
    description = "Trafego HTTP do mundo"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 2. FIREWALL DO BACKEND (Trancado)
# ==========================================
resource "aws_security_group" "sg_backend" {
  name        = "backend-api"
  description = "Regras restritas da API"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "SSH via Endpoint"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_eice.id]
  }
  
  ingress {
    description     = "Trafego HTTP APENAS do Frontend"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_frontend.id] # Elo de confianca
  }

  ingress {
    description = "Permite coleta de metricas do Monitoramento"
    from_port   = 9100 # Porta padrao do Node Exporter
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = ["10.1.0.0/16"] # Confia na rede interna (VPC)
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 3. FIREWALL DO MONITORAMENTO (Telemetria)
# ==========================================
resource "aws_security_group" "sg_monitoramento" {
  name        = "telemetria-grafana"
  description = "Painel de operacoes SecOps"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "SSH via Endpoint"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_eice.id]
  }
  
  ingress {
    description = "Painel Grafana web"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Painel Prometheus web"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ==========================================
# 4. FIREWALL DO RDS (Cofre)
# ==========================================
resource "aws_security_group" "sg_database" {
  name        = "rds-estoque"
  description = "Bloqueia tudo, exceto a API"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    description     = "Trafego Postgres vindo APENAS do Backend"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_backend.id]
  }
}

resource "aws_ec2_instance_connect_endpoint" "eice" {
  subnet_id          = aws_subnet.public_ec2.id
  security_group_ids = [aws_security_group.sg_eice.id]
  preserve_client_ip = false
  tags = { Name = "eice-techstock" }
}
