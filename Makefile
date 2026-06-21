# =============================================================================
# MAKEFILE — Comandos do projeto Multi-Cloud VPN
# Uso: make <comando>
# =============================================================================

.PHONY: help deploy destroy status backend test fmt validate

help:
	@echo ""
	@echo "  Multi-Cloud VPN — Comandos disponíveis"
	@echo "  ─────────────────────────────────────────"
	@echo "  make deploy        → Deploy completo (todas as fases)"
	@echo "  make phase1        → Azure infra + VPN Gateway"
	@echo "  make phase2        → AWS completo"
	@echo "  make phase3        → Azure VPN Connection"
	@echo "  make backend       → Deploy do backend nas VMs"
	@echo "  make status        → Status de IPs e recursos"
	@echo "  make test          → Testa conectividade VPN"
	@echo "  make destroy       → Destroi TODOS os recursos"
	@echo "  make validate      → Valida sintaxe Terraform"
	@echo "  make fmt           → Formata código Terraform"
	@echo "  make backend-dev   → Roda backend localmente"
	@echo ""

deploy:
	cd infrastructure && ./deploy.sh all

phase1:
	cd infrastructure && ./deploy.sh phase1

phase2:
	cd infrastructure && ./deploy.sh phase2

phase3:
	cd infrastructure && ./deploy.sh phase3

backend:
	cd infrastructure && ./deploy.sh backend

status:
	cd infrastructure && ./deploy.sh status

test:
	@source infrastructure/.deploy_state 2>/dev/null && \
	backend/scripts/test_vpn.sh $${AWS_EC2_IP:-10.0.1.10} $${AZURE_VM_IP:-10.1.1.10}

destroy:
	cd infrastructure && ./deploy.sh destroy

validate:
	@echo "Validando AWS..."
	cd infrastructure/aws && terraform init -backend=false -reconfigure && terraform validate
	@echo "Validando Azure..."
	cd infrastructure/azure && terraform init -backend=false -reconfigure && terraform validate
	@echo "OK — Todos os arquivos Terraform são válidos."

fmt:
	terraform fmt -recursive infrastructure/

backend-dev:
	cd backend && pip install -r requirements.txt && \
	uvicorn main:app --host 0.0.0.0 --port 8000 --reload

backend-docker:
	cd backend && docker-compose up -d && docker-compose logs -f
