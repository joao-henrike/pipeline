# Multi-Cloud VPN — AWS + Azure Site-to-Site

Projeto de entrega: VPN Site-to-Site entre **AWS** e **Azure** com comunicação
por IPs privados, backend Python e dashboard de monitoramento.

**Aluno:** [Seu Nome]  
**Curso:** Cloud Computing

---

## Arquitetura

```
Internet
   │
   ├── AWS (us-east-1)                    Azure (eastus)
   │   ┌──────────────────────────┐      ┌──────────────────────────┐
   │   │  VPC 10.0.0.0/16        │      │  VNet 10.1.0.0/16       │
   │   │                          │      │                           │
   │   │  Public Subnet .0.0/24   │      │  GatewaySubnet .0.0/27  │
   │   │  ├── Bastion Host        │      │  └── VPN Gateway         │
   │   │  └── NAT Gateway         │      │                           │
   │   │                          │      │  Private Subnet .1.0/24  │
   │   │  Private Subnet .1.0/24  │      │  └── VM Ubuntu (backend) │
   │   │  └── EC2 (backend)       │      │                           │
   │   │                          │      │                           │
   │   │  Virtual Private Gateway │◄────►│  VPN Connection          │
   │   └──────────────────────────┘      └──────────────────────────┘
   │             IPsec IKEv2 · AES-256 · Dois túneis redundantes
```

---

## Estrutura do Repositório

```
multicloud-vpn-project/
├── infrastructure/
│   ├── deploy.sh               ← Orquestrador completo (use este!)
│   ├── aws/                    ← Terraform AWS (VPC, EC2, VGW, VPN)
│   │   └── modules/vpc|sg|ec2|vpn
│   └── azure/                  ← Terraform Azure (VNet, NSG, VM, VPN GW)
│       └── modules/vnet|nsg|vm|vpn
├── backend/                    ← FastAPI Python + Dashboard HTML
│   ├── main.py                 ← Ponto de entrada
│   ├── app/routers/            ← Endpoints: status, vpn, connectivity, cloud
│   ├── app/services/           ← Integração boto3 (AWS) + azure-sdk
│   ├── templates/index.html    ← Dashboard visual
│   ├── scripts/                ← install_vm.sh + test_vpn.sh
│   ├── Dockerfile
│   └── docker-compose.yml
└── docs/
    ├── deployment-guide.md     ← Guia completo passo a passo
    └── ip-address-table.md     ← Tabela de IPs e políticas de segurança
```

---

## Quick Start

### 1. Configurar credenciais
```bash
aws configure           # AWS
az login                # Azure
```

### 2. Editar variáveis
```bash
# infrastructure/aws/terraform.tfvars
student_name   = "SeuNome"
vpn_shared_key = "SuaSenhaForte2024"

# infrastructure/azure/terraform.tfvars
subscription_id = "$(az account show --query id -o tsv)"
student_name    = "SeuNome"
vpn_shared_key  = "SuaSenhaForte2024"
```

### 3. Deploy
```bash
make deploy      # Deploy completo automatizado
# OU passo a passo:
make phase1      # Azure infra + VPN Gateway (~35min)
make phase2      # AWS completo
make phase3      # Azure VPN Connection
make backend     # Deploy do backend nas VMs
```

### 4. Testar
```bash
make test        # Executa test_vpn.sh automaticamente
make status      # Mostra todos os IPs
```

### 5. Dashboard
```
http://<AZURE_VM_PUBLIC_IP>:8000   → Dashboard Web
http://<BASTION_IP>:8000           → Dashboard AWS
http://<any>:8000/docs             → API Swagger
```

### 6. Destruir
```bash
make destroy     # Remove TODOS os recursos (para evitar custos)
```

---

## API Endpoints

| Método | Endpoint                          | Descrição                    |
|--------|-----------------------------------|------------------------------|
| GET    | `/`                               | Dashboard visual             |
| GET    | `/api/status/`                    | Status geral do sistema      |
| GET    | `/api/status/health`              | Health check                 |
| GET    | `/api/vpn/summary`                | Status VPN ambos os lados    |
| POST   | `/api/connectivity/ping`          | Ping para qualquer IP        |
| GET    | `/api/connectivity/ping/peer`     | Ping automático para peer    |
| POST   | `/api/connectivity/traceroute`    | Traceroute                   |
| GET    | `/api/connectivity/port/{ip}/{p}` | Verificar porta TCP          |
| GET    | `/api/connectivity/topology`      | Topologia de rede            |
| GET    | `/api/cloud/aws/vm`               | Info EC2 AWS                 |
| GET    | `/api/cloud/azure/vm`             | Info VM Azure                |
| GET    | `/docs`                           | Swagger UI                   |

---

## Diagrama VPN

```
AWS VGW (Virtual Private Gateway)
    └── VPN Connection
        ├── Tunnel 1: 169.254.21.0/30  PSK: [configurado]  IKEv2/AES256/SHA256
        └── Tunnel 2: 169.254.22.0/30  PSK: [configurado]  IKEv2/AES256/SHA256 (redundância)
            ↕
Azure VPN Gateway (VpnGw1, RouteBased)
    ├── Local Network Gateway T1 → AWS Tunnel 1 Outside IP
    └── Local Network Gateway T2 → AWS Tunnel 2 Outside IP
```

---

## Custos

> ⚠️ Execute `make destroy` após a apresentação para evitar cobranças.

| Recurso            | Custo/mês estimado |
|--------------------|--------------------|
| AWS (EC2 + NAT + VPN) | ~$87           |
| Azure (VM + VPN GW)   | ~$148          |
| **Total**             | **~$235/mês**  |
