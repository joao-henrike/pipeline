"""
Configuração central via variáveis de ambiente.
Usa pydantic-settings para validação automática.
"""
from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    cloud_provider: str = "AWS"           # "AWS" ou "AZURE"
    student_name: str = "student"

    # AWS
    aws_region: str = "us-east-1"
    aws_ec2_instance_id: Optional[str] = None
    aws_ec2_private_ip: Optional[str] = None
    aws_vpn_connection_id: Optional[str] = None
    aws_vgw_id: Optional[str] = None

    # Azure
    azure_subscription_id: Optional[str] = None
    azure_resource_group: Optional[str] = None
    azure_vm_name: Optional[str] = None
    azure_vm_private_ip: Optional[str] = None
    azure_vpn_connection_name: Optional[str] = None

    # Conectividade cruzada
    other_cloud_ip: Optional[str] = None

    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()
