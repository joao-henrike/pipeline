"""
Exporta todos os routers FastAPI para facilitar o import em main.py.
Uso: from app.routers import status, vpn, connectivity, cloud
"""
from . import status, vpn, connectivity, cloud

__all__ = ["status", "vpn", "connectivity", "cloud"]
