# Sub-rede publica obrigatoria na Zona de Disponibilidade B para o ALB
resource "aws_subnet" "public_ec2_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.1.10.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  tags                    = { Name = "subnet-public-b-techstock" }
}

# Vincula a nova sub-rede a tabela de rotas publica existente
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_ec2_b.id
  route_table_id = aws_subnet.public_ec2.map_public_ip_on_launch ? aws_subnet.public_ec2.id : aws_subnet.public_ec2.id 
  # O Terraform herdara a associacao correta da infraestrutura de rede basica
}

# ==========================================
# APPLICATION LOAD BALANCER (ALB)
# ==========================================
resource "aws_lb" "main_alb" {
  name               = "techstock-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_ec2.id, aws_subnet.public_ec2_b.id]

  tags = { Name = "alb-techstock" }
}

# ==========================================
# TARGET GROUPS (Grupos de Destino)
# ==========================================
resource "aws_lb_target_group" "frontend_tg" {
  name     = "tg-frontend-techstock"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 20
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name     = "tg-backend-techstock"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/produtos" # Rota base do nosso CRUD
    port                = "80"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 20
  }
}

# ==========================================
# LISTENER E REGRAS DE ROTEAMENTO
# ==========================================
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main_alb.arn
  port              = "80"
  protocol          = "HTTP"

  # Regra padrao (Catch-all): Envia tráfego para a interface visual
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
}

resource "aws_lb_listener_rule" "api_routing" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }

  # Se o usuario tentar acessar /produtos, o ALB desvia para o Backend
  condition {
    path_pattern {
      values = ["/produtos", "/produtos/*"]
    }
  }
}
