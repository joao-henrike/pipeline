#!/bin/bash
# =============================================================================
# USERDATA — EC2 MONITORING
# Instala Docker, Docker Compose e sobe o stack Prometheus + Grafana
# =============================================================================
set -euo pipefail
exec > /var/log/userdata-monitoring.log 2>&1

echo "========================================"
echo " EC2 MONITORING SETUP — $(date)"
echo " Aluno: ${student_name}"
echo "========================================"

# ── 1. Hostname
hostnamectl set-hostname "ec2-monitoring-${student_name}"

# ── 2. Atualizar sistema
echo "[1/7] Atualizando sistema..."
yum update -y
yum install -y git curl wget unzip net-tools

# ── 3. Instalar Docker CE
echo "[2/7] Instalando Docker CE..."
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user

# ── 4. Instalar Docker Compose v2
echo "[3/7] Instalando Docker Compose..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest     | grep '"tag_name"' | cut -d'"' -f4 || echo "v2.24.0")
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64"     -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# ── 5. Clonar repositório GitHub
echo "[4/7] Clonando repositório: ${github_repo_url}"
if [ -d "/opt/multicloud-vpn-project" ]; then
  cd /opt/multicloud-vpn-project && git pull origin main || git pull origin master || true
else
  git clone "${github_repo_url}" /opt/multicloud-vpn-project
fi
chown -R ec2-user:ec2-user /opt/multicloud-vpn-project

# ── 6. Gerar configuração do Prometheus com os IPs reais
echo "[5/7] Configurando Prometheus com IPs das instâncias..."
MONITORING_DIR="/opt/multicloud-vpn-project/monitoring"

# Substituir placeholders no prometheus.yml com IPs reais
sed -i "s|BACKEND_IP|${backend_private_ip}|g"   $MONITORING_DIR/prometheus/prometheus.yml
sed -i "s|FRONTEND_IP|${frontend_private_ip}|g" $MONITORING_DIR/prometheus/prometheus.yml
sed -i "s|AZURE_VM_IP|${azure_vm_ip}|g"         $MONITORING_DIR/prometheus/prometheus.yml

# ── 7. Criar diretórios de dados (persistência)
echo "[6/7] Criando volumes de dados..."
mkdir -p /opt/monitoring-data/prometheus
mkdir -p /opt/monitoring-data/grafana
chmod -R 777 /opt/monitoring-data

# ── 8. Criar arquivo de variáveis de ambiente para o Compose
cat > $MONITORING_DIR/.env << ENVEOF
GRAFANA_ADMIN_PASSWORD=${grafana_password}
PROMETHEUS_DATA=/opt/monitoring-data/prometheus
GRAFANA_DATA=/opt/monitoring-data/grafana
BACKEND_IP=${backend_private_ip}
FRONTEND_IP=${frontend_private_ip}
AZURE_VM_IP=${azure_vm_ip}
ENVEOF

# ── 9. Iniciar stack de monitoramento
echo "[7/7] Iniciando Prometheus + Grafana + Node Exporter..."
cd $MONITORING_DIR
docker-compose up -d

# Aguardar os containers subirem
sleep 10
docker-compose ps

# ── 10. Serviço systemd para auto-restart do stack
cat > /etc/systemd/system/multicloud-monitoring.service << 'SVCEOF'
[Unit]
Description=MultiCloud VPN Monitor — Monitoring Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/multicloud-vpn-project/monitoring
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
ExecReload=/usr/local/bin/docker-compose restart

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable multicloud-monitoring

PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || echo "IP_NAO_DISPONIVEL")
echo ""
echo "========================================"
echo " MONITORING SETUP CONCLUIDO! $(date)"
echo " Grafana:        http://$PUBLIC_IP:3000"
echo "   user: admin   senha: ${grafana_password}"
echo " Prometheus:     http://$PUBLIC_IP:9090"
echo " Alertmanager:   http://$PUBLIC_IP:9093"
echo " Node Exporter:  http://$PUBLIC_IP:9100/metrics"
echo "========================================"
