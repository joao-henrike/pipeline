// Mock da Base de Usuários (IAM)
let mockUsuarios = [
    { nome: "Administrador Sistema", email: "admin@techstock.com", funcao: "Administrador", status: "Ativo", ultimoAcesso: "2026-06-23 00:45" },
    { nome: "Erick Sobrinho BI", email: "erick.bi@honeybadger.com", funcao: "Auditor", status: "Ativo", ultimoAcesso: "2026-06-22 17:10" },
    { nome: "Operador Almoxarifado", email: "almox@honeybadger.com", funcao: "Operador", status: "Ativo", ultimoAcesso: "2026-06-21 08:00" },
    { nome: "Antônio Demitido", email: "antonio.ex@honeybadger.com", funcao: "Operador", status: "Inativo", ultimoAcesso: "2026-04-12 11:30" }
];

const tbody = document.getElementById('tabelaUsuarios');
const modal = document.getElementById('modalUsuario');
const form = document.getElementById('formUsuario');
const searchInput = document.getElementById('searchInput');
const filterFuncao = document.getElementById('filterFuncao');

function normalizarTexto(texto) {
    if (!texto) return "";
    return texto.normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase();
}

function renderizarTabela() {
    tbody.innerHTML = '';
    const termoBusca = normalizarTexto(searchInput.value);
    const funcaoFiltro = normalizarTexto(filterFuncao.value);

    const dadosFiltrados = mockUsuarios.filter(user => {
        const matchBusca = normalizarTexto(user.nome).includes(termoBusca) || normalizarTexto(user.email).includes(termoBusca);
        const matchFuncao = funcaoFiltro === 'all' || normalizarTexto(user.funcao) === funcaoFiltro;
        return matchBusca && matchFuncao;
    });

    dadosFiltrados.forEach((user) => {
        const originalIndex = mockUsuarios.indexOf(user);
        const classFuncao = user.funcao.toLowerCase();
        const classStatus = user.status.toLowerCase();

        const tr = document.createElement('tr');
        tr.innerHTML = `
            <td><strong>${user.nome}</strong></td>
            <td>${user.email}</td>
            <td><span class="badge-funcao ${classFuncao}">${user.funcao}</span></td>
            <td><span class="status-user ${classStatus}">${user.status}</span></td>
            <td style="color: var(--text-muted); font-size: 0.85rem;">${user.ultimoAcesso}</td>
            <td>
                <button class="btn-action" onclick="editarUsuario(${originalIndex})" title="Editar"><i class="fas fa-user-edit"></i></button>
                <button class="btn-action" onclick="excluirUsuario(${originalIndex})" title="Excluir"><i class="fas fa-user-slash"></i></button>
            </td>
        `;
        tbody.appendChild(tr);
    });
}

searchInput.addEventListener('input', renderizarTabela);
filterFuncao.addEventListener('change', renderizarTabela);

function abrirModal(isEdit = false) {
    document.getElementById('modalTitle').innerText = isEdit ? 'Editar Permissões do Usuário' : 'Adicionar Novo Usuário';
    modal.classList.remove('hidden');
}

function fecharModal() {
    modal.classList.add('hidden');
    form.reset();
    document.getElementById('userIndex').value = '-1';
}

document.getElementById('btnNovoUsuario').addEventListener('click', () => abrirModal(false));
document.getElementById('btnFecharModal').addEventListener('click', fecharModal);
document.getElementById('btnCancelar').addEventListener('click', fecharModal);

form.addEventListener('submit', (e) => {
    e.preventDefault();
    const index = parseInt(document.getElementById('userIndex').value);

    const usuarioDados = {
        nome: document.getElementById('inputNome').value,
        email: document.getElementById('inputEmail').value,
        funcao: document.getElementById('inputFuncao').value,
        status: document.getElementById('inputStatus').value,
        ultimoAcesso: index === -1 ? "Nunca" : mockUsuarios[index].ultimoAcesso
    };

    if (index === -1) {
        mockUsuarios.push(usuarioDados);
    } else {
        mockUsuarios[index] = usuarioDados;
    }

    renderizarTabela();
    fecharModal();
});

window.editarUsuario = function(index) {
    const user = mockUsuarios[index];
    document.getElementById('userIndex').value = index;
    document.getElementById('inputNome').value = user.nome;
    document.getElementById('inputEmail').value = user.email;
    document.getElementById('inputFuncao').value = user.funcao;
    document.getElementById('inputStatus').value = user.status;
    abrirModal(true);
};

window.excluirUsuario = function(index) {
    if (confirm(`Revogar permanentemente o acesso de ${mockUsuarios[index].nome}?`)) {
        mockUsuarios.splice(index, 1);
        renderizarTabela();
    }
};

document.addEventListener('DOMContentLoaded', renderizarTabela);
