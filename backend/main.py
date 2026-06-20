"""
MultiCloud VPN Monitor — Backend FastAPI
=========================================
Ponto de entrada da aplicação.

Inicie com:
  uvicorn main:app --host 0.0.0.0 --port 8000 --reload

Endpoints principais:
  GET  /                         → Dashboard (frontend)
  GET  /api/status/              → Status geral do sistema
  GET  /api/status/health        → Health check simples
  GET  /api/vpn/summary          → Resumo VPN dos dois lados
  POST /api/connectivity/ping    → Ping cross-cloud
  GET  /api/connectivity/ping/peer → Ping automático para a outra cloud
  POST /api/connectivity/traceroute → Traceroute
  GET  /api/connectivity/port/{ip}/{port} → Verificação de porta
  GET  /api/connectivity/topology → Topologia de rede
  GET  /api/cloud/aws/vm         → Info EC2 AWS
  GET  /api/cloud/azure/vm       → Info VM Azure
  GET  /docs                     → Swagger UI (documentação interativa)
"""
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.responses import HTMLResponse
from fastapi.middleware.cors import CORSMiddleware
import os
import logging

from app.config import settings
from app.routers import status, vpn, connectivity, cloud

# ── Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

# ── FastAPI App
app = FastAPI(
    title="MultiCloud VPN Monitor",
    description=(
        "Dashboard e API de monitoramento da VPN Site-to-Site AWS ↔ Azure. "
        f"Rodando em: {settings.cloud_provider} | Aluno: {settings.student_name}"
    ),
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# ── CORS — permite o frontend acessar a API de qualquer origem
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Incluir routers
app.include_router(status.router)
app.include_router(vpn.router)
app.include_router(connectivity.router)
app.include_router(cloud.router)

# ── Servir frontend estático
STATIC_DIR = os.path.join(os.path.dirname(__file__), "static")
if os.path.isdir(STATIC_DIR):
    app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")
    logger.info(f"Arquivos estáticos servidos de: {STATIC_DIR}")

TEMPLATES_DIR = os.path.join(os.path.dirname(__file__), "templates")


@app.get("/", response_class=HTMLResponse, include_in_schema=False)
async def serve_dashboard():
    """Serve o dashboard HTML principal."""
    index_path = os.path.join(TEMPLATES_DIR, "index.html")
    if os.path.isfile(index_path):
        with open(index_path, "r", encoding="utf-8") as f:
            return HTMLResponse(content=f.read())
    return HTMLResponse(
        content="<h1>Dashboard não encontrado</h1>"
                "<p>Acesse <a href=/docs>/docs</a> para a API.</p>"
    )


@app.on_event("startup")
async def startup():
    logger.info("=" * 60)
    logger.info(f"  MultiCloud VPN Monitor iniciado")
    logger.info(f"  Cloud Provider : {settings.cloud_provider}")
    logger.info(f"  Student        : {settings.student_name}")
    logger.info(f"  Other Cloud IP : {settings.other_cloud_ip or 'não configurado'}")
    logger.info(f"  Dashboard      : http://0.0.0.0:8000")
    logger.info(f"  API Docs       : http://0.0.0.0:8000/docs")
    logger.info("=" * 60)
