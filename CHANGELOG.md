# Changelog

Todas as mudanças notáveis do 1NXITER HUB são documentadas aqui.

## [4.0.0] - 2026-09-13

Reinício do versionamento. Resumo do estado atual do projeto após a limpeza:

### Núcleo
- Lifecycle Manager (`Core/Lifecycle.lua`): rastreia o carregamento de cada módulo (DISCOVER → LOAD → VALIDATE → RUNNING/FAILED), isola falhas sem derrubar o Hub inteiro, expõe diagnóstico na aba Sistema.
- Key System via WindUI nativo (`pandadevelopment`), com key salva localmente após a primeira validação.
- `Config` persistido em JSON local, aninhado por Feature, com merge automático contra os padrões em atualizações.

### Features
- **Aimbot** — Silent Aim, prioridade de alvo, checagem de parede, parte-alvo configurável.
- **ESP** — Chams, Tracers e Distância, cada um com conexão independente dos outros.
- **PlayerMods** — velocidade, pulo, Noclip, pulo infinito, voo livre (com orientação automática na direção do voo), Anti-Void.
- **Visuals** — FOV customizado com restauração do valor original do jogo ao desligar.
- **FreeCam** — câmera orbital livre.
- **SpyChat** — aba própria, independente da Câmera.
- **AutoJJs** — contagem automática no chat, 3 modos de intervalo mutuamente exclusivos, sufixo customizável, modo reverso, validação de intervalo antes de iniciar.
- **TASRecorder** — grava trajeto a ~60x/s, fantasma marcador estático no ponto inicial (pose fiel capturada no instante da gravação), reprodução via CFrame determinístico (sem física) com o próprio jogador assumindo o trajeto, rota visual e progresso de tempo/distância.
- **Grammar** — correção de texto via API do Gemini, key própria do usuário.
- **Utils** — Anti-Lag reversível (restaura os valores originais ao desligar), Anti-AFK, Auto-Rejoin, Server Hop.

### Interface
- Todas as abas usam Sections como contêineres colapsáveis de verdade (não só título).
- Diálogos de confirmação nativos em ações destrutivas (restaurar padrões, fechar hub).
- Tela de key personalizada com branding do hub.
