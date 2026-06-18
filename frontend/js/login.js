document.addEventListener("DOMContentLoaded", () => {
    
    // Captura dos elementos de interface
    const viewLogin = document.getElementById("view-login");
    const viewRegister = document.getElementById("view-register");
    const linkToRegister = document.getElementById("link-to-register");
    const linkToLogin = document.getElementById("link-to-login");

    const formLogin = document.getElementById("form-login");
    const formRegister = document.getElementById("form-register");

    // ==========================================
    // ALTERNÂNCIA DE TELAS (LOGIN <-> REGISTRO)
    // ==========================================
    const alternarTelas = (esconder, mostrar) => {
        esconder.classList.remove("active");
        setTimeout(() => {
            esconder.style.display = "none";
            mostrar.style.display = "block";
            // Timeout necessário para a transição de opacidade do CSS funcionar
            setTimeout(() => {
                mostrar.classList.add("active");
            }, 50);
        }, 300); // Tempo igual ao da transição no CSS
    };

    linkToRegister.addEventListener("click", (e) => {
        e.preventDefault();
        alternarTelas(viewLogin, viewRegister);
    });

    linkToLogin.addEventListener("click", (e) => {
        e.preventDefault();
        alternarTelas(viewRegister, viewLogin);
    });

    // ==========================================
    // SIMULAÇÃO DE SUBMISSÃO E ROTEAMENTO
    // ==========================================
    formLogin.addEventListener("submit", (e) => {
        e.preventDefault();
        
        const btn = formLogin.querySelector("button");
        const textoOriginal = btn.textContent;
        
        // Simula loading
        btn.textContent = "Autenticando...";
        btn.style.opacity = "0.8";

        // Aqui entraria a chamada real (fetch) para a AWS API
        setTimeout(() => {
            // Mock de sucesso - Redireciona para o Painel Principal
            sessionStorage.setItem("techstock_auth", "true");
            window.location.href = "index.html"; 
        }, 800);
    });

    formRegister.addEventListener("submit", (e) => {
        e.preventDefault();
        
        const btn = formRegister.querySelector("button");
        
        btn.textContent = "Processando...";
        btn.style.opacity = "0.8";

        setTimeout(() => {
            alert("Solicitação enviada! Aguarde a aprovação do gestor do Alpha Tech Group.");
            btn.textContent = "Solicitar Aprovação";
            btn.style.opacity = "1";
            formRegister.reset();
            alternarTelas(viewRegister, viewLogin);
        }, 1000);
    });

});