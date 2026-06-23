// O "Banco de Dados" na memória do navegador
let mockInventario = [
    { sku: "SRV-001", nome: "Servidor Dell PowerEdge R740", categoria: "Hardware", qtd: 2, local: "Rack 01 - U12" },
    { sku: "SWT-042", nome: "Switch Cisco Catalyst 9300", categoria: "Rede", qtd: 5, local: "Rack 02 - U04" },
    { sku: "CAB-993", nome: "Cabo Fibra Óptica LC/LC 5m", categoria: "Rede", qtd: 3, local: "Gaveta 4" }
];

// Mapeamento dos elementos da tela
const tbody = document.getElementById('tabelaInventario');
const modal = document.getElementById('modalAtivo');
const form = document.getElementById('formAtivo');
const searchInput = document.getElementById('searchInput');
const filterCategory = document.getElementById('filterCategory');

// Renderiza a tabela aplicando os filtros de busca e categoria
function renderizarTabela() {
    tbody.innerHTML = ''; 
    
    const termoBusca = searchInput.value.toLowerCase();
    const categoriaFiltro = filterCategory.value.toLowerCase();

    // Filtra o array antes de desenhar a tabela
    const dadosFiltrados = mockInventario.filter(item => {
        const matchBusca = item.sku.toLowerCase().includes(termoBusca) || item.nome.toLowerCase().includes(termoBusca);
        const matchCategoria = categoriaFiltro === 'all' || item.categoria.toLowerCase() === categoriaFiltro;
        return matchBusca && matchCategoria;
    });

    dadosFiltrados.forEach((item) => {
        // Captura o índice real do item no array original para não bugar a edição/exclusão
        const originalIndex = mockInventario.indexOf(item);
        
        const isCritico = item.qtd < 3;
        const statusClass = isCritico ? 'critico' : 'ok';
        const statusText = isCritico ? 'Baixo Estoque' : 'Estoque OK';

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${item.sku}</strong></td>
            <td>${item.nome}</td>
            <td>${item.categoria}</td>
            <td>${item.qtd}</td>
            <td>${item.local}</td>
            <td><span class="status ${statusClass}">${statusText}</span></td>
            <td>
                <button class="btn-action" onclick="editarItem(${originalIndex})" title="Editar"><i class="fas fa-edit"></i></button>
                <button class="btn-action" onclick="excluirItem(${originalIndex})" title="Excluir"><i class="fas fa-trash"></i></button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

// Gatilhos de Busca em Tempo Real
searchInput.addEventListener('input', renderizarTabela);
filterCategory.addEventListener('change', renderizarTabela);

// Lógica de Abrir/Fechar Modal
function abrirModal(isEdit = false) {
    document.getElementById('modalTitle').innerText = isEdit ? 'Editar Ativo' : 'Adicionar Novo Ativo';
    modal.classList.remove('hidden');
}

function fecharModal() {
    modal.classList.add('hidden');
    form.reset();
    document.getElementById('itemIndex').value = '-1';
}

// Eventos de clique nos botões do Modal
document.getElementById('btnNovoAtivo').addEventListener('click', () => abrirModal(false));
document.getElementById('btnFecharModal').addEventListener('click', fecharModal);
document.getElementById('btnCancelar').addEventListener('click', fecharModal);

// Lógica de Salvar (Create e Update)
form.addEventListener('submit', (e) => {
    e.preventDefault();

    const index = parseInt(document.getElementById('itemIndex').value);
    const novoAtivo = {
        sku: document.getElementById('inputSku').value,
        nome: document.getElementById('inputNome').value,
        categoria: document.getElementById('inputCategoria').value,
        qtd: parseInt(document.getElementById('inputQtd').value),
        local: document.getElementById('inputLocal').value
    };

    if (index === -1) {
        mockInventario.push(novoAtivo);
    } else {
        mockInventario[index] = novoAtivo;
    }

    renderizarTabela();
    fecharModal();
});

// Ações nas linhas da Tabela (Update e Delete)
window.editarItem = function(index) {
    const item = mockInventario[index];
    document.getElementById('itemIndex').value = index;
    document.getElementById('inputSku').value = item.sku;
    document.getElementById('inputNome').value = item.nome;
    document.getElementById('inputCategoria').value = item.categoria;
    document.getElementById('inputQtd').value = item.qtd;
    document.getElementById('inputLocal').value = item.local;
    abrirModal(true);
};

window.excluirItem = function(index) {
    if(confirm(`Tem certeza que deseja excluir o item ${mockInventario[index].sku}?`)) {
        mockInventario.splice(index, 1);
        renderizarTabela();
    }
};

// Inicializa a tela com os dados carregados
document.addEventListener('DOMContentLoaded', renderizarTabela);
