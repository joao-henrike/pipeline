// Mock do Log de Auditoria
let mockMovimentacoes = [
    { data: "2026-06-23 09:15", tipo: "Saída", sku: "CAB-993", qtd: 2, destino: "Infra - Rack 03", operador: "Admin" },
    { data: "2026-06-22 14:30", tipo: "Entrada", sku: "MON-112", qtd: 5, destino: "Compra Fornecedor", operador: "Admin" },
    { data: "2026-06-22 10:05", tipo: "Saída", sku: "SWT-042", qtd: 1, destino: "Manutenção", operador: "Admin" }
];

const tbody = document.getElementById('tabelaMovimentacoes');
const modal = document.getElementById('modalMov');
const form = document.getElementById('formMovimentacao');
const searchInput = document.getElementById('searchInput');
const filterTipo = document.getElementById('filterTipo');

// Função cirúrgica para remover acentos e ignorar maiúsculas/minúsculas
function normalizarTexto(texto) {
    if (!texto) return "";
    return texto.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function renderizarTabela() {
    tbody.innerHTML = ''; 
    const termoBusca = normalizarTexto(searchInput.value);
    const tipoFiltro = normalizarTexto(filterTipo.value); // 'all', 'entrada', ou 'saida'

    const dadosFiltrados = mockMovimentacoes.filter(item => {
        // Busca ignorando acentos no SKU e no Destino
        const buscaSku = normalizarTexto(item.sku).includes(termoBusca);
        const buscaDestino = normalizarTexto(item.destino).includes(termoBusca);
        const matchBusca = buscaSku || buscaDestino;

        // Filtro exato de tipo (Saída vira saida, Entrada vira entrada)
        const tipoItem = normalizarTexto(item.tipo);
        const matchTipo = tipoFiltro === 'all' || tipoItem === tipoFiltro;

        return matchBusca && matchTipo;
    });

    dadosFiltrados.forEach((item) => {
        const tagClass = item.tipo === 'Entrada' ? 'entrada' : 'saida';

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td>${item.data}</td>
            <td><span class="tag-tipo ${tagClass}">${item.tipo}</span></td>
            <td><strong>${item.sku}</strong></td>
            <td>${item.qtd}</td>
            <td>${item.destino}</td>
            <td style="color: var(--text-muted);">${item.operador}</td>
        `;
        tbody.appendChild(tr);
    });
}

// Filtros em Tempo Real
searchInput.addEventListener('input', renderizarTabela);
filterTipo.addEventListener('change', renderizarTabela);

// Lógica do Modal
document.getElementById('btnNovaMovimentacao').addEventListener('click', () => {
    modal.classList.remove('hidden');
});

function fecharModal() {
    modal.classList.add('hidden');
    form.reset();
}

document.getElementById('btnFecharModal').addEventListener('click', fecharModal);
document.getElementById('btnCancelar').addEventListener('click', fecharModal);

form.addEventListener('submit', (e) => {
    e.preventDefault();

    // Captura a data de forma robusta e formata para o padrão visual
    const agora = new Date();
    const ano = agora.getFullYear();
    const mes = String(agora.getMonth() + 1).padStart(2, '0');
    const dia = String(agora.getDate()).padStart(2, '0');
    const hora = String(agora.getHours()).padStart(2, '0');
    const min = String(agora.getMinutes()).padStart(2, '0');
    const dataFormatada = `${ano}-${mes}-${dia} ${hora}:${min}`;

    const novaMov = {
        data: dataFormatada,
        tipo: document.getElementById('inputTipo').value, // Vem do HTML: 'Entrada' ou 'Saída'
        sku: document.getElementById('inputSku').value.toUpperCase(), // Força SKU para Maiúsculo
        qtd: parseInt(document.getElementById('inputQtd').value),
        destino: document.getElementById('inputDestino').value,
        operador: "Admin (Sessão Atual)"
    };

    // Adiciona no topo do Array (Log mais recente primeiro)
    mockMovimentacoes.unshift(novaMov);
    
    renderizarTabela();
    fecharModal();
});

document.addEventListener('DOMContentLoaded', renderizarTabela);
