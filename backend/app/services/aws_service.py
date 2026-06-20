"""
Serviço de integração com AWS usando boto3.
Consulta EC2, VPN e status de rede.
"""
import boto3
import logging
from typing import Optional, Dict, Any
from datetime import datetime, timezone
from ..config import settings
from ..models import VMInfo, VpnStatus, VpnTunnel, StatusEnum

logger = logging.getLogger(__name__)


def _get_ec2_client():
    return boto3.client("ec2", region_name=settings.aws_region)


def get_ec2_info() -> VMInfo:
    """Retorna informações da instância EC2 privada."""
    try:
        client = _get_ec2_client()
        instance_id = settings.aws_ec2_instance_id

        if not instance_id:
            return VMInfo(
                cloud="AWS", state=StatusEnum.UNKNOWN,
                private_ip=settings.aws_ec2_private_ip,
                region_or_location=settings.aws_region,
            )

        resp = client.describe_instances(InstanceIds=[instance_id])
        inst = resp["Reservations"][0]["Instances"][0]

        state_map = {
            "running": StatusEnum.UP,
            "stopped": StatusEnum.DOWN,
            "pending": StatusEnum.PENDING,
        }
        state = state_map.get(inst["State"]["Name"], StatusEnum.UNKNOWN)

        # Calcular uptime se running
        uptime = None
        if inst["State"]["Name"] == "running":
            launch_time = inst["LaunchTime"].replace(tzinfo=timezone.utc)
            now = datetime.now(timezone.utc)
            uptime = (now - launch_time).total_seconds() / 3600

        # Obter nome da tag
        name = next(
            (t["Value"] for t in inst.get("Tags", []) if t["Key"] == "Name"),
            instance_id,
        )

        return VMInfo(
            cloud="AWS",
            instance_id=instance_id,
            name=name,
            private_ip=inst.get("PrivateIpAddress"),
            public_ip=inst.get("PublicIpAddress"),
            state=state,
            region_or_location=settings.aws_region,
            instance_type=inst.get("InstanceType"),
            os="Amazon Linux 2",
            uptime_hours=round(uptime, 2) if uptime else None,
        )
    except Exception as e:
        logger.error(f"Erro ao consultar EC2: {e}")
        return VMInfo(
            cloud="AWS",
            instance_id=settings.aws_ec2_instance_id,
            private_ip=settings.aws_ec2_private_ip,
            state=StatusEnum.UNKNOWN,
            region_or_location=settings.aws_region,
        )


def get_vpn_status() -> VpnStatus:
    """Retorna o status dos túneis VPN AWS."""
    try:
        client = _get_ec2_client()
        conn_id = settings.aws_vpn_connection_id

        if not conn_id:
            return VpnStatus(
                cloud="AWS", connection_id=None,
                tunnels=[], overall_status=StatusEnum.UNKNOWN,
            )

        resp = client.describe_vpn_connections(VpnConnectionIds=[conn_id])
        conn = resp["VpnConnections"][0]

        tunnels = []
        for vgwt in conn.get("VgwTelemetry", []):
            status = (
                StatusEnum.UP
                if vgwt["Status"] == "UP"
                else StatusEnum.DOWN
            )
            tunnels.append(
                VpnTunnel(
                    tunnel_id=vgwt.get("OutsideIpAddress", "unknown"),
                    outside_ip=vgwt.get("OutsideIpAddress", ""),
                    inside_cidr=vgwt.get("InsideCidr", ""),
                    status=status,
                    last_change=str(vgwt.get("LastStatusChange", "")),
                )
            )

        overall = (
            StatusEnum.UP
            if any(t.status == StatusEnum.UP for t in tunnels)
            else StatusEnum.DOWN
        )

        return VpnStatus(
            cloud="AWS",
            connection_id=conn_id,
            tunnels=tunnels,
            overall_status=overall,
        )
    except Exception as e:
        logger.error(f"Erro ao consultar VPN AWS: {e}")
        return VpnStatus(
            cloud="AWS", connection_id=settings.aws_vpn_connection_id,
            tunnels=[], overall_status=StatusEnum.UNKNOWN,
        )
