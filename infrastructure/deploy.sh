#!/usr/bin/env bash
# =============================================================================
# DEPLOY.SH — Orquestrador do deploy Multi-Cloud VPN
#
# Ordem de execução (resolve o problema de IPs circulares):
#
#   FASE 1: Azure VPN Gateway (cria e obtém o IP público do Azure VPN GW)
#   FASE 2: AWS completo (VPC + EC2 + VGW + CGW + VPN Connection com IP Azure)
#   FASE 3: Azure VPN Connection (LNG + Connection usando IPs AWS dos túneis)
#   FASE 4: Deploy do Backend nas VMs
#
# Uso:
#   ./deploy.sh all          — executa todas as fases
#   ./deploy.sh phase1       — apenas Azure infra + VPN GW
#   ./deploy.sh phase2       — apenas AWS (requer phase1 concluída)
#   ./deploy.sh phase3       — apenas Azure VPN Connection (requer phase2)
#   ./deploy.sh backend      — deploy do backend nas VMs
#   ./deploy.sh destroy      — destrói TUDO (AWS + Azure)
#   ./deploy.sh status        — mostra status dos recursos
# =============================================================================

set -euo pipefail

# ── Cores para output
RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'
BLUE='[0;34m'; CYAN='[0;36m'; BOLD='[1m'; NC='[0m'

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AWS_DIR="$DIR/aws"
AZURE_DIR="$DIR/azure"
STATE_FILE="$DIR/.deploy_state"

