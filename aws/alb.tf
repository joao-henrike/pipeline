# ==========================================
# APPLICATION LOAD BALANCER
# ==========================================
resource "aws_lb" "main_alb" {
  name               = "techstock-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_subnet.id, aws_subnet.public_subnet_b.id]
  tags               = { Name = "techstock-alb" }
}

# ==========================================
# TARGET GROUPS
# ==========================================
resource "aws_lb_target_group" "tg_frontend" {
  name     = "tg-frontend"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

resource "aws_lb_target_group" "tg_backend" {
  name     = "tg-backend"
  port     = 3000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

resource "aws_lb_target_group" "tg_monitoring" {
  name     = "tg-monitoring"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
}

# ==========================================
# ANEXO DAS MAQUINAS AOS TARGET GROUPS
# ==========================================
resource "aws_lb_target_group_attachment" "frontend_attach" {
  target_group_arn = aws_lb_target_group.tg_frontend.arn
  target_id        = aws_instance.ec2_frontend.id
  port             = 80
}

resource "aws_lb_target_group_attachment" "backend_attach" {
  target_group_arn = aws_lb_target_group.tg_backend.arn
  target_id        = aws_instance.ec2_backend.id
  port             = 3000
}

resource "aws_lb_target_group_attachment" "monitoring_attach" {
  target_group_arn = aws_lb_target_group.tg_monitoring.arn
  target_id        = aws_instance.ec2_monitoring.id
  port             = 80
}

# ==========================================
# LISTENER E REGRAS DE ROTEAMENTO
# ==========================================
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Acao padrao: Mandar para o Frontend (Prioridade 4 do diagrama)
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_frontend.arn
  }
}

resource "aws_lb_listener_rule" "api_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 10 # Prioridade 1 no diagrama

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_backend.arn
  }
  condition {
    path_pattern { values = ["/api/*"] }
  }
}

resource "aws_lb_listener_rule" "grafana_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 20 # Prioridade 2 no diagrama

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_monitoring.arn
  }
  condition {
    path_pattern { values = ["/grafana/*"] }
  }
}

resource "aws_lb_listener_rule" "prometheus_rule" {
  listener_arn = aws_lb_listener.http_listener.arn
  priority     = 30 # Prioridade 3 no diagrama

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg_monitoring.arn
  }
  condition {
    path_pattern { values = ["/prometheus/*"] }
  }
}
