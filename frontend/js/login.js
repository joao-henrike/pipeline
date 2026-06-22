// --- LÓGICA DO CARROSSEL DE IMAGENS ---
const bgImages = [
    "https://images.unsplash.com/photo-1542332213-9b5a5a3fad35?q=80&w=1200&auto=format&fit=crop", // 1. Montanhas/Natureza (Original)
    "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?q=80&w=1200&auto=format&fit=crop", // 2. Servidores / Data Center
    "https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=1200&auto=format&fit=crop", // 3. Rede Global / Terra
    "https://images.unsplash.com/photo-1497366216548-37526070297c?q=80&w=1200&auto=format&fit=crop"  // 4. Arquitetura Corporativa Noturna
];

let currentIndex = 0;
const leftPanel = document.querySelector('.left-panel');
const dots = document.querySelectorAll('.dot');

function rotateBackground() {
    // Avança o índice e volta ao zero se passar do limite
    currentIndex = (currentIndex + 1) % bgImages.length;
    
    // Troca a imagem de fundo com o gradiente por cima
    leftPanel.style.backgroundImage = `linear-gradient(rgba(15, 12, 22, 0.4), rgba(15, 12, 22, 0.9)), url('${bgImages[currentIndex]}')`;
    
    // Atualiza os indicadores (dots)
    dots.forEach((dot, index) => {
        if (index === currentIndex) {
            dot.classList.add('active');
        } else {
            dot.classList.remove('active');
        }
    });
}

// Inicia o motor para rodar a cada 7 segundos (7000ms)
setInterval(rotateBackground, 7000);


// --- LÓGICA DOS FORMULÁRIOS ---
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
        icon.classList.remove('fa-eye');
        icon.classList.add('fa-eye-slash');
    } else {
        input.type = "password";
        icon.classList.remove('fa-eye-slash');
        icon.classList.add('fa-eye');
    }
}

document.getElementById('register-form').addEventListener('submit', (e) => {
    e.preventDefault();
    console.log("[Auth] Payload de Registro gerado.");
});

document.getElementById('login-form').addEventListener('submit', (e) => {
    e.preventDefault();
    console.log("[Auth] Payload de Login gerado.");
});
