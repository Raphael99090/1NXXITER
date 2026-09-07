# Changelog

Todas as mudanças notáveis do 1NXITER HUB são documentadas aqui.

## [3.0.0] - 2026-09-07

### Segurança
- **Keys premium não ficam mais em texto puro no `keys.json`**: como esse arquivo é público (GitHub raw/Pages), guardar a key crua como índice do JSON deixava qualquer um que abrisse a página ler a lista inteira de keys vendidas e usá-las de graça. Agora só o **hash SHA-256** da key fica salvo — implementado um SHA-256 puro em Lua no `main.lua` (sem libs externas, já que o loader roda antes do sistema de módulos existir) e via Web Crypto (`crypto.subtle.digest`) no painel admin, os dois batendo o mesmo hash. Rodei os dois contra vetores de teste oficiais do SHA-256 antes de subir. O painel admin agora deixa claro que a key só aparece na hora da criação — depois só o hash fica recuperável.

### Alterado
- **UI trocada de Fluent pra WindUI**: mesma estrutura de abas e funcionalidades, mas o botão flutuante de mobile agora é o `OpenButton` nativo da WindUI (arrastável) — o hack de ~250 linhas que existia em `Interface/Main.lua` pra simular isso em cima da Fluent (bolinha customizada, hook em `Window.Minimize`, `VirtualInputManager` simulando tecla) foi todo removido. Tema agora troca em runtime de verdade via `WindUI:SetTheme` (dropdown nativo na aba Sistema), sem precisar do addon `InterfaceManager` que a Fluent exigia pra isso.

### Adicionado
- **Modo de teste temporário** no sistema de key: `TESTING_MODE = true` em `main.lua` faz a key `"TESTE-1NX"` liberar o hub sem bater no site (útil enquanto `VALIDATE_URL` ainda é o placeholder). Imprime um aviso no console (F9) lembrando que tá ativo. **⚠️ Mude pra `false` antes de publicar** — com isso ligado, qualquer um que descubra a key de teste entra de graça.
- **Combate**: prioridade de alvo (mais perto da mira / menor vida), "Só mirar segurando E" (aim key), "Ignorar Time" e "Mostrar Círculo do FOV" — todas já existiam como `Settings` mortos, sem controle na UI.
- **Movimento**: **Fly** de verdade (voo 3D via BodyVelocity — WASD/joystick pra direção, Espaço/Ctrl pra subir/descer, botão de pulo dá um empurrão no touch sem teclado) e **Anti-Queda** (teleporta de volta pra última posição segura se cair do mapa).
- **Visual**: Tracers (linha até o jogador) e texto de Distância, como extras opt-in em cima do Chams minimalista.
- **Sistema de key real, ligado ao site**: `main.lua` agora chama `POST /api/validate` do site (`1nxiter-site`) em vez de comparar com uma key fixa — envia `key` + `hwid` (via `gethwid`/`get_hwid`/`identifyexecutor`, com fallback pro `RbxAnalyticsService`), mostra "Verificando..." durante a checagem, trava contra clique duplo, e traduz cada `reason` do servidor (`key_invalid`, `expired`, `revoked`, `hwid_mismatch`, `rate_limited`) numa mensagem amigável. **Antes de publicar**, troque `VALIDATE_URL` em `main.lua` pelo domínio real do site (com HTTPS).
- **Silent Aim**: novo toggle no Aimbot — trava o alvo (`Aimbot.LockedTarget`) e mostra um marcador triangular na tela, mas **nunca gira a câmera sozinha**. Não existe hook de disparo genérico pra redirecionar tiro nesse jogo, então isso é o modo "mira sem se mexer": serve pra você mirar em cima da marcação sem ninguém perceber a câmera travando — não atira sozinho.
- Auto-save de verdade: `Config.AutoSave` existia desde sempre mas nada lia esse valor — agora `StateManager:StartAutoSave` roda em segundo plano e salva sozinho quando algo muda (a cada ~8s), respeitando a flag.
- Botão "RESTAURAR PADRÕES" na aba Sistema (`StateManager:ResetConfig`), com aviso de que é preciso reabrir o hub pra ver os controles atualizados.
- Status ao vivo "🎯 Mirando em alvo" / "🔒 Alvo travado (Silent Aim)" / "👀 Procurando alvo..." na aba Combate.
- Contador ao vivo de jogadores detectados na aba Visual (atualiza a cada segundo enquanto o ESP está ligado).
- Toggle de Jump Power (Ativar + slider de força) na aba Movimento — `PlayerMods.Settings.JumpEnabled/JumpValue` já existiam no código mas não tinham nenhum controle na UI.
- Toggle de Auto-Rejoin na aba Sistema — `Config.AutoRejoin` já era lido por `Utils:AutoRejoin`, mas não dava pra ligar sem editar o JSON na mão.