log()     { echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} $*"; }
success() { echo -e "${GREEN}[✓] $*${NC}"; }
warn()    { echo -e "${YELLOW}[⚠] $*${NC}"; }
error()   { echo -e "${RED}[✗] $*${NC}"; exit 1; }
header()  { echo -e "
${BOLD}${BLUE}═══════════════════════════════════════${NC}"; echo -e "${BOLD}${BLUE} $* ${NC}"; echo -e "${BOLD}${BLUE}═══════════════════════════════════════${NC}
"; }

# ── Verificar pré-requisitos
check_prereqs() {
  header "Verificando pré-requisitos"
  local missing=0

  for cmd in terraform aws az python3 ssh scp jq; do
    if command -v "$cmd" &>/dev/null; then
      success "$cmd encontrado: $(command -v $cmd)"
    else
      warn "$cmd NÃO encontrado — instale antes de continuar"
      missing=$((missing+1))
    fi
  done

  if [ $missing -gt 0 ]; then
    error "$missing pré-requisito(s) faltando. Instale e tente novamente."
  fi

  # Verificar credenciais AWS
  if aws sts get-caller-identity &>/dev/null; then
    success "AWS credentials OK: $(aws sts get-caller-identity --query Account --output text)"
  else
    error "AWS credentials inválidas. Execute: aws configure"
  fi

  # Verificar credenciais Azure
  if az account show &>/dev/null; then
    success "Azure credentials OK: $(az account show --query name --output tsv)"
  else
    error "Azure não autenticado. Execute: az login"
  fi
}

# ── FASE 1: Azure infra + VPN Gateway
phase1_azure_infra() {
  header "FASE 1: Provisionando Azure (VNet + NSG + VM + VPN Gateway)"
  warn "O Azure VPN Gateway leva 30-45 minutos para ser criado. Aguarde..."

  cd "$AZURE_DIR"
  terraform init -upgrade
  terraform plan -out=tfplan.phase1
  terraform apply -auto-approve tfplan.phase1

  # Extrair IP do Azure VPN Gateway
  AZURE_VPN_IP=$(terraform output -raw vpn_gateway_public_ip 2>/dev/null || echo "")
  if [ -z "$AZURE_VPN_IP" ] || [ "$AZURE_VPN_IP" = "null" ]; then
    error "Não foi possível obter o IP do Azure VPN Gateway. Verifique o apply."
  fi

  AZURE_VM_IP=$(terraform output -raw vm_private_ip 2>/dev/null || echo "")
  AZURE_VM_PUBLIC=$(terraform output -raw vm_public_ip 2>/dev/null || echo "")

  echo "AZURE_VPN_IP=$AZURE_VPN_IP"       > "$STATE_FILE"
  echo "AZURE_VM_IP=$AZURE_VM_IP"         >> "$STATE_FILE"
  echo "AZURE_VM_PUBLIC=$AZURE_VM_PUBLIC" >> "$STATE_FILE"

  success "FASE 1 concluída!"
  success "Azure VPN Gateway IP: $AZURE_VPN_IP"
  success "Azure VM Private IP:  $AZURE_VM_IP"
}

# ── FASE 2: AWS completo
phase2_aws() {
  header "FASE 2: Provisionando AWS (VPC + EC2 + VGW + VPN Connection)"

  # Carregar estado da fase 1
  if [ ! -f "$STATE_FILE" ]; then
    error "State file não encontrado. Execute phase1 primeiro."
  fi
  source "$STATE_FILE"

  cd "$AWS_DIR"
  terraform init -upgrade

  # Aplicar com o IP do Azure já conhecido
  terraform apply -auto-approve     -var="azure_vpn_gateway_ip=$AZURE_VPN_IP"     -var="create_vpn_tunnel=true"

  # Extrair IPs dos túneis AWS
  AWS_TUNNEL1=$(terraform output -raw vpn_tunnel1_outside_ip 2>/dev/null || echo "")
  AWS_TUNNEL2=$(terraform output -raw vpn_tunnel2_outside_ip 2>/dev/null || echo "")
  AWS_EC2_IP=$(terraform output -raw ec2_private_ip 2>/dev/null || echo "")
  AWS_BASTION_IP=$(terraform output -raw bastion_public_ip 2>/dev/null || echo "")
  AWS_KEY_NAME=$(terraform output -raw key_pair_name 2>/dev/null || echo "")

  echo "AWS_TUNNEL1=$AWS_TUNNEL1"       >> "$STATE_FILE"
  echo "AWS_TUNNEL2=$AWS_TUNNEL2"       >> "$STATE_FILE"
  echo "AWS_EC2_IP=$AWS_EC2_IP"         >> "$STATE_FILE"
  echo "AWS_BASTION_IP=$AWS_BASTION_IP" >> "$STATE_FILE"
  echo "AWS_KEY_NAME=$AWS_KEY_NAME"     >> "$STATE_FILE"

  success "FASE 2 concluída!"
  success "AWS Tunnel 1 IP: $AWS_TUNNEL1"
  success "AWS Tunnel 2 IP: $AWS_TUNNEL2"
  success "AWS EC2 Private: $AWS_EC2_IP"
  success "AWS Bastion IP:  $AWS_BASTION_IP"
}

# ── FASE 3: Azure VPN Connection
phase3_azure_vpn_connect() {
  header "FASE 3: Criando Azure VPN Connection (Local Network Gateway + Connection)"

  source "$STATE_FILE"

  if [ -z "${AWS_TUNNEL1:-}" ]; then
    error "AWS_TUNNEL1 não definido. Execute phase2 primeiro."
  fi

  cd "$AZURE_DIR"

  terraform apply -auto-approve     -var="aws_tunnel1_ip=$AWS_TUNNEL1"     -var="aws_tunnel2_ip=$AWS_TUNNEL2"     -var="create_vpn_connection=true"

  success "FASE 3 concluída! VPN Connection criada."
  warn "Aguarde 2-5 minutos para o túnel IPsec estabelecer..."
}

# ── FASE 4: Deploy do Backend
phase4_backend() {
  header "FASE 4: Deploy do Backend nas VMs"

  source "$STATE_FILE"
  STUDENT=$(grep "student_name" "$AWS_DIR/terraform.tfvars" | cut -d'"' -f2 | head -1)
  AWS_KEY="$AWS_DIR/keys/key-multicloud-${STUDENT}.pem"
  AZ_KEY="$AZURE_DIR/keys/key-azure-${STUDENT}.pem"
  BACKEND_DIR="$(dirname $DIR)/backend"

  # ── Deploy na EC2 AWS
  log "Copiando backend para EC2 AWS via Bastion..."
  scp -i "$AWS_KEY" -o StrictHostKeyChecking=no       -o ProxyJump="ec2-user@${AWS_BASTION_IP}"       -r "$BACKEND_DIR"/*       "ec2-user@${AWS_EC2_IP}:/opt/multicloud-backend/"

  log "Criando .env na EC2 AWS..."
  ssh -i "$AWS_KEY" -o StrictHostKeyChecking=no       -J "ec2-user@${AWS_BASTION_IP}"       "ec2-user@${AWS_EC2_IP}" << ENVCMD
cat > /opt/multicloud-backend/.env << ENVEOF
CLOUD_PROVIDER=AWS
AWS_REGION=$(grep aws_region "$AWS_DIR/terraform.tfvars" | cut -d'"' -f2)
AZURE_VM_IP=${AZURE_VM_IP}
AWS_EC2_PRIVATE_IP=${AWS_EC2_IP}
STUDENT_NAME=${STUDENT}
ENVEOF
systemctl enable multicloud-backend
systemctl restart multicloud-backend
ENVCMD

  # ── Deploy na VM Azure
  log "Copiando backend para VM Azure..."
  scp -i "$AZ_KEY" -o StrictHostKeyChecking=no       -r "$BACKEND_DIR"/*       "${AZURE_VM_PUBLIC}:/opt/multicloud-backend/" 2>/dev/null ||   warn "SSH Azure ainda não disponível. Deploy manual necessário."

  success "FASE 4 concluída!"
  success "Backend AWS: http://${AWS_BASTION_IP}:8000"
}

# ── Status geral
show_status() {
  header "Status do Deploy"
  if [ -f "$STATE_FILE" ]; then
    source "$STATE_FILE"
    echo -e "
${BOLD}IPs e Recursos:${NC}"
    echo "  Azure VPN GW IP : ${AZURE_VPN_IP:-N/A}"
    echo "  Azure VM Private: ${AZURE_VM_IP:-N/A}"
    echo "  Azure VM Public : ${AZURE_VM_PUBLIC:-N/A}"
    echo "  AWS Tunnel 1 IP : ${AWS_TUNNEL1:-N/A}"
    echo "  AWS Tunnel 2 IP : ${AWS_TUNNEL2:-N/A}"
    echo "  AWS EC2 Private : ${AWS_EC2_IP:-N/A}"
    echo "  AWS Bastion IP  : ${AWS_BASTION_IP:-N/A}"
  else
    warn "Nenhum deploy realizado ainda."
  fi
}

# ── Destruir tudo
destroy_all() {
  header "DESTRUINDO TODOS OS RECURSOS"
  warn "Isso vai remover TUDO. Tem certeza? [digite 'yes' para confirmar]"
  read -r confirm
  if [ "$confirm" != "yes" ]; then
    log "Operação cancelada."
    exit 0
  fi

  cd "$AWS_DIR"
  terraform destroy -auto-approve || true

  cd "$AZURE_DIR"
  terraform destroy -auto-approve || true

  rm -f "$STATE_FILE"
  success "Todos os recursos destruídos."
}

# ── Entry point
case "${1:-help}" in
  all)
    check_prereqs
    phase1_azure_infra
    phase2_aws
    phase3_azure_vpn_connect
    phase4_backend
    header "DEPLOY COMPLETO!"
    show_status
    ;;
  phase1)  check_prereqs; phase1_azure_infra ;;
  phase2)  check_prereqs; phase2_aws ;;
  phase3)  check_prereqs; phase3_azure_vpn_connect ;;
  backend) phase4_backend ;;
  status)  show_status ;;
  destroy) destroy_all ;;
  *)
    echo -e "${BOLD}Uso: $0 {all|phase1|phase2|phase3|backend|status|destroy}${NC}"
    echo ""
    echo "  all      — Deploy completo (todas as fases)"
    echo "  phase1   — Apenas Azure infra + VPN Gateway"
    echo "  phase2   — Apenas AWS completo"
    echo "  phase3   — Apenas Azure VPN Connection"
    echo "  backend  — Deploy do backend nas VMs"
    echo "  status   — Mostra IPs e estado do deploy"
    echo "  destroy  — Remove TODOS os recursos"
    ;;
esac
