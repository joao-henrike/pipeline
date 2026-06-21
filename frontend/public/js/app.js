\
/**
 * app.js — Lógica principal do dashboard MultiCloud VPN Monitor
 * Depende de: api.js (window.api)
 */

"use strict";

// ── Estado global
const state = {
  latencies: [],
  refreshInterval: null,
  activeTab: "overview",
};

// ── Utilitários DOM
const $ = (id) => document.getElementById(id);
const ts = () => new Date().toLocaleTimeString("pt-BR");

const STATUS_CLASS = { UP:"up", DOWN:"down", UNKNOWN:"unknown", PENDING:"pending" };
const STATUS_EMOJI = { UP:"🟢", DOWN:"🔴", UNKNOWN:"🟡", PENDING:"🔵" };

function cls(s) { return STATUS_CLASS[(s||"").toUpperCase()] || "unknown"; }
function emo(s) { return STATUS_EMOJI[(s||"").toUpperCase()] || "🟡"; }

function badge(status, label) {
  const c = cls(status);
  return `<span class="badge ${c}"><span class="dot ${c}"></span>${label||status}</span>`;
}

function setBadge(id, status, label) {
  const el = $(id);
  if (el) el.innerHTML = badge(status, label || status);
}

function setText(id, text) {
  const el = $(id);
  if (el) el.textContent = text || "—";
}

function setHTML(id, html) {
  const el = $(id);
  if (el) el.innerHTML = html;
}

// ── Log de terminal
function log(msg, type = "info") {
  const box = $("log-box");
  if (!box) return;
  const span = document.createElement("span");
  span.innerHTML = `<span class="log-ts">[${ts()}]</span> <span class="log-${type}">${msg}</span>\n`;
  box.appendChild(span);
  box.scrollTop = box.scrollHeight;
}

function clearLog() {
  const b = $("log-box");
  if (b) b.innerHTML = '<span class="log-info">── Log limpo ──\n</span>';
}

// ── Sparkline de latência
function pushLatency(ms) {
  if (ms == null) return;
  state.latencies.push(ms);
  if (state.latencies.length > 12) state.latencies.shift();
  const sl = $("sparkline");
  if (!sl) return;
  const max = Math.max(...state.latencies, 1);
  sl.innerHTML = state.latencies.map(v => {
    const pct = Math.max(6, (v / max) * 100);
    const col = v < 10 ? "var(--green)" : v < 80 ? "var(--azure)" : "var(--yellow)";
    return `<div class="spark-bar" style="height:${pct}%;background:${col}" title="${v.toFixed(1)}ms"></div>`;
  }).join("");
}

// ══ CARREGADORES ══════════════════════════════════════════════

async function loadStatus() {
  try {
    const d = await window.api.status();
    setBadge("stat-overall",  d.overall);
    setBadge("stat-vpn",      d.vpn_tunnel);
    setBadge("stat-ping",     d.cross_cloud_ping);
    setBadge("stat-aws-vm",   d.aws_vm);
    setText("stat-student",   `${d.student_name} · ${d.cloud_running_on}`);
    $("last-refresh").textContent = `Atualizado às ${ts()}`;
  } catch (e) {
    $("last-refresh").textContent = `Erro: ${e.message}`;
  }
}

async function loadVms() {
  try {
    const [aws, az] = await Promise.all([
      window.api.awsVm().catch(() => ({})),
      window.api.azureVm().catch(() => ({})),
    ]);

    setBadge("aws-vm-badge",   aws.state, aws.state);
    setText("aws-private-ip",  aws.private_ip);
    setText("aws-region",      aws.region_or_location);
    setText("aws-type",        aws.instance_type);
    setText("aws-os",          aws.os || "Amazon Linux 2");
    setText("aws-uptime",      aws.uptime_hours != null ? `${aws.uptime_hours.toFixed(1)}h` : "—");

    setBadge("az-vm-badge",    az.state, az.state);
    setText("az-private-ip",   az.private_ip);
    setText("az-location",     az.region_or_location);
    setText("az-type",         az.instance_type);
    setText("az-os",           az.os || "Ubuntu 20.04 LTS");

    // Preencher campos de teste com os IPs detectados
    if (az.private_ip && !$("ping-target")?.value)
      $("ping-target").value = az.private_ip;

    // Atualizar topologia
    setText("topo-aws-ip",   aws.private_ip || "10.0.1.x");
    setText("topo-azure-ip", az.private_ip  || "10.1.1.x");
  } catch (e) { console.error("loadVms:", e); }
}

async function loadVpn() {
  try {
    const d = await window.api.vpnSummary();
    setText("vpn-aws-conn",    d.aws?.connection_id  || "—");
    setText("vpn-aws-tunnels", `${d.aws?.tunnels_up ?? "?"} / ${d.aws?.total_tunnels ?? "?"} UP`);
    setText("vpn-az-conn",     d.azure?.connection_id || "—");
    setBadge("vpn-az-status",  d.azure?.overall_status, d.azure?.overall_status);

    // Linha do diagrama de topologia
    const line = $("tunnel-line");
    if (line) {
      if (d.vpn_active) {
        line.className = "tunnel-line";
      } else {
        line.className = "tunnel-line inactive";
      }
    }
  } catch (e) { console.error("loadVpn:", e); }
}

