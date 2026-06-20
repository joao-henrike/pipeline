# =============================================================================
# MODULO SECURITY GROUPS
# sg-frontend   → EC2 Frontend (HTTP 80, Node 3000, SSH 22)
# sg-backend    → EC2 Backend privada (API 8000, node_exporter 9100)
# sg-monitoring → EC2 Monitoring (Grafana 3000, Prometheus 9090)
# =============================================================================

resource "aws_security_group" "frontend" {
  name        = "sg-frontend-${var.student_name}"
  description = "Frontend EC2: HTTP publico + SSH admin"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP Nginx"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Node.js dev server"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "Node Exporter (Prometheus)"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-frontend-${var.student_name}" }
}

resource "aws_security_group" "backend" {
  name        = "sg-backend-${var.student_name}"
  description = "Backend EC2: FastAPI + node_exporter + trafego Azure VPN"
  vpc_id      = var.vpc_id

  ingress {
    description = "FastAPI da VPC (frontend → backend)"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "FastAPI do Azure via VPN"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = [var.azure_vnet_cidr]
  }
  ingress {
    description = "SSH via VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "SSH do Azure via VPN"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.azure_vnet_cidr]
  }
  ingress {
    description = "ICMP ping do Azure via VPN"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.azure_vnet_cidr]
  }
  ingress {
    description = "ICMP ping interno VPC"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [var.vpc_cidr]
  }
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-backend-${var.student_name}" }
}

resource "aws_security_group" "monitoring" {
  name        = "sg-monitoring-${var.student_name}"
  description = "Monitoring EC2: Grafana 3000 + Prometheus 9090 + Alertmanager 9093"
  vpc_id      = var.vpc_id

  ingress {
    description = "Grafana dashboard"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "Prometheus UI"
    from_port   = 9090
    to_port     = 9090
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "Alertmanager UI"
    from_port   = 9093
    to_port     = 9093
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "cAdvisor UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "SSH admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.admin_ip_cidrs
  }
  ingress {
    description = "Node Exporter"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "sg-monitoring-${var.student_name}" }
}
