# Tabela de Endereços IP — Multi-Cloud VPN

## Endereçamento de Rede

| Recurso                  | CIDR / IP           | Notas                              |
|--------------------------|--------------------|------------------------------------|
| **AWS VPC**              | 10.0.0.0/16        | Rede principal AWS                 |
| AWS Subnet Pública       | 10.0.0.0/24        | Bastion Host + NAT Gateway         |
| AWS Subnet Privada       | 10.0.1.0/24        | EC2 principal (endpoint VPN)       |
| AWS EC2 Private IP       | 10.0.1.x (DHCP)    | Alvo dos testes ping/SSH do Azure  |
| **Azure VNet**           | 10.1.0.0/16        | Rede principal Azure               |
| Azure GatewaySubnet      | 10.1.0.0/27        | **Obrigatório** para VPN Gateway   |
| Azure Subnet Privada     | 10.1.1.0/24        | VM principal (endpoint VPN)        |
| Azure VM Private IP      | 10.1.1.x (DHCP)    | Alvo dos testes ping/SSH do AWS    |

## Endereços VPN (IPsec Tunnels)

| Recurso                  | Endereço              | Notas                              |
|--------------------------|-----------------------|------------------------------------|
| Tunnel 1 Inside CIDR     | 169.254.21.0/30       | Link-local interno IPsec T1        |
| Tunnel 2 Inside CIDR     | 169.254.22.0/30       | Link-local interno IPsec T2        |
| AWS Tunnel 1 Outside IP  | 34.x.x.x (gerado AWS) | Configure no Azure LNG T1          |
| AWS Tunnel 2 Outside IP  | 34.y.y.y (gerado AWS) | Configure no Azure LNG T2          |
| Azure VPN GW Public IP   | 20.z.z.z (gerado Az)  | Configure como CGW no AWS          |

## Políticas de Segurança

### AWS Security Group — EC2 Privada
| Direção | Protocolo | Porta | Origem               | Propósito           |
|---------|-----------|-------|----------------------|---------------------|
| Inbound | ICMP      | -1    | 10.1.0.0/16 (Azure)  | Ping do Azure       |
| Inbound | TCP       | 22    | 10.1.0.0/16 (Azure)  | SSH do Azure        |
| Inbound | TCP       | 8000  | 10.1.0.0/16 (Azure)  | Backend HTTP        |
| Inbound | ICMP      | -1    | 10.0.0.0/16 (VPC)    | Ping interno        |
| Inbound | TCP       | 22    | 10.0.0.0/16 (VPC)    | SSH via Bastion     |
| Outbound| ALL       | ALL   | 0.0.0.0/0            | Saída liberada      |

### Azure NSG — Subnet Privada
| Direção | Protocolo | Porta | Origem               | Propósito           |
|---------|-----------|-------|----------------------|---------------------|
| Inbound | TCP       | 22    | Admin IPs            | SSH externo         |
| Inbound | ICMP      | *     | 10.0.0.0/16 (AWS)    | Ping do AWS         |
| Inbound | TCP       | 22    | 10.0.0.0/16 (AWS)    | SSH do AWS          |
| Inbound | TCP       | 8000  | 10.0.0.0/16 (AWS)    | Backend HTTP        |
| Outbound| ALL       | ALL   | 0.0.0.0/0            | Saída liberada      |

## Parâmetros VPN IPsec

| Parâmetro         | Valor         |
|-------------------|---------------|
| Tipo              | Site-to-Site  |
| Protocolo         | IPsec/IKEv2   |
| IKE Encryption    | AES-256       |
| IKE Integrity     | SHA-256       |
| DH Group          | Group 2       |
| IPsec Encryption  | AES-256       |
| IPsec Integrity   | SHA-256       |
| PFS Group         | PFS 2         |
| SA Lifetime       | 3600s         |
| Dead Peer Detect  | Habilitado    |
