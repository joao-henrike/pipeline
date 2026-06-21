"""
Router: /api/status
Status geral do sistema multi-cloud.
"""
from fastapi import APIRouter
from datetime import datetime, timezone
from ..config import settings
from ..models import SystemStatus, StatusEnum
from ..services import aws_service, azure_service, network_service

router = APIRouter(prefix="/api/status", tags=["Status"])


@router.get("/", response_model=SystemStatus)
async def get_system_status():
    """
    Retorna o status geral do sistema:
    - VPN tunnel (AWS)
    - AWS EC2 VM
    - Azure VM
    - Ping cross-cloud
    """
    cloud = settings.cloud_provider.upper()
    other_ip = settings.other_cloud_ip

    # VPN status
    vpn_status = StatusEnum.UNKNOWN
    if cloud == "AWS":
        vpn = aws_service.get_vpn_status()
        vpn_status = vpn.overall_status
    elif cloud == "AZURE":
        vpn = azure_service.get_vpn_status()
        vpn_status = vpn.overall_status

    # VM status
    aws_vm_status   = aws_service.get_ec2_info().state
    azure_vm_status = azure_service.get_vm_info().state

    # Cross-cloud ping
    ping_status = StatusEnum.UNKNOWN
    if other_ip:
        result = await network_service.ping_host(other_ip, count=2, timeout=5)
        ping_status = result.status

    overall = (
        StatusEnum.UP
        if all(s == StatusEnum.UP for s in [vpn_status, ping_status])
        else StatusEnum.DOWN
        if StatusEnum.DOWN in [vpn_status, ping_status]
        else StatusEnum.UNKNOWN
    )

    return SystemStatus(
        overall=overall,
        vpn_tunnel=vpn_status,
        aws_vm=aws_vm_status,
        azure_vm=azure_vm_status,
        cross_cloud_ping=ping_status,
        last_updated=datetime.now(timezone.utc),
        student_name=settings.student_name,
        cloud_running_on=cloud,
    )


@router.get("/health")
async def health_check():
    """Health check simples — usado pelo load balancer e Terraform."""
    return {
        "status": "healthy",
        "cloud": settings.cloud_provider,
        "student": settings.student_name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
