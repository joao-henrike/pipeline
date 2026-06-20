"""
Serviço de integração com Azure usando azure-sdk-for-python.
"""
import logging
from typing import Optional
from ..config import settings
from ..models import VMInfo, VpnStatus, VpnTunnel, StatusEnum

logger = logging.getLogger(__name__)


def _get_clients():
    from azure.identity import DefaultAzureCredential, ManagedIdentityCredential
    from azure.mgmt.compute import ComputeManagementClient
    from azure.mgmt.network import NetworkManagementClient

    try:
        cred = DefaultAzureCredential()
    except Exception:
        cred = ManagedIdentityCredential()

    sub = settings.azure_subscription_id
    return (
        ComputeManagementClient(cred, sub),
        NetworkManagementClient(cred, sub),
    )


def get_vm_info() -> VMInfo:
    """Retorna informações da VM Azure."""
    try:
        compute_client, network_client = _get_clients()
        rg   = settings.azure_resource_group
        name = settings.azure_vm_name

        if not rg or not name:
            return VMInfo(
                cloud="Azure", state=StatusEnum.UNKNOWN,
                private_ip=settings.azure_vm_private_ip,
            )

        vm = compute_client.virtual_machines.get(rg, name, expand="instanceView")
        iview = vm.instance_view

        state_map = {
            "running":      StatusEnum.UP,
            "stopped":      StatusEnum.DOWN,
            "deallocated":  StatusEnum.DOWN,
            "starting":     StatusEnum.PENDING,
        }
        power_state = next(
            (s.code.split("/")[1] for s in iview.statuses
             if s.code.startswith("PowerState/")),
            "unknown",
        )
        state = state_map.get(power_state, StatusEnum.UNKNOWN)

        return VMInfo(
            cloud="Azure",
            instance_id=vm.vm_id,
            name=vm.name,
            private_ip=settings.azure_vm_private_ip,
            state=state,
            region_or_location=vm.location,
            instance_type=vm.hardware_profile.vm_size,
            os="Ubuntu 20.04 LTS",
        )
    except Exception as e:
        logger.error(f"Erro ao consultar VM Azure: {e}")
        return VMInfo(
            cloud="Azure",
            name=settings.azure_vm_name,
            private_ip=settings.azure_vm_private_ip,
            state=StatusEnum.UNKNOWN,
        )


def get_vpn_status() -> VpnStatus:
    """Retorna o status da conexão VPN Azure."""
    try:
        _, network_client = _get_clients()
        rg   = settings.azure_resource_group
        name = settings.azure_vpn_connection_name

        if not rg or not name:
            return VpnStatus(
                cloud="Azure", connection_id=None,
                tunnels=[], overall_status=StatusEnum.UNKNOWN,
            )

        conn = network_client.virtual_network_gateway_connections.get(rg, name)
        state_map = {
            "Connected":    StatusEnum.UP,
            "Disconnected": StatusEnum.DOWN,
            "Connecting":   StatusEnum.PENDING,
        }
        overall = state_map.get(conn.connection_status, StatusEnum.UNKNOWN)

        return VpnStatus(
            cloud="Azure",
            connection_id=conn.name,
            tunnels=[
                VpnTunnel(
                    tunnel_id=conn.name,
                    outside_ip=conn.local_network_gateway2.gateway_ip_address
                    if conn.local_network_gateway2 else "",
                    inside_cidr="",
                    status=overall,
                    last_change=None,
                )
            ],
            overall_status=overall,
        )
    except Exception as e:
        logger.error(f"Erro ao consultar VPN Azure: {e}")
        return VpnStatus(
            cloud="Azure", connection_id=settings.azure_vpn_connection_name,
            tunnels=[], overall_status=StatusEnum.UNKNOWN,
        )
