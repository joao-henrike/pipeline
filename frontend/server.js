/**
 * server.js — Node.js Express server para o frontend
 * Serve os arquivos estáticos de /public e faz proxy para a API backend.
 *
 * Em produção o Nginx serve os statics diretamente,
 * mas este servidor é usado em desenvolvimento e como fallback.
 */
const express  = require("express");
const path     = require("path");
const { createProxyMiddleware } = require("http-proxy-middleware");
require("dotenv").config();

const app      = express();
const PORT     = process.env.PORT        || 3000;
const API_URL  = process.env.BACKEND_URL || "http://localhost:8000";

// ── Proxy: /api/* → backend FastAPI
app.use(
  "/api",
  createProxyMiddleware({
    target:       API_URL,
    changeOrigin: true,
    on: {
      error: (err, req, res) => {
        console.error("[proxy] Erro ao contatar backend:", err.message);
        res.status(502).json({ error: "Backend indisponível", detail: err.message });
      },
    },
  })
);

// ── Servir arquivos estáticos de /public
app.use(express.static(path.join(__dirname, "public")));

// ── SPA fallback: todas as rotas retornam index.html
app.get("*", (_req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, "0.0.0.0", () => {
  console.log("╔══════════════════════════════════════╗");
  console.log("║  MultiCloud VPN — Frontend Server    ║");
  console.log(`║  URL:         http://0.0.0.0:${PORT}    ║`);
  console.log(`║  Backend API: ${API_URL}  ║`);
  console.log("╚══════════════════════════════════════╝");
});
