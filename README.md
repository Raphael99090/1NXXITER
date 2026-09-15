<div align="center">
  <h1>1NXXITER HUB</h1>
  <p>Hub modular para Roblox, com interface em WindUI e arquitetura de carregamento por módulos via GitHub.</p>

  <p>
    <a href="https://github.com/Raphael99090/1NXXITER/releases"><img src="https://img.shields.io/badge/version-3.11.2-blue?style=flat-square" alt="Versão"></a>
    <a href="https://github.com/Raphael99090/1NXXITER/blob/main/LICENSE"><img src="https://img.shields.io/github/license/Raphael99090/1NXXITER?style=flat-square&color=green" alt="Licença"></a>
    <img src="https://img.shields.io/badge/language-Lua-blue?style=flat-square" alt="Linguagem">
    <img src="https://img.shields.io/badge/architecture-modular-informational?style=flat-square" alt="Arquitetura">
  </p>
</div>

## Índice

- [Uso](#uso)
- [Sistema de key](#sistema-de-key)
- [Arquitetura](#arquitetura)
- [Funcionalidades](#funcionalidades)
- [Estrutura do repositório](#estrutura-do-repositório)
- [Contribuindo](#contribuindo)
- [Licença](#licença)
- [Créditos](#créditos)

## Uso

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/src/main.lua"))()
```

Execute em qualquer executor de scripts compatível com Roblox (Delta, Arceus X, Wave, Solara, entre outros).

## Sistema de key

A validação usa o Panda Key System, implementado através do KeySystem nativo da WindUI (`Type = "pandadevelopment"`) — sem tela de key própria pra manter.

- Validação feita no servidor do Panda, antes do Hub carregar.
- Key obtida pela página oficial de GetKey do Panda e vinculada ao HWID do usuário.
- Depois de validada uma vez, a key fica salva localmente.

## Arquitetura

- **Carregamento modular** — cada Feature e cada aba da interface é baixada e compilada individualmente via `Import()`, não um único arquivo monolítico.
- **Isolamento de falhas** — um módulo que falha ao carregar não derruba o Hub inteiro; o `Lifecycle Manager` rastreia o estado de cada um (`Core/Lifecycle.lua`) e reporta em "Diagnóstico" (aba Sistema).
- **Configuração persistente** — salva em JSON local (`Core/State.lua`), com merge automático contra os valores padrão em atualizações.

## Funcionalidades

| Área | Descrição |
|---|---|
| **Combate** | Aimbot com Silent Aim, prioridade de alvo, checagem de parede e parte-alvo configurável. |
| **Visual** | ESP (Chams), Tracers e Distância — cada um independente dos outros. Hitbox Expander. |
| **Movimento** | Velocidade, pulo, Noclip, pulo infinito, voo livre, Anti-Void. |
| **Câmera** | FOV customizado, câmera orbital livre (FreeCam). |
| **Spy Chat** | Leitura de mensagens e comandos que normalmente só quem está por perto veria. |
| **Auto JJ's** | Contagem automática no chat — intervalo inteligente/fixo/dinâmico, sufixo customizável, modo reverso. |
| **TAS** | Grava trajeto (posição/rotação a ~60x/s), fantasma marcador no ponto inicial, reprodução fiel com rota visual e progresso. |
| **Gramática** | Correção de texto via API do Gemini, usando a key do próprio usuário. |
| **Sistema** | Rejoin, Server Hop, Anti-AFK, Anti-Lag reversível, temas, diagnóstico de módulos. |

## Estrutura do repositório

```text
src/
├── main.lua            # Loader (Import/LoadHub, Key System, ApplyConfig)
├── Core/                # Utils, State Manager, Lifecycle Manager
├── Features/            # Lógica de cada recurso (Aimbot, ESP, PlayerMods, ...)
└── Interface/
    ├── Window.lua        # Montagem da janela principal
    └── Tabs/              # Uma aba por arquivo
```

## Contribuindo

- Guia de contribuição: [CONTRIBUTING.md](CONTRIBUTING.md)
- Código de conduta: [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)
- Bugs e sugestões: [Issues](https://github.com/Raphael99090/1NXXITER/issues)

## Licença

Distribuído sob os termos do arquivo [LICENSE](LICENSE).

## Créditos

- Desenvolvedor: [Raphael99090](https://github.com/Raphael99090)
- Interface: [WindUI](https://github.com/Footagesus/WindUI), por Footagesus

---

Projeto criado para fins de estudo de Lua e da API do Roblox. O uso é de responsabilidade exclusiva de quem executa o script.
