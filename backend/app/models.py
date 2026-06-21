"""
Modelos Pydantic para as respostas da API.
"""
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
from enum import Enum

class StatusEnum(str, Enum):
    UP      = "UP"
    DOWN    = "DOWN"
    UNKNOWN = "UNKNOWN"
    PENDING = "PENDING"

class PingResult(BaseModel):
    target_ip: str
    packets_sent: int
    packets_received: int
    packet_loss_pct: float
    avg_latency_ms: Optional[float]
    min_latency_ms: Optional[float]
    max_latency_ms: Optional[float]
    status: StatusEnum
    raw_output: str
    timestamp: datetime

class VpnTunnel(BaseModel):
    tunnel_id: str
    outside_ip: str
    inside_cidr: str
    status: StatusEnum
    last_change: Optional[str]

class VpnStatus(BaseModel):
    cloud: str
    connection_id: Optional[str]
    tunnels: List[VpnTunnel]
    overall_status: StatusEnum

class VMInfo(BaseModel):
    cloud: str
    instance_id: Optional[str]
    name: Optional[str]
    private_ip: Optional[str]
    public_ip: Optional[str]
    state: StatusEnum
    region_or_location: Optional[str]
    instance_type: Optional[str]
    os: Optional[str]
    uptime_hours: Optional[float]

class NetworkTopology(BaseModel):
    aws_vpc_cidr: str
    azure_vnet_cidr: str
    aws_private_subnet: str
    azure_private_subnet: str
    vpn_tunnel1_ip: Optional[str]
    vpn_tunnel2_ip: Optional[str]
    azure_vpn_gw_ip: Optional[str]

class SystemStatus(BaseModel):
    overall: StatusEnum
    vpn_tunnel: StatusEnum
    aws_vm: StatusEnum
    azure_vm: StatusEnum
    cross_cloud_ping: StatusEnum
    last_updated: datetime
    student_name: str
    cloud_running_on: str
