#!/bin/bash
set -e
exec > /var/log/user-data.log 2>&1

echo "=== [$(date)] Iniciando setup EC2 privada ${student_name} ==="

# Hostname
hostnamectl set-hostname "ec2-aws-${student_name}"

# Atualizar sistema
yum update -y

# Ferramentas de rede (para testes VPN)
yum install -y net-tools traceroute tcpdump nmap-ncat python3 python3-pip git

# Habilitar ping response
echo "net.ipv4.icmp_echo_ignore_all = 0" >> /etc/sysctl.conf
sysctl -p

# Instalar dependências Python do backend
pip3 install fastapi uvicorn boto3 azure-identity azure-mgmt-compute azure-mgmt-network httpx jinja2 python-dotenv psutil aiofiles

# Criar diretório do app
mkdir -p /opt/multicloud-backend
cd /opt/multicloud-backend

# Clonar o repositório (substitua pela URL real do seu repo)
# git clone https://github.com/SEU_USUARIO/multicloud-vpn-project.git .
# Por ora, o backend será instalado via SCP após o deploy

# Criar serviço systemd para o backend
cat > /etc/systemd/system/multicloud-backend.service << 'SVCEOF'
[Unit]
Description=MultiCloud VPN Monitor Backend
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/multicloud-backend
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload

echo "=== [$(date)] Setup concluido! Backend aguardando deploy do codigo ==="
echo "IP privado: $(hostname -I | awk '{print $1}')" >> /var/log/user-data.log
