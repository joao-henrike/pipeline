data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# ==========================================
# 1. FRONTEND: LAUNCH TEMPLATE & AUTO SCALING
# ==========================================
resource "aws_launch_template" "frontend_lt" {
  name_prefix   = "frontend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_frontend.id]
  }

  iam_instance_profile { name = "LabInstanceProfile" }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > >(tee /var/log/techstock-boot.log | logger -t user-data -s 2>/dev/console) 2>&1
set -e
exec > >(tee /var/log/user-data-frontend.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "============================================"
echo " TechStock — Setup Frontend Automatizado"
echo "============================================"

AWS_REGION="us-east-1"
SECRET_NAME="techstock/frontend"
WEBROOT="/usr/share/nginx/html/techstock"
NODE_EXPORTER_VERSION="1.7.0"

# Interpolação direta do DNS do ALB gerado pelo Terraform
ALB_DNS="${aws_lb.main_alb.dns_name}"
GITHUB_BASE="https://raw.githubusercontent.com/seu-usuario/seu-repositorio/main/frontend"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx wget curl python3

cat > /etc/nginx/nginx.conf << 'NGXMAIN'
user www-data;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;
include /etc/nginx/modules-enabled/*.conf;
events { worker_connections 1024; }
http {
    log_format main '$$remote_addr - $$remote_user [$$time_local] "$$request" $$status $$body_bytes_sent';
    access_log /var/log/nginx/access.log main;
    sendfile on; tcp_nopush on; keepalive_timeout 65;
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    include /etc/nginx/conf.d/*.conf;
}
NGXMAIN

mkdir -p $$WEBROOT
chown -R www-data:www-data $$WEBROOT; chmod -R 755 $$WEBROOT

for f in index.html style.css app.js config.js; do
  wget -q -O $$WEBROOT/$$f "$$GITHUB_BASE/$$f" || true
done
chown -R www-data:www-data $$WEBROOT/; chmod -R 755 $$WEBROOT/

cat > $$WEBROOT/config.js << CFG
// config.js — gerado automaticamente via Terraform
window.TECHSTOCK_CONFIG = { apiUrl: 'http://$$ALB_DNS' };
CFG
chown www-data:www-data $$WEBROOT/config.js; chmod 644 $$WEBROOT/config.js

cat > /etc/nginx/conf.d/techstock.conf << 'NGINX'
server {
    listen 80 default_server;
    server_name _;
    root  /usr/share/nginx/html/techstock;
    index index.html;
    location = /config.js {
        add_header Cache-Control "no-store, no-cache, must-revalidate";
        add_header Pragma "no-cache"; expires -1;
    }
    location / {
        try_files $$uri $$uri/ /index.html;
        add_header Cache-Control "no-cache";
        add_header X-Frame-Options "SAMEORIGIN";
    }
    location ~* \.(css|js)$$ { expires 1h; add_header Cache-Control "public, max-age=3600"; }
    location = /health {
        default_type application/json;
        return 200 '{"ok":true,"service":"frontend-nginx"}';
    }
    access_log /var/log/nginx/techstock-access.log main;
    error_log  /var/log/nginx/techstock-error.log;
}
NGINX

rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx
systemctl restart nginx

wget -q "https://github.com/prometheus/node_exporter/releases/download/v$$NODE_EXPORTER_VERSION/node_exporter-$$NODE_EXPORTER_VERSION.linux-amd64.tar.gz" -O /tmp/ne.tar.gz
tar xzf /tmp/ne.tar.gz -C /tmp/
cp /tmp/node_exporter-$$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << 'NE'
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NE

wget -q https://amazoncloudwatch-agent.s3.amazonaws.com/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
dpkg -i -E ./amazon-cloudwatch-agent.deb

cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'CW'
{
  "logs": { "logs_collected": { "files": { "collect_list": [
    { "file_path": "/var/log/nginx/techstock-access.log", "log_group_name": "/techstock/nginx-access", "log_stream_name": "{instance_id}" },
    { "file_path": "/var/log/nginx/techstock-error.log",  "log_group_name": "/techstock/nginx-error",  "log_stream_name": "{instance_id}" }
  ]}}},
  "metrics": { "namespace": "TechStock/Frontend", "metrics_collected": {
    "cpu": { "measurement": ["cpu_usage_active"], "metrics_collection_interval": 60 },
    "mem": { "measurement": ["mem_used_percent"],  "metrics_collection_interval": 60 }
  }}
}
CW

systemctl daemon-reload
systemctl enable node_exporter amazon-cloudwatch-agent
systemctl start  node_exporter amazon-cloudwatch-agent
echo "Setup Frontend Concluido!"
EOF
  )
}

resource "aws_autoscaling_group" "frontend_asg" {
  name                = "asg-frontend-techstock"
  vpc_zone_identifier = [aws_subnet.public_ec2.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  target_group_arns   = [aws_lb_target_group.frontend_tg.arn]

  launch_template {
    id      = aws_launch_template.frontend_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "frontend_scale_up" {
  name                   = "frontend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.frontend_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}

# ==========================================
# 2. BACKEND: LAUNCH TEMPLATE & AUTO SCALING
# ==========================================
resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  key_name      = aws_key_pair.generated_key.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.sg_backend.id]
  }

  iam_instance_profile { name = "LabInstanceProfile" }

  user_data = base64encode(<<-EOF
#!/bin/bash
exec > >(tee /var/log/techstock-boot.log | logger -t user-data -s 2>/dev/console) 2>&1
set -e
exec > >(tee /var/log/user-data-backend.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "============================================"
echo " TechStock — Setup Backend Automatizado"
echo "============================================"

AWS_REGION="us-east-1"
SECRET_NAME="techstock/backend"
APP_DIR="/opt/techstock"
NODE_EXPORTER_VERSION="1.7.0"

# Captura automatica do endpoint do banco RDS
DB_HOST="${aws_db_instance.estoque_db.endpoint}"
DB_HOST=$$${DB_HOST%:*}

GITHUB_BASE="https://raw.githubusercontent.com/seu-usuario/seu-repositorio/main/backend"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y curl dirmngr apt-transport-https lsb-release ca-certificates wget postgresql-client
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

useradd -r -m -d $$APP_DIR -s /bin/bash techstock 2>/dev/null || true
mkdir -p $$APP_DIR/public

for f in server.js package.json schema.sql; do
  wget -q -O $$APP_DIR/$$f "$$GITHUB_BASE/$$f" || true
done
cd $$APP_DIR && npm install --omit=dev

cat > $$APP_DIR/.env << ENV
TECHSTOCK_SECRET_NAME=$$SECRET_NAME
AWS_REGION=$$AWS_REGION
ENV
chown techstock:techstock $$APP_DIR/.env
chmod 640 $$APP_DIR/.env
chown -R techstock:techstock $$APP_DIR
chmod 755 $$APP_DIR

cat > /etc/systemd/system/techstock.service << SVC
[Unit]
Description=TechStock Backend API
After=network.target

[Service]
Type=simple
User=techstock
WorkingDirectory=$$APP_DIR
EnvironmentFile=$$APP_DIR/.env
ExecStart=/usr/bin/node server.js
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=techstock

[Install]
WantedBy=multi-user.target
SVC
systemctl daemon-reload
systemctl enable techstock
systemctl start techstock

wget -q "https://github.com/prometheus/node_exporter/releases/download/v$$NODE_EXPORTER_VERSION/node_exporter-$$NODE_EXPORTER_VERSION.linux-amd64.tar.gz" -O /tmp/ne.tar.gz
tar xzf /tmp/ne.tar.gz -C /tmp/
cp /tmp/node_exporter-$$NODE_EXPORTER_VERSION.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

cat > /etc/systemd/system/node_exporter.service << NE
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
NE
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

echo "Setup Concluido!"
EOF
  )
}

resource "aws_autoscaling_group" "backend_asg" {
  name                = "asg-backend-techstock"
  vpc_zone_identifier = [aws_subnet.public_ec2.id]
  desired_capacity    = 1
  min_size            = 1
  max_size            = 3
  target_group_arns   = [aws_lb_target_group.backend_tg.arn]

  launch_template {
    id      = aws_launch_template.backend_lt.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "backend_scale_up" {
  name                   = "backend-cpu-tracking"
  autoscaling_group_name = aws_autoscaling_group.backend_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification { predefined_metric_type = "ASGAverageCPUUtilization" }
    target_value = 70.0
  }
}

# ==========================================
# 3. MONITORAMENTO: INSTÂNCIA FIXA (NÓ DE TELEMETRIA)
# ==========================================
resource "aws_instance" "monitoramento" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_ec2.id
  vpc_security_group_ids      = [aws_security_group.sg_monitoramento.id]
  key_name                    = aws_key_pair.generated_key.key_name
  iam_instance_profile        = "LabInstanceProfile"
  associate_public_ip_address = true
  tags = { Name = "vm-monitoramento-techstock" }

  # Utilizamos <<-EOF para permitir injeção de variáveis do Terraform.
  # Variáveis do Bash estão escapadas com $$ para não quebrar a compilação.
  user_data = base64encode(<<-EOF
#!/bin/bash
# ==========================================
# ARMADURA DE LOG EXTREMO
# ==========================================
exec > >(tee /var/log/techstock-boot.log | logger -t user-data -s 2>/dev/console) 2>&1
set -e

echo "Iniciando provisionamento do Nó de Telemetria..."
export DEBIAN_FRONTEND=noninteractive

# Variáveis globais
GRAFANA_PASSWORD="TechStock@2024"
PROMETHEUS_VERSION="2.51.2"
NODE_EXPORTER_VERSION="1.7.0"

# --- [1/5] Atualização e Ferramentas Base ---
apt-get update -y
apt-get install -y wget curl tar nginx apt-transport-https software-properties-common

# --- [2/5] Prometheus & Node Exporter ---
echo "Instalando Node Exporter..."
wget -q "https://github.com/prometheus/node_exporter/releases/download/v$${NODE_EXPORTER_VERSION}/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz" -O /tmp/ne.tar.gz
tar xzf /tmp/ne.tar.gz -C /tmp/
mv /tmp/node_exporter-$${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/

cat > /etc/systemd/system/node_exporter.service << 'SVC'
[Unit]
Description=Node Exporter
[Service]
ExecStart=/usr/local/bin/node_exporter
Restart=always
[Install]
WantedBy=multi-user.target
SVC
systemctl enable node_exporter --now

echo "Instalando Prometheus..."
useradd --no-create-home --shell /bin/false prometheus || true
mkdir -p /etc/prometheus /var/lib/prometheus
wget -q "https://github.com/prometheus/prometheus/releases/download/v$${PROMETHEUS_VERSION}/prometheus-$${PROMETHEUS_VERSION}.linux-amd64.tar.gz" -O /tmp/prom.tar.gz
tar xzf /tmp/prom.tar.gz -C /tmp/
mv /tmp/prometheus-$${PROMETHEUS_VERSION}.linux-amd64/prometheus /usr/local/bin/
mv /tmp/prometheus-$${PROMETHEUS_VERSION}.linux-amd64/promtool /usr/local/bin/

# Configuração do Prometheus com Roteamento Externo para o Nginx Proxy
cat > /etc/prometheus/prometheus.yml << 'PROM'
global:
  scrape_interval: 15s
scrape_configs:
  - job_name: 'prometheus'
    metrics_path: /prometheus/metrics
    static_configs:
      - targets: ['localhost:9090']
  - job_name: 'node-exporter-monitoring'
    static_configs:
      - targets: ['localhost:9100']
  - job_name: 'techstock-backend-asg'
    aws_sd_configs:
      - region: us-east-1
        port: 9100
    relabel_configs:
      - source_labels: [__meta_ec2_tag_Name]
        regex: vm-backend-techstock
        action: keep
PROM

chown -R prometheus:prometheus /etc/prometheus /var/lib/prometheus

cat > /etc/systemd/system/prometheus.service << 'SVC'
[Unit]
Description=Prometheus
[Service]
User=prometheus
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/var/lib/prometheus \
  --web.external-url=/prometheus \
  --web.route-prefix=/prometheus
Restart=always
[Install]
WantedBy=multi-user.target
SVC
systemctl enable prometheus --now

# --- [3/5] Instalação do Grafana ---
echo "Instalando Grafana..."
mkdir -p /etc/apt/keyrings/
wget -q -O - https://apt.grafana.com/gpg.key | gpg --dearmor | tee /etc/apt/keyrings/grafana.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/grafana.gpg] https://apt.grafana.com stable main" | tee /etc/apt/sources.list.d/grafana.list
apt-get update -y
apt-get install -y grafana

cat > /etc/grafana/grafana.ini << GINI
[server]
root_url = %(protocol)s://%(domain)s/grafana/
serve_from_sub_path = true
[security]
admin_user = admin
admin_password = $${GRAFANA_PASSWORD}
allow_embedding = true
[analytics]
reporting_enabled = false
GINI

# --- [4/5] Provisionamento Nativo (GitOps) de Dashboards ---
# Substitui o script Python falho pela inteligência nativa do Grafana
echo "Configurando Provisionamento Automático..."
mkdir -p /etc/grafana/provisioning/datasources
mkdir -p /etc/grafana/provisioning/dashboards
mkdir -p /var/lib/grafana/dashboards

cat > /etc/grafana/provisioning/datasources/prometheus.yaml << 'DS'
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://localhost:9090/prometheus
    isDefault: true
    uid: PBFA97CFB590B2093
DS

cat > /etc/grafana/provisioning/dashboards/default.yaml << 'DASH'
apiVersion: 1
providers:
  - name: 'TechStock'
    orgId: 1
    folder: ''
    type: file
    disableDeletion: false
    updateIntervalSeconds: 10
    options:
      path: /var/lib/grafana/dashboards
DASH

# Baixa os dashboards diretamente do seu repositório para a pasta de leitura
REPO_URL="https://raw.githubusercontent.com/seu-usuario/seu-repositorio/main/monitoring"
wget -q "$${REPO_URL}/dashboard_techstock-observability.json" -O /var/lib/grafana/dashboards/observability.json || true
wget -q "$${REPO_URL}/dashboard_techstock-infra-ec2.json" -O /var/lib/grafana/dashboards/infra.json || true

chown -R grafana:grafana /etc/grafana/provisioning/ /var/lib/grafana/dashboards/
systemctl enable grafana-server --now

# --- [5/5] Proxy Reverso (Nginx) & Health Check Blindado ---
echo "Configurando Nginx Proxy..."
cat > /etc/nginx/conf.d/techstock-monitoring.conf << 'NGXCONF'
server {
    listen 80;
    server_name _;

    # Rota raiz salva a vida da máquina: O ALB bate aqui e recebe um 200 OK
    location / {
        return 200 "TechStock Telemetry Node Healthy\n";
        add_header Content-Type text/plain;
    }

    # Roteamento Grafana
    location /grafana/ {
        proxy_pass http://127.0.0.1:3000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Roteamento Prometheus
    location /prometheus/ {
        proxy_pass http://127.0.0.1:9090/prometheus/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
NGXCONF

rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

echo "Provisionamento da Telemetria concluído com sucesso."
EOF
  )
}