### Alterado
- **ESP totalmente reescrito**: saiu Box/Skeleton/HealthBar (baseados em Drawing, mais pesados e mais código) e entrou só **Chams** (Highlight que atravessa parede) — minimalista, um toggle + ocultar aliados + slider de transparência. Também passou a reagir a respawn (`CharacterAdded`) automaticamente, o que o Aura antigo não fazia sozinho.
- Sistema de key fixa (`main.lua`) antes de carregar qualquer módulo — tela de input com validação e mensagem de erro. **Apenas para teste**: a key fica em texto puro no código, sem segurança real ainda.
- Ícone customizado na bolinha flutuante, baixado do repositório (`Assets/1784776415112.png`) via `writefile`/`getcustomasset`, com fallback pro texto "1NX" caso o executor não suporte.
- `UIAspectRatioConstraint` na bolinha flutuante, pra ela nunca esticar/virar elipse em resoluções diferentes.
- Sombra suave (drop-shadow) atrás da bolinha flutuante.
- Efeito de glow pulsante no contorno da bolinha enquanto o hub está minimizado.
- Snap automático pra borda esquerda/direita da tela ao soltar o drag da bolinha, com clamp vertical pra nunca sair da viewport.
- Fade-in suave do ícone customizado quando termina de carregar, e fade-out do texto de fallback.

### Corrigido
- **FreeCam**: conexão de `UserInputService.TouchEnded` não era guardada — cada vez que a FreeCam era ligada, uma nova conexão global era empilhada por cima das anteriores sem nunca desconectar (vazamento a cada toggle). Agora é guardada e desconectada junto com as outras.
- **FreeCam**: rotação vertical (pitch) não tinha limite — dava pra passar da vertical e virar a câmera de cabeça pra baixo. Agora é limitada a ±89°.
- **SpyChat**: `MakeDraggable` conectava direto em `UserInputService.InputChanged` sem devolver/guardar a conexão — toda vez que o painel era reaberto (Toggle true), a conexão antiga continuava viva. Agora as conexões do arraste são registradas em `self.Connections` e desconectadas junto com o resto ao fechar.
- **AutoTrain**: não tinha `Unload()` — um treino em andamento sobrevivia ao "FECHAR HUB" e continuava mandando mensagem no chat pra sempre, sem UI pra pausar. `RuntimeState.IsActive` também nunca era setado como `false` em lugar nenhum, então a checagem de segurança que já existia no loop nunca disparava de verdade.
- **ESP**: jogador que saía da partida com ESP ligado nunca tinha os Drawings (Box/Skeleton/HealthBar) removidos — ficavam órfãos em `ESP.Cache` até o ESP inteiro ser desligado. Agora limpa automaticamente em `Players.PlayerRemoving`.
- **PlayerMods**: duas conexões separadas ao mesmo `CharacterAdded` foram unificadas em uma só, e a conexão de `DescendantAdded` do personagem anterior agora é desconectada a cada respawn em vez de empilhar uma nova a cada morte.
- Bolinha flutuante não aparecia ao minimizar o hub — a detecção antiga tentava adivinhar qual `Frame` da Fluent era o principal e escutar `.Visible`, o que é frágil na v3 da Fluent (que anima minimize/restore sem necessariamente tocar em `.Visible`). Trocado por um hook direto em `Window:Minimize`, que cobre tanto o clique na bolinha quanto o `MinimizeKey` (LeftControl).
- Clique na bolinha não restaurava a janela — a chamada `Window:Minimize(false)` estava tratando o parâmetro como "estado desejado", mas ele provavelmente é uma flag de animação/instant, não o estado alvo. Trocado por `Window:Minimize()` como toggle puro, igual o keybind interno já fazia.

### Alterado
- Paleta de cores da bolinha flutuante trocada de vermelho genérico pra roxo/dourado, combinando com a logo do hub.

### Removido
- Badge de atividade (pontinho verde indicando feature ativa em segundo plano) — implementado e depois removido a pedido, por não ser necessário no momento.