// ══ TESTES DE CONECTIVIDADE ════════════════════════════════════

async function runPing() {
  const target = $("ping-target")?.value?.trim();
  const count  = parseInt($("ping-count")?.value) || 4;
  if (!target) { log("⚠ Digite um IP alvo", "fail"); return; }

  const btn = $("btn-ping");
  if (btn) btn.disabled = true;
  log(`Executando ping -c ${count} ${target} ...`, "info");

  try {
    const d = await window.api.ping(target, count);
    const ok = d.status === "UP";
    log(
      `${ok ? "✓" : "✗"} ${d.target_ip} — ` +
      `${d.packets_received}/${d.packets_sent} pkts — ` +
      `perda: ${d.packet_loss_pct}% — ` +
      `lat: ${d.avg_latency_ms != null ? d.avg_latency_ms.toFixed(2)+"ms" : "N/A"}`,
      ok ? "ok" : "fail"
    );
    if (d.raw_output) log(d.raw_output.trim(), "info");
    pushLatency(d.avg_latency_ms);
  } catch (e) {
    log(`Erro: ${e.message}`, "fail");
  } finally {
    if (btn) btn.disabled = false;
  }
}

async function runPingPeer() {
  const btn = $("btn-ping-peer");
  if (btn) btn.disabled = true;
  log("Ping automático para o peer (outra cloud)...", "info");
  try {
    const d = await window.api.pingPeer(4);
    const ok = d.status === "UP";
    log(
      `${ok ? "✓ VPN ATIVA" : "✗ VPN INATIVA"} — ${d.target_ip} — ` +
      `lat: ${d.avg_latency_ms != null ? d.avg_latency_ms.toFixed(2)+"ms" : "N/A"}`,
      ok ? "ok" : "fail"
    );
    pushLatency(d.avg_latency_ms);
  } catch (e) {
    log(`Erro: ${e.message}`, "fail");
  } finally {
    if (btn) btn.disabled = false;
  }
}

async function runTraceroute() {
  const target = $("trace-target")?.value?.trim();
  if (!target) return;
  const out = $("trace-output");
  if (out) out.textContent = "Executando traceroute... (até 30s)";
  try {
    const d = await window.api.traceroute(target);
    if (out) out.textContent = d.output || "Sem resultado";
  } catch (e) {
    if (out) out.textContent = `Erro: ${e.message}`;
  }
}

async function runPortCheck() {
  const ip   = $("port-ip")?.value?.trim();
  const port = $("port-num")?.value?.trim();
  const res  = $("port-result");
  if (!ip || !port || !res) return;
  res.textContent = "Verificando...";
  try {
    const d = await window.api.portCheck(ip, port);
    res.style.color = d.open ? "var(--green)" : "var(--red)";
    res.textContent = d.open
      ? `✓ ${ip}:${port} ACESSÍVEL via VPN`
      : `✗ ${ip}:${port} NÃO acessível`;
  } catch (e) {
    res.textContent = `Erro: ${e.message}`;
  }
}

// ══ TABS ═══════════════════════════════════════════════════════

function switchTab(name) {
  document.querySelectorAll(".tab").forEach(t => {
    t.classList.toggle("active", t.dataset.tab === name);
  });
  document.querySelectorAll(".tab-panel").forEach(p => {
    p.classList.toggle("active", p.id === `panel-${name}`);
  });
  state.activeTab = name;
}

// ══ BOOTSTRAP ══════════════════════════════════════════════════

async function loadAll() {
  await Promise.allSettled([loadStatus(), loadVms(), loadVpn()]);
}

function startAutoRefresh(intervalSec = 30) {
  if (state.refreshInterval) clearInterval(state.refreshInterval);
  state.refreshInterval = setInterval(loadAll, intervalSec * 1000);
  const el = $("refresh-countdown");
  if (!el) return;
  let rem = intervalSec;
  const tick = setInterval(() => {
    rem--;
    el.textContent = `Próximo refresh: ${rem}s`;
    if (rem <= 0) rem = intervalSec;
  }, 1000);
}

document.addEventListener("DOMContentLoaded", () => {
  // Setup tabs
  document.querySelectorAll(".tab").forEach(t => {
    t.addEventListener("click", () => switchTab(t.dataset.tab));
  });

  // Setup botões
  $("btn-ping")?.addEventListener("click",      runPing);
  $("btn-ping-peer")?.addEventListener("click", runPingPeer);
  $("btn-trace")?.addEventListener("click",     runTraceroute);
  $("btn-port")?.addEventListener("click",      runPortCheck);
  $("btn-clear-log")?.addEventListener("click", clearLog);
  $("btn-refresh")?.addEventListener("click",   loadAll);

  // Enter key nos campos de input
  [$("ping-target"), $("ping-count")].forEach(el =>
    el?.addEventListener("keydown", e => e.key === "Enter" && runPing())
  );
  $("trace-target")?.addEventListener("keydown", e => e.key === "Enter" && runTraceroute());

  // Iniciar
  loadAll();
  startAutoRefresh(30);
});
