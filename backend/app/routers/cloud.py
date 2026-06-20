"""
Router: /api/cloud
Informações das VMs em cada cloud.
"""
from fastapi import APIRouter
from ..models import VMInfo
from ..services import aws_service, azure_service

router = APIRouter(prefix="/api/cloud", tags=["Cloud"])


@router.get("/aws/vm", response_model=VMInfo)
def get_aws_vm():
    """Retorna informações da EC2 privada na AWS."""
    return aws_service.get_ec2_info()


@router.get("/azure/vm", response_model=VMInfo)
def get_azure_vm():
    """Retorna informações da VM Linux no Azure."""
    return azure_service.get_vm_info()


@router.get("/all")
def get_all_vms():
    """Retorna informações das VMs de ambas as clouds em uma única chamada."""
    return {
        "aws":   aws_service.get_ec2_info(),
        "azure": azure_service.get_vm_info(),
    }
