// 1. Trava preventivamente qualquer tentativa do HTML de enviar dados sozinho
document.querySelectorAll('form').forEach(form => {
    form.addEventListener('submit', (e) => e.preventDefault());
});

// 2. Captura o botão de login (seja ele um type=submit ou um button genérico)
const btnLogin = document.querySelector('button[type="submit"]') || document.querySelector('button');

if (btnLogin) {
    btnLogin.addEventListener('click', async (e) => {
        e.preventDefault(); // Trava a navegação padrão

        // Procura os inputs genéricos de e-mail e senha onde quer que estejam
        const emailInput = document.querySelector('input[type="email"]') || document.querySelector('input[name="email"]');
        const passwordInput = document.querySelector('input[type="password"]') || document.querySelector('input[name="password"]');

        const email = emailInput ? emailInput.value : 'admin@techstock.com';
        const password = passwordInput ? passwordInput.value : '12345';

        console.log("[FRONT-END] Tentando conectar no Flask com:", email);

        try {
            const response = await fetch('http://127.0.0.1:5000/api/login', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ email: email, password: password })
            });

            if (response.ok) {
                console.log("[FRONT-END] Acesso concedido!");
                window.location.href = "inventario.html"; 
            } else {
                alert("Acesso negado pelo servidor.");
            }
        } catch (error) {
            console.error("Erro de Conectividade:", error);
            alert("Falha crítica: O Servidor Flask (127.0.0.1:5000) está rodando?");
        }
    });
} else {
    console.error("Botão de login não encontrado! Verifique o HTML da sua tela.");
}
