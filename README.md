# 1NXXITER HUB ⚔️ | v3.0 Modular

![GitHub License](https://img.shields.io/github/license/Raphael99090/1NXXITER?style=for-the-badge&color=green)
![Lua](https://img.shields.io/badge/Language-Lua-blue?style=for-the-badge&logo=lua)
![Version](https://img.shields.io/badge/Version-3.0.0-red?style=for-the-badge)
![Architecture](https://img.shields.io/badge/Architecture-Modular_SRC-orange?style=for-the-badge)

O **1NXXITER HUB** v3.0 é um software de automação para Roblox com arquitetura modular de alto nível. Desenvolvido para oferecer máxima performance, estabilidade e uma interface ultra-moderna via **WindUI**.

---

## 🚀 Execução Direta

Copie o código abaixo e execute em seu software de preferência (Solara, Wave, Delta, etc):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/src/main.lua"))()
```

---

## 🔑 Sistema de Key

O **1NXXITER HUB** utiliza um sistema de **key individual por usuário**.

*   **👤 Key Individual:** Cada usuário possui sua própria key.
*   **🔗 URL Exclusiva:** Cada usuário recebe uma URL própria para o processo de obtenção da key.
*   **🛡️ Validação Server-Side:** A key é validada pelo servidor antes do carregamento do Hub.
*   **♻️ Controle de Acesso:** Keys podem possuir expiração, ativação ou revogação.

---

## 🛠️ Diferenciais da Versão 3.0 (SRC Edition)

Diferente de scripts comuns, a v3.0 utiliza uma estrutura de **Software Modular**:
*   **⚡ Carregamento Assíncrono:** Módulos baixados e compilados individualmente.
*   **🧩 Tabs Isoladas:** Cada aba da interface é um arquivo independente, facilitando atualizações.
*   **🛡️ Pcall Shield:** Sistema de proteção contra erros que impede o fechamento do Hub se um módulo falhar.
*   **💾 Deep Config:** Salvamento inteligente em JSON que preserva configurações mesmo após updates.

---

## ✨ Funcionalidades

### ⚔️ Treino Automatizado
*   Modos: Canguru (360º Physics), Flexão e Polichinelo.
*   Inteligência de Chat: Conversão Numérica para PT-BR.
*   Controle de delay e séries customizáveis.

### 🎯 Combate & Visual
*   **Aimbot Pro:** Suavidade por DeltaTime e checagem de visibilidade.
*   **ESP de Elite:** Aura (Highlight), Box 2D com contorno e Skeleton R6/R15.
*   **Hitbox Expander:** Aumento volumétrico de alvos com transparência ajustável.

### 🚀 Utilidades Extra
*   **Spy Chat HD:** Interface inspirada no HD Admin com busca e minimizar.
*   **FreeCam Orbital:** Câmera livre com controle de sensibilidade.
*   **System Tools:** Anti-AFK, Auto-Rejoin, Server Hop e FPS Boost.

---

## 📂 Estrutura do Repositório
```text
src/
├── main.lua            # Loader e Montador do Sistema
├── Core/               # Kernel: State e Utils
├── Features/           # Lógica: Aimbot, ESP, PlayerMods...
└── Interface/          # UI: Janela Principal e Abas (Tabs/)
```

---

## 👤 Créditos
*   **Desenvolvedor:** [Raphael99090](https://github.com/Raphael99090)
*   **UI Library:** [WindUI](https://github.com/Footagesus/WindUI)
*   **Data de Lançamento:** 21 de Julho de 2026

---
> **Aviso:** Este projeto foi criado para fins educacionais e de estudo da linguagem Lua. O uso indevido é de responsabilidade do usuário.
