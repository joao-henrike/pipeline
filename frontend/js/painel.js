document.addEventListener("DOMContentLoaded", () => {
    
    const sidebar = document.getElementById('sidebar');
    const btnCollapse = document.getElementById('btn-collapse');
    const navItems = document.querySelectorAll('.nav-item');
    const workspaceArea = document.getElementById('workspace-area');
    const titleHeader = document.getElementById('current-module-title');

    // ==========================================
    // 1. CONTROLES DE INTERFACE (UI)
    // ==========================================
    
    // Recolher/Expandir Sidebar
    btnCollapse.addEventListener('click', () => {
        sidebar.classList.toggle('collapsed');
    });

    // Command Palette Mock (Ctrl+K)
    document.addEventListener('keydown', (e) => {
        if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
            e.preventDefault();
            // Na versão final, aqui abriria um Modal central sobreposto
            alert("Command Palette acionado. A integração de busca global (Elasticsearch/Azure) será implementada em breve.");
        }
    });

    document.getElementById('cmd-palette-trigger').addEventListener('click', () => {
        alert("Command Palette acionado. Utilize Ctrl+K no teclado.");
    });

    // ==========================================
    // 2. ROTEADOR SPA (SINGLE PAGE APPLICATION)
    // ==========================================
    
    const renderSkeleton = () => {
        return `
            <div class="skeleton-wrapper fade-in">
                <div class="skeleton-header"></div>
                <div class="skeleton-toolbar">
                    <div class="skeleton-search"></div>
                    <div class="skeleton-btn"></div>
                    <div class="skeleton-btn" style="width: 140px;"></div>
                </div>
                <div class="skeleton-table">
                    ${Array(6).fill().map(() => `
                        <div class="skeleton-row">
                            <div class="skeleton-cell w-id"></div>
                            <div class="skeleton-cell w-desc"></div>
                            <div class="skeleton-cell w-qty"></div>
                            <div class="skeleton-cell w-id"></div>
                        </div>
                    `).join('')}
                </div>
            </div>
        `;
    };

    const carregarModulo = async (paginaId, titulo) => {
        // 1. Injeta o Skeleton UI (Padrão Enterprise)
        workspaceArea.innerHTML = renderSkeleton();
        titleHeader.textContent = titulo;

        // 2. Simula latência de I/O da API/Serverless
        setTimeout(() => {
            try {
                // MOCK: Na versão de produção, faremos fetch(`${paginaId}.html`)
                const htmlContent = gerarTemplateTemporario(paginaId, titulo);
                
                // 3. Renderiza o conteúdo final
                workspaceArea.innerHTML = `<div class="fade-in">${htmlContent}</div>`;
                
            } catch (error) {
                workspaceArea.innerHTML = `
                    <div style="background: #fff; padding: 40px; border-radius: 8px; border: 1px solid #e2e8f0;">
                        <h3 style="color: #ef4444; margin-bottom: 8px;">Falha de I/O na Rota</h3>
                        <p style="color: #64748b; font-size: 0.9rem;">O módulo ${paginaId} não pôde ser instanciado a partir do CloudFront.</p>
                    </div>
                `;
            }
        }, 800); // 800ms para apreciação do skeleton (no mundo real seria o tempo da request)
    };

    // Controle de cliques na Navegação
    navItems.forEach(item => {
        item.addEventListener('click', (e) => {
            e.preventDefault();
            if (item.classList.contains('active')) return; // Evita re-render da mesma página

            navItems.forEach(nav => nav.classList.remove('active'));
            item.classList.add('active');

            const pageId = item.getAttribute('data-page');
            const pageTitle = item.querySelector('.nav-label').textContent;

            carregarModulo(pageId, pageTitle);
        });
    });

    // Função Placeholder temporária
    function gerarTemplateTemporario(id, titulo) {
        return `
            <div style="background: #fff; padding: 32px; border-radius: 8px; border: 1px solid #e2e8f0;">
                <h2 style="font-size: 1.2rem; color: #0f172a; margin-bottom: 12px; font-weight: 600;">Submódulo: ${titulo}</h2>
                <p style="color: #64748b; font-size: 0.9rem; line-height: 1.5;">O contêiner do componente <code>${id}.html</code> será hidratado aqui. As lógicas de tabela, gráficos ECharts e formulários controlados preencherão este espaço.</p>
            </div>
        `;
    }

    // Inicialização Limpa
    const initialItem = document.querySelector('.nav-item.active');
    if (initialItem) {
        carregarModulo(initialItem.getAttribute('data-page'), initialItem.querySelector('.nav-label').textContent);
    }
});