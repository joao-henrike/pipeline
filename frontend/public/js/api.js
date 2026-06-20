\
/**
 * api.js — Cliente da API FastAPI backend
 *
 * Detecta automaticamente a URL do backend:
 *   1. window.BACKEND_URL (injetado no index.html pelo Terraform/Nginx)
 *   2. /api (proxy via Nginx ou Node.js server)
 */

const BASE_URL = window.BACKEND_URL || "";

class ApiClient {
  constructor(baseUrl) {
    this.base = baseUrl;
  }

  async _get(path) {
    const r = await fetch(`${this.base}${path}`);
    if (!r.ok) throw new Error(`HTTP ${r.status} em ${path}`);
    return r.json();
  }

  async _post(path, body) {
    const r = await fetch(`${this.base}${path}`, {
      method:  "POST",
      headers: { "Content-Type": "application/json" },
      body:    JSON.stringify(body),
    });
    if (!r.ok) throw new Error(`HTTP ${r.status} em ${path}`);
    return r.json();
  }

  // ── Status geral
  status()      { return this._get("/api/status/"); }
  health()      { return this._get("/api/status/health"); }

  // ── VPN
  vpnSummary()  { return this._get("/api/vpn/summary"); }
  vpnAws()      { return this._get("/api/vpn/aws"); }
  vpnAzure()    { return this._get("/api/vpn/azure"); }

  // ── Cloud VMs
  awsVm()       { return this._get("/api/cloud/aws/vm"); }
  azureVm()     { return this._get("/api/cloud/azure/vm"); }
  allVms()      { return this._get("/api/cloud/all"); }

  // ── Conectividade
  topology()    { return this._get("/api/connectivity/topology"); }
  pingPeer(count = 4) {
    return this._get(`/api/connectivity/ping/peer?count=${count}`);
  }
  ping(targetIp, count = 4) {
    return this._post("/api/connectivity/ping", { target_ip: targetIp, count });
  }
  traceroute(targetIp, maxHops = 15) {
    return this._post("/api/connectivity/traceroute", { target_ip: targetIp, max_hops: maxHops });
  }
  portCheck(ip, port) {
    return this._get(`/api/connectivity/port/${ip}/${port}`);
  }
}

window.api = new ApiClient(BASE_URL);
