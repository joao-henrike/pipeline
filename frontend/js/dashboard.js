// Configuração Global do Chart.js para Dark Mode
Chart.defaults.color = '#828191';
Chart.defaults.borderColor = '#241f35';
Chart.defaults.font.family = "'Inter', sans-serif";

document.addEventListener('DOMContentLoaded', () => {
    
    // Gráfico 1: Fluxo de Movimentações (Linha)
    const ctxFluxo = document.getElementById('chartFluxo').getContext('2d');
    new Chart(ctxFluxo, {
        type: 'line',
        data: {
            labels: ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
            datasets: [
                {
                    label: 'Entradas',
                    data: [12, 19, 3, 5, 2, 0, 8],
                    borderColor: '#34d399', // Verde
                    backgroundColor: 'rgba(52, 211, 153, 0.1)',
                    borderWidth: 2,
                    tension: 0.4, // Curva suave
                    fill: true
                },
                {
                    label: 'Saídas',
                    data: [5, 10, 15, 8, 12, 2, 4],
                    borderColor: '#f87171', // Vermelho
                    backgroundColor: 'rgba(248, 113, 113, 0.1)',
                    borderWidth: 2,
                    tension: 0.4,
                    fill: true
                }
            ]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: { legend: { position: 'top' } },
            scales: {
                y: { beginAtZero: true, grid: { color: '#241f35' } },
                x: { grid: { display: false } }
            }
        }
    });

    // Gráfico 2: Distribuição por Categoria (Rosca/Doughnut)
    const ctxCategoria = document.getElementById('chartCategoria').getContext('2d');
    new Chart(ctxCategoria, {
        type: 'doughnut',
        data: {
            labels: ['Hardware (Servidores/Peças)', 'Equip. de Rede', 'Periféricos', 'Licenças'],
            datasets: [{
                data: [45, 25, 20, 10],
                backgroundColor: [
                    '#7c3aed', // Roxo (Primary)
                    '#3b82f6', // Azul
                    '#10b981', // Verde
                    '#f59e0b'  // Laranja
                ],
                borderWidth: 0, // Sem borda branca
                hoverOffset: 4
            }]
        },
        options: {
            responsive: true,
            cutout: '70%', // Espessura da rosca
            plugins: {
                legend: { position: 'bottom', labels: { padding: 20 } }
            }
        }
    });
});
