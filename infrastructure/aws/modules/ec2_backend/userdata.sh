#!/bin/bash
# =============================================================================
# USERDATA — EC2 BACKEND (SUBNET PRIVADA)
# Instala Docker, Python 3.11, Node Exporter e o backend FastAPI
# =============================================================================
set -euo pipefail
exec > /var/log/userdata-backend.log 2>&1

echo "========================================"
echo " EC2 BACKEND SETUP — $(date)"
echo " Aluno: ${student_name}"
echo "========================================"

# ── 1. Hostname
hostnamectl set-hostname "ec2-backend-${student_name}"

# ── 2. Atualizar sistema
echo "[1/8] Atualizando sistema..."
yum update -y

# ── 3. Instalar dependências base
echo "[2/8] Instalando git, curl, wget, net-tools..."
yum install -y git curl wget unzip net-tools traceroute tcpdump nmap-ncat

# ── 4. Instalar Python 3.11
echo "[3/8] Instalando Python 3.11..."
amazon-linux-extras install python3.8 -y 2>/dev/null || true
yum install -y python3 python3-pip python3-devel gcc
# Tentar instalar Python 3.11 via compilação se não disponível
python3 --version
pip3 install --upgrade pip setuptools wheel

# ── 5. Instalar Docker CE
echo "[4/8] Instalando Docker CE..."
amazon-linux-extras install docker -y
systemctl enable docker
systemctl start docker
# Adicionar ec2-user ao grupo docker
usermod -aG docker ec2-user

# ── 6. Instalar Docker Compose v2
echo "[5/8] Instalando Docker Compose v2..."
COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest     | grep '"tag_name"' | cut -d'"' -f4 || echo "v2.24.0")
curl -SL "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64"     -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
docker-compose --version

# ── 7. Clonar repositório GitHub
echo "[6/8] Clonando repositório: ${github_repo_url}"
if [ -d "/opt/multicloud-vpn-project" ]; then
  cd /opt/multicloud-vpn-project && git pull origin main || git pull origin master || true
else
  git clone "${github_repo_url}" /opt/multicloud-vpn-project
fi
chown -R ec2-user:ec2-user /opt/multicloud-vpn-project

# ── 8. Instalar dependências Python do backend
echo "[7/8] Instalando dependências Python..."
cd /opt/multicloud-vpn-project/backend
pip3 install -r requirements.txt

# Criar arquivo .env do backend
PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || hostname -I | awk '{print $1}')
cat > /opt/multicloud-vpn-project/backend/.env << ENVEOF
CLOUD_PROVIDER=${cloud_provider}
STUDENT_NAME=${student_name}
AWS_REGION=${aws_region}
AWS_EC2_PRIVATE_IP=$PRIVATE_IP
AZURE_VM_PRIVATE_IP=${azure_vm_ip}
OTHER_CLOUD_IP=${azure_vm_ip}
ENVEOF

# ── 9. Serviço systemd para o backend FastAPI (direto com uvicorn)
cat > /etc/systemd/system/multicloud-backend.service << 'SVCEOF'
[Unit]
Description=MultiCloud VPN Monitor — Backend FastAPI
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/multicloud-vpn-project/backend
EnvironmentFile=/opt/multicloud-vpn-project/backend/.env
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000 --workers 2
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable multicloud-backend
systemctl start multicloud-backend

# ── 10. Instalar Node Exporter (métricas para Prometheus)
echo "[8/8] Instalando Node Exporter..."
NODE_EXPORTER_VERSION="1.7.0"
curl -sL "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"     -o /tmp/node_exporter.tar.gz
tar -xzf /tmp/node_exporter.tar.gz -C /tmp/
mv /tmp/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter /usr/local/bin/
chmod +x /usr/local/bin/node_exporter

# Criar usuário dedicado para o node_exporter
useradd --no-create-home --shell /bin/false node_exporter 2>/dev/null || true

cat > /etc/systemd/system/node_exporter.service << 'SVCEOF'
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
User=node_exporter
ExecStart=/usr/local/bin/node_exporter     --collector.systemd     --collector.processes     --web.listen-address=:9100
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter

# ── 11. Também iniciar via Docker Compose (opcional, redundância)
cd /opt/multicloud-vpn-project/backend
docker-compose up -d 2>/dev/null || true

# ── 12. Cron para atualizar o repo automaticamente
cat > /etc/cron.d/multicloud-git-pull << 'CRONEOF'
*/10 * * * * ec2-user cd /opt/multicloud-vpn-project && git pull origin main --quiet 2>&1 | logger -t multicloud-git && systemctl restart multicloud-backend 2>/dev/null || true
CRONEOF

PRIVATE_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 || hostname -I | awk '{print $1}')
echo ""
echo "========================================"
echo " SETUP BACKEND CONCLUIDO! $(date)"
echo " Backend API:    http://$PRIVATE_IP:8000"
echo " API Docs:       http://$PRIVATE_IP:8000/docs"
echo " Node Exporter:  http://$PRIVATE_IP:9100/metrics"
echo " Logs backend:   journalctl -u multicloud-backend -f"
echo "========================================"
