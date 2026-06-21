"""
Serviço de conectividade de rede.
Executa ping, traceroute e verificação de porta TCP via subprocess.
Funciona em Linux (AWS EC2 / Azure VM Ubuntu).
"""
import asyncio
import re
import logging
from datetime import datetime, timezone
from ..models import PingResult, StatusEnum

logger = logging.getLogger(__name__)


async def ping_host(target_ip: str, count: int = 4, timeout: int = 10) -> PingResult:
    """
    Executa ping ICMP para o host alvo.
    Retorna PingResult com latência, perda de pacotes e output bruto.
    """
    ts = datetime.now(timezone.utc)
    cmd = ["ping", "-c", str(count), "-W", str(timeout), target_ip]

    try:
        proc = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=timeout + 5)
        raw = stdout.decode() + stderr.decode()

        # "4 packets transmitted, 4 received, 0% packet loss"
        sent, recv, loss = count, 0, 100.0
        m = re.search(r"(\d+) packets transmitted, (\d+) received.*?([\d.]+)% packet loss", raw)
        if m:
            sent  = int(m.group(1))
            recv  = int(m.group(2))
            loss  = float(m.group(3))

        # "rtt min/avg/max/mdev = 1.2/2.3/3.4/0.5 ms"
        avg_ms = min_ms = max_ms = None
        m2 = re.search(r"rtt min/avg/max/mdev = ([\d.]+)/([\d.]+)/([\d.]+)", raw)
        if m2:
            min_ms = float(m2.group(1))
            avg_ms = float(m2.group(2))
            max_ms = float(m2.group(3))

        status = StatusEnum.UP if recv > 0 else StatusEnum.DOWN

        return PingResult(
            target_ip=target_ip, packets_sent=sent, packets_received=recv,
            packet_loss_pct=loss, avg_latency_ms=avg_ms, min_latency_ms=min_ms,
            max_latency_ms=max_ms, status=status, raw_output=raw, timestamp=ts,
        )

    except asyncio.TimeoutError:
        return PingResult(
            target_ip=target_ip, packets_sent=count, packets_received=0,
            packet_loss_pct=100.0, avg_latency_ms=None, min_latency_ms=None,
            max_latency_ms=None, status=StatusEnum.DOWN,
            raw_output=f"Timeout após {timeout}s", timestamp=ts,
        )
    except Exception as e:
        logger.error(f"Ping error {target_ip}: {e}")
        return PingResult(
            target_ip=target_ip, packets_sent=count, packets_received=0,
            packet_loss_pct=100.0, avg_latency_ms=None, min_latency_ms=None,
            max_latency_ms=None, status=StatusEnum.DOWN,
            raw_output=str(e), timestamp=ts,
        )


async def traceroute_host(target_ip: str, max_hops: int = 15) -> str:
    """Executa traceroute e retorna output em texto."""
    try:
        proc = await asyncio.create_subprocess_exec(
            "traceroute", "-m", str(max_hops), "-w", "2", target_ip,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
        )
        stdout, stderr = await asyncio.wait_for(proc.communicate(), timeout=60)
        return stdout.decode() + stderr.decode()
    except asyncio.TimeoutError:
        return "Traceroute timeout após 60s"
    except FileNotFoundError:
        return "traceroute não instalado. Execute: sudo apt install traceroute"
    except Exception as e:
        return f"Erro: {e}"


async def check_port(target_ip: str, port: int, timeout: int = 5) -> dict:
    """Verifica se uma porta TCP está acessível no host."""
    ts = datetime.now(timezone.utc)
    try:
        reader, writer = await asyncio.wait_for(
            asyncio.open_connection(target_ip, port), timeout=timeout
        )
        writer.close()
        await writer.wait_closed()
        return {"target": target_ip, "port": port, "open": True, "timestamp": ts.isoformat()}
    except Exception:
        return {"target": target_ip, "port": port, "open": False, "timestamp": ts.isoformat()}
