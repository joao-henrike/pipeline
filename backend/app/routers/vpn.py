"""
Router: /api/vpn
Informações e status dos túneis VPN.
"""
from fastapi import APIRouter
from ..config import settings
from ..models import VpnStatus
from ..services import aws_service, azure_service

router = APIRouter(prefix="/api/vpn", tags=["VPN"])


@router.get("/aws", response_model=VpnStatus)
def get_aws_vpn():
    """Status dos túneis VPN no lado AWS (VGW Telemetry)."""
    return aws_service.get_vpn_status()


@router.get("/azure", response_model=VpnStatus)
def get_azure_vpn():
    """Status da conexão VPN no lado Azure."""
    return azure_service.get_vpn_status()


@router.get("/summary")
def vpn_summary():
    """Resumo consolidado do túnel VPN dos dois lados."""
    aws_vpn   = aws_service.get_vpn_status()
    azure_vpn = azure_service.get_vpn_status()
    return {
        "aws": {
            "connection_id":  aws_vpn.connection_id,
            "overall_status": aws_vpn.overall_status,
            "tunnels_up":     sum(1 for t in aws_vpn.tunnels if t.status.value == "UP"),
            "total_tunnels":  len(aws_vpn.tunnels),
        },
        "azure": {
            "connection_id":  azure_vpn.connection_id,
            "overall_status": azure_vpn.overall_status,
            "tunnels_up":     sum(1 for t in azure_vpn.tunnels if t.status.value == "UP"),
        },
        "vpn_active": (
            aws_vpn.overall_status.value == "UP"
            or azure_vpn.overall_status.value == "UP"
        ),
    }
