#!/bin/bash
set -e
exec > /var/log/cloud-init-custom.log 2>&1

echo "=== [$(date)] Setup VM Azure ${student_name} ==="

# Hostname
hostnamectl set-hostname "vm-azure-${student_name}"

# Atualizar e instalar dependências
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y   net-tools traceroute tcpdump netcat-openbsd nmap   python3 python3-pip git curl wget iputils-ping

# Instalar dependências Python do backend
pip3 install fastapi uvicorn boto3 azure-identity   azure-mgmt-compute azure-mgmt-network httpx   jinja2 python-dotenv psutil aiofiles

# Criar diretório do backend
mkdir -p /opt/multicloud-backend
chown ${admin_username}:${admin_username} /opt/multicloud-backend

# Serviço systemd para o backend
cat > /etc/systemd/system/multicloud-backend.service << 'SVCEOF'
[Unit]
Description=MultiCloud VPN Monitor Backend
After=network.target

[Service]
Type=simple
User=${admin_username}
WorkingDirectory=/opt/multicloud-backend
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
echo "=== [$(date)] Setup concluido! ==="
