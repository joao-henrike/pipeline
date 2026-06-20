"""
Exporta todos os services para facilitar imports nos routers.
Uso: from app.services import aws_service, azure_service, network_service
"""
from . import aws_service, azure_service, network_service

__all__ = ["aws_service", "azure_service", "network_service"]
