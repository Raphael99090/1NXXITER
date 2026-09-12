<div align="center">
  <h1>1NXXITER HUB ⚔️</h1>
  <p><strong>Software de Automação de Alto Nível e Arquitetura Modular para Roblox</strong></p>

  <p>
    <a href="https://github.com/Raphael99090/1NXXITER/releases"><img src="https://img.shields.io/badge/Version-3.0.0-red?style=for-the-badge" alt="Versão"></a>
    <a href="https://github.com/Raphael99090/1NXXITER/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Raphael99090/1NXXITER?style=for-the-badge&color=green" alt="Licença"></a>
    <a href="https://www.lua.org/"><img src="https://img.shields.io/badge/Language-Lua-blue?style=for-the-badge&logo=lua" alt="Linguagem"></a>
    <img src="https://img.shields.io/badge/Architecture-Modular_SRC-orange?style=for-the-badge" alt="Arquitetura">
  </p>
</div>

---

O **1NXXITER HUB** v3.0 é um software de automação para Roblox com arquitetura modular de alto nível. Desenvolvido para oferecer máxima performance, estabilidade e uma interface ultra-moderna via **WindUI**.

## 📑 Índice

- [Execução Direta](#-execução-direta)
- [Sistema de Key](#-sistema-de-key-panda-key-system)
- [Diferenciais da Versão 3.0](#-diferenciais-da-versão-30-src-edition)
- [Funcionalidades](#-funcionalidades)
- [Estrutura do Repositório](#-estrutura-do-repositório)
- [Contribuindo](#-contribuindo)
- [Licença](#-licença)
- [Créditos](#-créditos)

---

## 🚀 Execução Direta

Copie o código abaixo e execute em seu executor de scripts preferido (Solara, Wave, Delta, Arceus X, etc):

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/src/main.lua"))()
```

---

## 🔑 Sistema de Key (Panda Key System)

O **1NXXITER HUB** utiliza o **Panda Key System** para uma validação server-side segura.

*   **🔐 Validação Server-Side:** Keys são validadas nos servidores do Panda antes do Hub ser carregado.
*   **🔗 GetKey Page:** Usuários obtêm keys através da página oficial GetKey do Panda.
*   **🛡️ HWID Lock:** Cada key é vinculada automaticamente ao dispositivo do usuário (Hardware ID).
*   **📊 Analytics:** Acompanhe o número de execuções e uso no dashboard do Panda.
*   **💰 Monetização:** Suporte integrado a Linkvertise, LootLabs, AdMaven e outras plataformas.

---

## 🛠️ Diferenciais da Versão 3.0 (SRC Edition)

Diferente de scripts comuns, a v3.0 utiliza uma estrutura de **Software Modular**:

*   **⚡ Carregamento Assíncrono:** Módulos são baixados e compilados individualmente, otimizando o tempo de carregamento.
*   **🧩 Tabs Isoladas:** Cada aba da interface é tratada como um arquivo independente, facilitando atualizações sem impactar outras partes do código.
*   **🛡️ Pcall Shield:** Sistema robusto de proteção contra erros que impede o encerramento abrupto do Hub caso algum módulo específico falhe.
*   **💾 Deep Config:** Sistema de salvamento inteligente em formato JSON que preserva todas as suas configurações, mesmo após atualizações do Hub.

---

## ✨ Funcionalidades

### ⚔️ Treino Automatizado
*   **Modos Suportados:** Canguru (360º Physics), Flexão e Polichinelo.
*   **Inteligência de Chat:** Conversão Numérica avançada para o formato PT-BR.
*   **Customização:** Controle detalhado de delay e quantidade de séries.

### 🎯 Combate & Visual
*   **Aimbot Pro:** Suavidade calculada por DeltaTime, checagem rigorosa de visibilidade, prioridade de alvo (mais perto/menor vida) e parte-alvo selecionável (Root/Head/Torso). Modo Silent Aim incluso!
*   **ESP Minimalista:** Chams (Highlight que atravessa parede) com Tracers e Distância opcionais, desligados por padrão pra manter leve.
*   **Hitbox Expander:** Aumento volumétrico dos alvos com controle de transparência e tamanho ajustável.

### 🚀 Utilidades Extra
*   **Spy Chat HD:** Interface customizada inspirada no HD Admin, incluindo busca e função minimizar.
*   **FreeCam Orbital:** Câmera livre total com controle refinado de sensibilidade de movimento.
*   **System Tools:** Utilitários essenciais como Anti-AFK, Auto-Rejoin, Server Hop rápido e Otimizador de FPS (FPS Boost).

---

## 📂 Estrutura do Repositório

O repositório é organizado de maneira profissional e escalável:

```text
src/
├── main.lua            # Loader principal e montador da interface (Key System)
├── Core/               # Kernel: State Manager, Utils, Services
├── Features/           # Lógica: Aimbot, ESP, PlayerMods, AutoTrain
└── Interface/          # UI: Janela Principal e Módulos das Abas (Tabs)
```

---

## 🤝 Contribuindo

Contribuições são muito bem-vindas! Se você tem uma ideia de melhoria, nova funcionalidade ou encontrou algum bug, por favor, verifique nossos guias:

*   Veja o [Guia de Contribuição](CONTRIBUTING.md) para saber como enviar código.
*   Leia nosso [Código de Conduta](CODE_OF_CONDUCT.md).
*   Abra uma [Issue](https://github.com/Raphael99090/1NXXITER/issues) para sugerir melhorias ou reportar problemas.

---

## 📜 Licença

Este projeto está licenciado sob os termos da licença incluída no arquivo [LICENSE](LICENSE).

---

## 👤 Créditos

*   **Desenvolvedor:** [Raphael99090](https://github.com/Raphael99090)
*   **UI Library:** [WindUI](https://github.com/Footagesus/WindUI) por Footagesus
*   **Data de Lançamento (v3):** 07 de Setembro de 2026

---

> ⚠️ **Aviso de Responsabilidade:** Este projeto foi criado puramente para fins educacionais e de estudo da linguagem Lua e da API do Roblox. O uso indevido é de total e exclusiva responsabilidade do usuário final.
