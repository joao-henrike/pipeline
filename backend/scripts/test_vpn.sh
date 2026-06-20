#!/usr/bin/env bash
# =============================================================================
# TEST_VPN.SH — Testa a conectividade VPN entre AWS e Azure
# Execute APÓS o deploy.sh ter concluído e o túnel VPN estar ativo.
#
# Uso: ./test_vpn.sh <AWS_EC2_IP> <AZURE_VM_IP>
# =============================================================================
set -euo pipefail

AWS_IP="${1:-10.0.1.10}"
AZ_IP="${2:-10.1.1.10}"

RED='[0;31m'; GREEN='[0;32m'; YELLOW='[1;33m'; NC='[0m'; BOLD='[1m'

ok()   { echo -e "${GREEN}[✓] $*${NC}"; }
fail() { echo -e "${RED}[✗] $*${NC}"; }
info() { echo -e "${YELLOW}[i] $*${NC}"; }
hdr()  { echo -e "
${BOLD}$*${NC}"; echo "$(printf '─%.0s' {1..40})"; }

hdr "Teste 1: ICMP Ping (AWS → Azure)"
if ping -c 4 -W 5 "$AZ_IP" > /tmp/ping_az.txt 2>&1; then
  ok "Ping para Azure ($AZ_IP) BEM-SUCEDIDO"
  grep -E "transmitted|rtt" /tmp/ping_az.txt | sed 's/^/   /'
else
  fail "Ping para Azure ($AZ_IP) FALHOU — VPN pode estar inativa"
  cat /tmp/ping_az.txt
fi

hdr "Teste 2: ICMP Ping (Azure → AWS) — via API do backend"
if curl -sf "http://localhost:8000/api/connectivity/ping/peer" > /tmp/ping_api.txt 2>&1; then
  LOSS=$(python3 -c "import json; d=json.load(open('/tmp/ping_api.txt')); print(d['packet_loss_pct'])")
  LAT=$(python3  -c "import json; d=json.load(open('/tmp/ping_api.txt')); print(d['avg_latency_ms'])")
  ok "Ping via API: perda=${LOSS}% latência=${LAT}ms"
else
  info "Backend não está rodando ou OTHER_CLOUD_IP não configurado"
fi

hdr "Teste 3: SSH Port Check (porta 22)"
if nc -zv "$AZ_IP" 22 -w 5 2>&1 | grep -q "succeeded\|Connected"; then
  ok "Porta 22 (SSH) acessível em $AZ_IP via VPN"
else
  fail "Porta 22 NÃO acessível em $AZ_IP"
fi

hdr "Teste 4: Backend HTTP (porta 8000)"
if nc -zv "$AZ_IP" 8000 -w 5 2>&1 | grep -q "succeeded\|Connected"; then
  ok "Porta 8000 (Backend) acessível em $AZ_IP via VPN"
  curl -sf "http://${AZ_IP}:8000/api/status/health" | python3 -m json.tool 2>/dev/null || true
else
  info "Porta 8000 não acessível (backend pode não estar instalado ainda)"
fi

hdr "Teste 5: Traceroute"
traceroute -m 10 -w 2 "$AZ_IP" 2>/dev/null | head -12 || true

hdr "Resumo"
echo "  AWS EC2 IP : $AWS_IP"
echo "  Azure VM IP: $AZ_IP"
echo ""
echo "  Para prints do relatório, capture as saídas acima."
echo "  Dashboard visual: http://localhost:8000"
