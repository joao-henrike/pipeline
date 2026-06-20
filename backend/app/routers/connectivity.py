"""
Router: /api/connectivity
Testes de conectividade cross-cloud via VPN:
  ping, traceroute, check de porta.
"""
from fastapi import APIRouter, HTTPException, Query
from typing import Optional
from pydantic import BaseModel
from ..config import settings
from ..models import PingResult
from ..services import network_service

router = APIRouter(prefix="/api/connectivity", tags=["Connectivity"])


class PingRequest(BaseModel):
    target_ip: str
    count: int = 4
    timeout: int = 10


class TracerouteRequest(BaseModel):
    target_ip: str
    max_hops: int = 15


@router.post("/ping", response_model=PingResult)
async def run_ping(req: PingRequest):
    """
    Executa ping ICMP para o IP alvo.
    Use o IP privado da VM na outra cloud para testar a VPN.

    Exemplo:
      POST /api/connectivity/ping
      Body: {"target_ip": "10.1.1.10", "count": 4}
    """
    if req.count < 1 or req.count > 20:
        raise HTTPException(status_code=400, detail="count deve ser entre 1 e 20")
    return await network_service.ping_host(req.target_ip, req.count, req.timeout)


@router.get("/ping/peer", response_model=PingResult)
async def ping_peer(count: int = Query(4, ge=1, le=20)):
    """
    Atalho: faz ping para a outra cloud (IP configurado em OTHER_CLOUD_IP).
    Se other_cloud_ip não estiver definido, retorna erro 400.
    """
    other_ip = settings.other_cloud_ip
    if not other_ip:
        raise HTTPException(
            status_code=400,
            detail="OTHER_CLOUD_IP não configurado no .env. "
                   "Defina o IP privado da VM na outra cloud.",
        )
    return await network_service.ping_host(other_ip, count)


@router.post("/traceroute")
async def run_traceroute(req: TracerouteRequest):
    """Executa traceroute para o IP alvo e retorna o caminho de rede."""
    output = await network_service.traceroute_host(req.target_ip, req.max_hops)
    return {
        "target_ip": req.target_ip,
        "max_hops":  req.max_hops,
        "output":    output,
    }


@router.get("/port/{target_ip}/{port}")
async def check_port(target_ip: str, port: int, timeout: int = Query(5, ge=1, le=30)):
    """
    Verifica se a porta TCP está acessível na VM alvo.
    Útil para testar SSH (22) e backend HTTP (8000) via VPN.

    Exemplo: GET /api/connectivity/port/10.1.1.10/22
    """
    return await network_service.check_port(target_ip, port, timeout)


@router.get("/topology")
def get_topology():
    """
    Retorna o mapa de rede do ambiente multi-cloud.
    Usado pelo frontend para renderizar o diagrama de topologia.
    """
    cloud = settings.cloud_provider.upper()
    return {
        "aws": {
            "vpc_cidr":          "10.0.0.0/16",
            "public_subnet":     "10.0.0.0/24",
            "private_subnet":    "10.0.1.0/24",
            "ec2_private_ip":    settings.aws_ec2_private_ip or "10.0.1.x",
            "region":            settings.aws_region,
        },
        "azure": {
            "vnet_cidr":         "10.1.0.0/16",
            "gateway_subnet":    "10.1.0.0/27",
            "private_subnet":    "10.1.1.0/24",
            "vm_private_ip":     settings.azure_vm_private_ip or "10.1.1.x",
            "location":          "eastus",
        },
        "vpn": {
            "type":              "IPsec IKEv2",
            "protocol":          "Site-to-Site",
            "encryption":        "AES-256",
            "integrity":         "SHA-256",
            "dh_group":          "Group2",
            "tunnel1_cidr":      "169.254.21.0/30",
            "tunnel2_cidr":      "169.254.22.0/30",
        },
        "current_cloud": cloud,
        "other_cloud_ip": settings.other_cloud_ip,
    }
