// --- ENGINE DO CARROSSEL ---
const bgImages = [
    "https://images.unsplash.com/photo-1542332213-9b5a5a3fad35?q=80&w=1200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?q=80&w=1200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop",
    "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1200&auto=format&fit=crop"
];
let currentIndex = 0;
const leftPanel = document.querySelector('.left-panel');
const dots = document.querySelectorAll('.dot');

if (leftPanel && dots.length > 0) {
    setInterval(() => {
        currentIndex = (currentIndex + 1) % bgImages.length;
        leftPanel.style.backgroundImage = `linear-gradient(rgba(15, 12, 22, 0.4), rgba(15, 12, 22, 0.9)), url('${bgImages[currentIndex]}')`;
        dots.forEach((dot, idx) => dot.classList.toggle('active', idx === currentIndex));
    }, 7000);
}

// --- ALTERNÂNCIA DE FORMULÁRIOS ---
function toggleForms(target) {
    const loginSection = document.getElementById('login-section');
    const registerSection = document.getElementById('register-section');
    if (target === 'login') {
        registerSection.classList.add('hidden');
        loginSection.classList.remove('hidden');
        document.title = "TechStock | Log in";
    } else {
        loginSection.classList.add('hidden');
        registerSection.classList.remove('hidden');
        document.title = "TechStock | Create an account";
    }
}

function togglePasswordVisibility(inputId) {
    const input = document.getElementById(inputId);
    const icon = input.nextElementSibling;
    if (input.type === "password") {
        input.type = "text";
        icon.className = 'fa-regular fa-eye-slash toggle-password';
    } else {
        input.type = "password";
        icon.className = 'fa-regular fa-eye toggle-password';
    }
}

// --- CONEXÃO REAL COM A API (FETCH INTEGRATION) ---

// Fluxo de Registro (Create Account)
document.getElementById('register-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const payload = {
        firstname: document.getElementById('reg-firstname').value,
        lastname: document.getElementById('reg-lastname').value,
        email: document.getElementById('reg-email').value,
        password: document.getElementById('reg-password').value
    };

    try {
        const response = await fetch('/api/register', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const result = await response.json();

        if (response.ok) {
            alert(`Sucesso: Conta de ${result.user} criada! Faça o login.`);
            toggleForms('login');
        } else {
            alert(`Erro no Registro: ${result.message}`);
        }
    } catch (error) {
        console.error("[Network Error]", error);
        alert("Falha crítica de conectividade com o servidor de backend.");
    }
});

// Fluxo de Autenticação (Log In)
document.getElementById('login-form').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const payload = {
        email: document.getElementById('login-email').value,
        password: document.getElementById('login-password').value
    };

    try {
        const response = await fetch('/api/login', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(payload)
        });

        const result = await response.json();

        if (response.ok) {
            // Armazena o token de sessão simulado
            localStorage.setItem('techstock_token', result.token);
            // Redireciona o operador para o Command Center
            window.location.href = `../${result.redirect}`;
        } else {
            alert(`Erro no Login: ${result.message}`);
        }
    } catch (error) {
        console.error("[Network Error]", error);
        alert("Falha crítica de conectividade com o servidor de backend.");
    }
});
