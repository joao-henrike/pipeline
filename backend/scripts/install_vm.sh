#!/usr/bin/env bash
# =============================================================================
# INSTALL_VM.SH — Instala o backend MultiCloud nas VMs (AWS EC2 ou Azure VM)
#
# Uso:
#   chmod +x install_vm.sh
#   sudo ./install_vm.sh
#
# O script detecta automaticamente o OS (Amazon Linux / Ubuntu).
# =============================================================================
set -euo pipefail
APP_DIR="/opt/multicloud-backend"
SERVICE="multicloud-backend"

echo "=== Instalando MultiCloud VPN Monitor Backend ==="

# Detectar OS
if [ -f /etc/os-release ]; then
  . /etc/os-release
  OS=$ID
else
  OS="unknown"
fi
echo "OS detectado: $OS"

# Instalar dependências conforme o OS
if [[ "$OS" == "amzn" || "$OS" == "rhel" || "$OS" == "centos" ]]; then
  yum update -y
  yum install -y python3 python3-pip git net-tools traceroute tcpdump nmap-ncat
elif [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
  apt-get update -y
  apt-get install -y python3 python3-pip git net-tools traceroute tcpdump netcat-openbsd nmap iputils-ping
else
  echo "OS não suportado: $OS"
fi

# Criar diretório da aplicação
mkdir -p "$APP_DIR"

# Copiar arquivos (assumindo que o script é executado do root do projeto)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$(dirname "$SCRIPT_DIR")"
cp -r "$BACKEND_DIR"/* "$APP_DIR"/

# Instalar dependências Python
pip3 install -r "$APP_DIR/requirements.txt"

# Criar arquivo .env se não existir
if [ ! -f "$APP_DIR/.env" ]; then
  cat > "$APP_DIR/.env" << ENVEOF
CLOUD_PROVIDER=AWS
STUDENT_NAME=SeuNome
AWS_REGION=us-east-1
OTHER_CLOUD_IP=
ENVEOF
  echo "⚠  Edite $APP_DIR/.env com os valores corretos!"
fi

# Criar serviço systemd
cat > "/etc/systemd/system/${SERVICE}.service" << SVCEOF
[Unit]
Description=MultiCloud VPN Monitor Backend
After=network.target

[Service]
Type=simple
WorkingDirectory=${APP_DIR}
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always
RestartSec=5
EnvironmentFile=${APP_DIR}/.env

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable "$SERVICE"
systemctl restart "$SERVICE"

echo ""
echo "✓ Backend instalado e iniciado!"
echo "  Dashboard: http://$(hostname -I | awk '{print $1}'):8000"
echo "  Logs:      journalctl -u $SERVICE -f"
echo "  Config:    $APP_DIR/.env"
