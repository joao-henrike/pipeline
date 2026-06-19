# Subnet publica na Zona B obrigatoria para o ALB
resource "aws_subnet" "public_ec2_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-public-b-techstock" }
}

# ==========================================
# CORRECAO: Rastreamento dinamico da Tabela de Rotas
# ==========================================

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_ec2_b.id
  route_table_id = aws_route_table.public_rt.id
}

# ==========================================
# APPLICATION LOAD BALANCER
# ==========================================
resource "aws_lb" "main_alb" {
  name               = "techstock-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_ec2.id, aws_subnet.public_ec2_b.id]
}

# ==========================================
# TARGET GROUPS (Destinos)
# ==========================================
resource "aws_lb_target_group" "frontend_tg" {
  name     = "tg-frontend-techstock"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { 
    path = "/health" 
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "tg-backend-techstock"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { 
    path = "/api/health" 
  }
}

resource "aws_lb_target_group" "monitoring_tg" {
  name     = "tg-monitoring-techstock"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  health_check { 
    path = "/grafana/api/health" 
  }
}

# Fixando a maquina de monitoramento no Target Group
resource "aws_lb_target_group_attachment" "monitoring_attach" {
  target_group_arn = aws_lb_target_group.monitoring_tg.arn
  target_id        = aws_instance.monitoramento.id
  port             = 80
}

# ==========================================
# REGRAS DO LISTENER
# ==========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "grafana_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring_tg.arn
  }
  condition { 
    path_pattern { 
      values = ["/grafana*"] 
    } 
  }
}

resource "aws_lb_listener_rule" "prometheus_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 20
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.monitoring_tg.arn
  }
  condition { 
    path_pattern { 
      values = ["/prometheus*"] 
    } 
  }
}

resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 30
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
  condition { 
    path_pattern { 
      values = ["/api*"] 
    } 
  }
}
