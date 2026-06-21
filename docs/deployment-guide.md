# Guia Completo de Deploy — Multi-Cloud VPN AWS + Azure

## Pré-requisitos

| Ferramenta     | Versão    | Instalação |
|----------------|-----------|------------|
| Terraform      | >= 1.5.0  | https://developer.hashicorp.com/terraform/install |
| AWS CLI        | >= 2.x    | `pip install awscli` |
| Azure CLI      | >= 2.50   | https://docs.microsoft.com/cli/azure/install-azure-cli |
| Python         | >= 3.11   | https://python.org |
| Docker         | >= 24.x   | https://docs.docker.com/get-docker/ |
| jq             | any       | `apt install jq` / `brew install jq` |

---

## Configuração Inicial

### 1. Autenticação AWS
```bash
aws configure
# Informe: Access Key ID, Secret Access Key, Region (us-east-1), output (json)

# Verificar:
aws sts get-caller-identity
```

### 2. Autenticação Azure
```bash
az login
az account list --output table

# Definir subscription ativa
az account set --subscription "NOME_OU_ID"

# Obter Subscription ID (anote — vai no terraform.tfvars)
az account show --query id --output tsv
```

### 3. Configurar terraform.tfvars

**infrastructure/aws/terraform.tfvars:**
```hcl
student_name   = "SeuNomeAqui"
vpn_shared_key = "SuaSenhaForte2024"
```

**infrastructure/azure/terraform.tfvars:**
```hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
student_name    = "SeuNomeAqui"   # MESMO DO AWS
vpn_shared_key  = "SuaSenhaForte2024"  # MESMO DO AWS
```

---

## Deploy Automático (Recomendado)

```bash
cd infrastructure
chmod +x deploy.sh

# Deploy completo (todas as fases)
./deploy.sh all
```

O script executa automaticamente as 4 fases e passa os IPs entre as clouds.

---

## Deploy Manual (Fase a Fase)

### FASE 1: Azure — VNet + NSG + VM + VPN Gateway

```bash
cd infrastructure/azure
terraform init
terraform apply
```

**⚠️ O Azure VPN Gateway leva 30–45 minutos para provisionar. Aguarde.**

Anote o output:
```
vpn_gateway_public_ip = "20.x.x.x"   ← IP do Azure VPN GW
vm_public_ip          = "20.y.y.y"   ← IP da VM Azure
```

### FASE 2: AWS — VPC + EC2 + VGW + VPN Connection

Atualize `infrastructure/aws/terraform.tfvars`:
```hcl
azure_vpn_gateway_ip = "20.x.x.x"   # ← da Fase 1
create_vpn_tunnel    = true
```

```bash
cd infrastructure/aws
terraform init
terraform apply
```

Anote os outputs:
```
vpn_tunnel1_outside_ip = "34.a.b.c"   ← IP Túnel 1 AWS
vpn_tunnel2_outside_ip = "34.d.e.f"   ← IP Túnel 2 AWS
ec2_private_ip         = "10.0.1.x"   ← IP privado EC2
bastion_public_ip      = "3.g.h.i"    ← IP Bastion
```

### FASE 3: Azure — VPN Connection

Atualize `infrastructure/azure/terraform.tfvars`:
```hcl
aws_tunnel1_ip        = "34.a.b.c"   # ← Túnel 1 da Fase 2
aws_tunnel2_ip        = "34.d.e.f"   # ← Túnel 2 da Fase 2
create_vpn_connection = true
```

```bash
cd infrastructure/azure
terraform apply
```

Aguarde 2–5 minutos para o túnel IPsec estabelecer.

### FASE 4: Deploy do Backend

```bash
# Instalar backend na EC2 AWS (via Bastion)
scp -i infrastructure/aws/keys/key-multicloud-SeuNome.pem \
    -o ProxyJump=ec2-user@<BASTION_IP> \
    -r backend/ \
    ec2-user@<EC2_PRIVATE_IP>:/opt/multicloud-backend/

# SSH na EC2 via Bastion e instalar
ssh -i infrastructure/aws/keys/key-multicloud-SeuNome.pem \
    -J ec2-user@<BASTION_IP> \
    ec2-user@<EC2_PRIVATE_IP> \
    "cd /opt/multicloud-backend && sudo ./scripts/install_vm.sh"

# Instalar backend na VM Azure (diretamente)
scp -i infrastructure/azure/keys/key-azure-SeuNome.pem \
    -r backend/ \
    azureuser@<AZURE_VM_PUBLIC_IP>:/opt/multicloud-backend/

ssh -i infrastructure/azure/keys/key-azure-SeuNome.pem \
    azureuser@<AZURE_VM_PUBLIC_IP> \
    "cd /opt/multicloud-backend && sudo ./scripts/install_vm.sh"
```

---

## Verificação do Túnel VPN

### No Console AWS
```bash
aws ec2 describe-vpn-connections \
  --query "VpnConnections[*].{ID:VpnConnectionId,Status:State,Tunnels:VgwTelemetry}" \
  --output table
```

### No Portal Azure
Navegue até: **VPN Gateways → vpngw-SeuNome → Connections → conn-aws-t1-SeuNome**

Status esperado: **Connected**

### Teste de Conectividade
```bash
# SSH na EC2 via Bastion
ssh -i infrastructure/aws/keys/key-multicloud-SeuNome.pem \
    -J ec2-user@<BASTION_IP> \
    ec2-user@<EC2_PRIVATE_IP>

# Dentro da EC2: ping na Azure VM
ping <AZURE_VM_PRIVATE_IP>   # deve responder com ~50ms
```

---

## Dashboard Web

```
http://<AZURE_VM_PUBLIC_IP>:8000       → Dashboard Azure
http://<BASTION_IP>:8000               → Dashboard AWS (via Bastion)
```

---

## Destruir o Ambiente

```bash
cd infrastructure
./deploy.sh destroy

# Ou manualmente:
cd infrastructure/azure && terraform destroy
cd infrastructure/aws   && terraform destroy
```

---

## Custos Estimados (us-east-1 / eastus)

| Recurso               | Custo/hora | Custo/mês |
|-----------------------|-----------|-----------|
| EC2 t2.micro (x2)    | $0.0116   | ~$17      |
| Azure VM Standard_B1s | $0.0104   | ~$8       |
| AWS NAT Gateway       | $0.045    | ~$33      |
| AWS VPN Connection    | $0.050    | ~$37      |
| Azure VPN GW VpnGw1  | $0.190    | ~$140     |
| EIPs e IPs públicos   | ~$0.005   | ~$5       |
| **TOTAL ESTIMADO**    |           | **~$240** |

> ⚠️ **Destrua o ambiente após o projeto para evitar cobranças.**
