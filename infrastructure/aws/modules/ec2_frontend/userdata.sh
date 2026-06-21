#!/bin/bash
# =============================================================================
# USERDATA — EC2 FRONTEND
# Instalação automática: Node.js 20 + Nginx + clone do repositório GitHub
# Tudo é registrado em /var/log/userdata-frontend.log
# =============================================================================
set -euo pipefail
exec > /var/log/userdata-frontend.log 2>&1
echo "========================================"
echo " EC2 FRONTEND SETUP — $(date)"
echo " Aluno: ${student_name}"
echo "========================================"

# ── 1. Hostname identificável
hostnamectl set-hostname "ec2-frontend-${student_name}"

# ── 2. Atualizar sistema
echo "[1/7] Atualizando sistema..."
yum update -y

# ── 3. Instalar dependências base
echo "[2/7] Instalando git, curl, wget..."
yum install -y git curl wget unzip

# ── 4. Instalar Node.js 20.x LTS via NodeSource
echo "[3/7] Instalando Node.js 20.x LTS..."
curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
yum install -y nodejs
node --version
npm --version
# Instalar PM2 globalmente (process manager para Node.js)
npm install -g pm2

# ── 5. Instalar Nginx
echo "[4/7] Instalando Nginx..."
amazon-linux-extras enable nginx1
yum install -y nginx

# ── 6. Clonar repositório GitHub
echo "[5/7] Clonando repositório: ${github_repo_url}"
if [ -d "/opt/multicloud-vpn-project" ]; then
  cd /opt/multicloud-vpn-project
  git pull origin main || git pull origin master || true
else
  git clone "${github_repo_url}" /opt/multicloud-vpn-project
fi

# ── 7. Instalar dependências Node.js do frontend
echo "[6/7] Instalando dependências npm do frontend..."
cd /opt/multicloud-vpn-project/frontend
npm install --production

# Criar .env com URL do backend
cat > /opt/multicloud-vpn-project/frontend/.env << ENVEOF
PORT=3000
BACKEND_URL=http://${backend_private_ip}:8000
MONITORING_HOST=${backend_private_ip}
ENVEOF

# ── 8. Configurar Nginx
echo "[7/7] Configurando Nginx..."
# Substituir o placeholder do IP do backend no nginx.conf
sed "s|BACKEND_PRIVATE_IP|${backend_private_ip}|g"     /opt/multicloud-vpn-project/frontend/nginx.conf     > /etc/nginx/conf.d/multicloud.conf

# Desabilitar config default do Nginx
rm -f /etc/nginx/conf.d/default.conf

# Injetar BACKEND_URL no index.html para o JavaScript
sed -i "s|window.BACKEND_URL = window.BACKEND_URL || "";|window.BACKEND_URL = "http://${backend_private_ip}:8000";|g"     /opt/multicloud-vpn-project/frontend/public/index.html || true

# ── 9. Habilitar e iniciar serviços
systemctl enable nginx
systemctl start nginx

# PM2 para desenvolvimento (Node.js server em paralelo na porta 3000)
cd /opt/multicloud-vpn-project/frontend
pm2 start server.js --name "multicloud-frontend"
pm2 startup systemd -u ec2-user --hp /home/ec2-user
pm2 save

# ── 10. Criar serviço de atualização automática do repo (pull a cada 5 min)
cat > /etc/cron.d/multicloud-git-pull << CRONEOF
*/5 * * * * root cd /opt/multicloud-vpn-project && git pull origin main --quiet 2>&1 | logger -t multicloud-git && systemctl reload nginx 2>/dev/null || true
CRONEOF

echo ""
echo "========================================"
echo " SETUP CONCLUIDO! $(date)"
echo " Frontend Nginx: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):80"
echo " Frontend Node:  http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4):3000"
echo " Backend proxy:  http://${backend_private_ip}:8000"
echo "========================================"
