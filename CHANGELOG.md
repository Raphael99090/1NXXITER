# Changelog

Todas as mudanças notáveis do 1NXITER HUB são documentadas aqui.

## [3.6.1] - 2026-09-09

### Corrigido
- **Pulo não funcionava no replay**: `Humanoid:MoveTo` mirava cada ponto gravado, inclusive os que estavam no ar — a gravidade sempre puxava o personagem de volta antes de chegar lá, então o pulo nunca acontecia de verdade. Agora, ao entrar num trecho gravado como "Jumping"/"Freefall", o replay dispara `Humanoid.Jump` uma vez só e mira o `MoveTo` direto no ponto de POUSO (o primeiro waypoint depois que volta a andar) — a física cuida da altura, o `MoveTo` só carrega o impulso horizontal até o lugar certo.
- `TASTab.lua`: botão "Preparar Fantasma" removido — selecionar uma gravação na lista já prepara o fantasma automaticamente.

## [3.6.0] - 2026-09-09

### Alterado (reversão de arquitetura em `Features/TASRecorder.lua`)
- **O fantasma voltou a ser só um marcador parado** — não anda, não anima, não é mais um "ator" clonado em movimento. É o clone semitransparente do personagem, parado exatamente no ponto onde a gravação começou.
- **É o SEU personagem quem faz o caminho agora**, não o fantasma. Ao disparar o replay, o jogador é teleportado pra posição inicial gravada e o script guia o `Humanoid:MoveTo` waypoint por waypoint (física real, respeita colisão, pulos via `Humanoid.Jump` nos pontos marcados como salto na gravação).
- **Câmera voltou ao normal** — não é mais sequestrada (`Scriptable`) nem reproduz a gravação. Segue o jogador como sempre, já que é ele quem anda.
- **Gatilho trocado de `Touched` pra proximidade**: em vez de depender do evento de toque físico (que com `CanCollide=false` pode não disparar igual em todo executor), agora é um `Heartbeat` medindo distância — "estar dentro" do fantasma (raio de ~3.5 studs) com "Ativar Reproduzir" ligado dispara o replay.
- Removido: interpolação `CFrame:Lerp` do fantasma, carregamento de animações (`Animator`/`LoadAnimation`), sequestro de câmera. A suspensão de Aimbot/FreeCam durante o replay (`SetHub`) continua, já que os dois ainda podem interferir na câmera/controle do jogador real durante o replay.
- Rota visual e label de tempo/distância continuam, mas o label agora acompanha o JOGADOR durante o replay (progresso ao vivo) em vez do fantasma parado (que ganhou um label estático só com o total gravado).
- API pública 100% preservada de novo — `TASTab.lua` não mudou.

## [3.5.0] - 2026-09-09

### Adicionado
- **TAS suspende Aimbot (Silent Aim) e FreeCam durante o replay**: os três brigavam pelo `workspace.CurrentCamera` (todos fazem `CameraType = Scriptable`). Agora `TASRecorder:SetHub(Hub)` é chamado uma vez em `main.lua` logo depois das Features carregarem; no início do replay, se Aimbot/FreeCam estiverem ligados, são desligados temporariamente e restaurados no fim (natural ou manual) — é a primeira dependência real entre duas Features do projeto, mas opcional por natureza (sem `SetHub`, TAS continua funcionando sozinho).
- **Tela de Key personalizada**: `Note`, `URL` (link direto pro GetKey do Panda), `Thumbnail` (reaproveita o ícone já usado no topo da janela) e `Title`/`Desc`/`Icon` no provedor Panda Auth, em vez do formulário genérico padrão da lib. Fundo da janela ganhou um gradiente escuro-pra-ciano sutil (`WindUI:Gradient`, com fallback silencioso pro tema padrão se a versão da lib não suportar).

## [3.4.2] - 2026-09-09

### Corrigido
- `docs/index.html`: os 3 links "Pegar minha key" apontavam pra `getkey/`, uma página que nunca existiu no repo (resquício de antes da migração pro Panda). Agora apontam direto pra `https://ads.pandauth.com/getkey/1nxxiter`.
- `TASRecorder.lua`: guardas contra gravar e reproduzir ao mesmo tempo — `StartRecording()` recusa se um replay estiver ativo, `PlayRecording()` recusa se uma gravação estiver em andamento.

## [3.4.1] - 2026-09-09

### Corrigido (`Features/TASRecorder.lua`)
- **Clone falhando silenciosamente**: `char:Clone()` podia devolver `nil` sem erro nenhum quando `Archivable` do personagem vinha `false` (padrão em vários jogos). `PrepareGhost` agora liga `Archivable = true` só pro clone e restaura o valor original logo depois, sempre — mesmo se a clonagem falhar.
- **Softlock em morte/respawn**: se o jogador morresse ou desse reset com o replay ativo, a câmera ficava travada em `Scriptable` e o controle desabilitado apontando pra um `Humanoid`/`PlayerModule` de um personagem que não existe mais — sem forma de recuperar sem re-executar o hub. Novo listener em `LocalPlayer.CharacterRemoving` chama `StopPlayback()` automaticamente nesse caso.
- **Fim do replay travava o jogador**: alcançar o último frame só desconectava o loop e deixava a câmera/controle presos até alguém clicar manualmente em "Parar reprodução" (era proposital antes, mas causava exatamente o tipo de travamento que o fix acima existe pra evitar). Agora o fim natural do replay já devolve câmera (`Custom`) e controle (`PlayerModule:GetControls():Enable()`) na hora — o fantasma continua parado e visível no último frame, só o jogador não fica preso esperando.
- Lógica de "devolver câmera + controle" extraída pra uma função só (`ReleaseControl`), reaproveitada tanto na parada manual quanto no fim natural — evita duplicar a mesma lógica em dois lugares.

## [3.4.0] - 2026-09-09

### Corrigido (reescrita completa de `Features/TASRecorder.lua`)
- **A causa raiz de tudo**: o replay nunca movia o fantasma — ele ficava parado no ponto inicial enquanto o SEU personagem era teleportado via `Humanoid:MoveTo` por waypoint. Isso explicava a falta de câmera, rota, animação e info visual: nada disso fazia sentido reproduzir no jogador real. Agora o fantasma é quem executa o replay inteiro; o jogador só fica com a câmera presa assistindo.
- **Fantasma real desde o início**: clone completo do personagem (partes, proporções, tudo — sem fallback de bloco/Part), já posicionado exatamente no 1º frame gravado assim que "Preparar Fantasma" é clicado, não só quando o replay começa.
- **Câmera gravada, sem toggle**: `cc` (CFrame da câmera) é gravado em todo frame junto com a posição do personagem — não existe opção pra desligar isso. Durante o replay a câmera vira `Scriptable` e reproduz a trajetória gravada por interpolação (`CFrame:Lerp`), incluindo rotação.
- **Movimento determinístico, sem física**: trocado `Humanoid:MoveTo` (físico, não-determinístico, podia empacar em obstáculo) por interpolação direta de `CFrame` entre frames consecutivos com base no tempo real decorrido. Anda/corre/pula/cai com animação real tocada manualmente via `Animator`, usando os IDs de animação do PRÓPRIO jogo (lidos do script `Animate` do personagem real) quando disponíveis.
- **Loop removido de vez**: o índice do frame (`segIndex`) só avança, nunca reseta; ao alcançar o último frame o `RunService.Heartbeat` é desconectado e o fantasma/câmera ficam congelados no estado final até "Parar reprodução" ser clicado. Nenhuma operação `% total` ou wrap-around em lugar nenhum.
- **Rota visual**: liga os pontos gravados em ordem (funciona em qualquer sentido do percurso) com segmentos `Part` finos em Neon, pulando só trechos onde o jogador ficou parado (evita segmento de comprimento zero) — sem recalcular a rota.
- **Info acima do fantasma**: `BillboardGui` com tempo decorrido e distância real percorrida (soma dos deslocamentos entre frames, pré-calculada uma vez, não linha reta início→fim).
- **Cleanup**: `RemoveGhost()` sempre chama `StopPlayback()` primeiro (nunca deixa câmera/controle presos); preparar um novo fantasma remove o anterior por completo (nunca sobrepõe); `Unload()` limpa tudo.
- **API pública 100% preservada** — `TASTab.lua` não precisou de nenhuma mudança.

## [3.3.0] - 2026-09-09

### Adicionado
- **Aba TAS**: grava seu trajeto (posição a cada 0.15s + marcação de pulo), salva em `.tas` (JSON) na pasta `1NXITER_HUB/TAS`. Ao "preparar" uma gravação, spawna um clone semitransparente do seu personagem parado no ponto inicial; com "Ativar Reproduzir" ligado, **entrar dentro do fantasma** (toque real, não só proximidade) dispara o replay. O replay usa `Humanoid:MoveTo` por waypoint (movimento simulado, com física — sujeito a colisão), trava o controle (WASD) do jogador até terminar ou até "Parar reprodução" ser clicado, e sempre devolve o controle no `Unload()` mesmo se o hub for fechado no meio de uma reprodução.
- Novo módulo `Features/TASRecorder.lua` + aba `Interface/Tabs/TASTab.lua`, registrados no Lifecycle Manager.

## [3.2.0] - 2026-09-09

### Alterado
- **Key System migrado pro nativo da WindUI**: as ~220 linhas de `main.lua` que faziam HWID manual, fetch da lib PUSL V4 do Panda e montavam uma janela de key na mão viraram só um parâmetro `KeySystem` (`Type = "pandadevelopment"`) dentro do `CreateWindow` do `Interface/Main.lua`. Sem `Secret` exposto no client — pandadevelopment só pede `ServiceId`, que já é público (aparece na URL do GetKey). Ganho de brinde: `SaveKey = true`, então a key validada fica salva localmente e não precisa ser colada de novo toda sessão. **Não testado no executor ainda** — o comportamento exato do gate nativo (se trava a janela até validar, etc.) precisa ser confirmado na prática antes de considerar isso pronto pra valer.
- Como consequência, os módulos agora são baixados do GitHub antes da key ser validada (antes, `RequestKey()` só chamava `LoadHub()` depois da key certa). Não pesa pra um hub pessoal, mas é uma mudança de comportamento real.
- Botões **RESTAURAR PADRÕES DE FÁBRICA** e **FECHAR HUB TOTALMENTE** agora pedem confirmação via `Window:Dialog()` nativo antes de executar, em vez de disparar na hora.

## [3.1.0] - 2026-09-09

### Corrigido
- **Bug crítico de persistência**: `CombatTab`, `ESPTab`, `MovementTab` e `CameraTab` faziam `local Cfg = Config.Aimbot or {}` (e equivalentes pra ESP/Movement/Camera). Como essas chaves nunca existiam no `DefaultConfig`, `Cfg` virava uma tabela nova e órfã — nunca escrita de volta em `Config`. Os toggles/sliders funcionavam na hora (porque também setavam `Feature.Settings.X` direto), mas **nada disso era salvo no JSON**, nem pelo auto-save nem pelo botão manual. Ao reabrir o hub, Combate/Visual/Movimento/Câmera sempre voltavam pro padrão — só Treino, Sistema e Atalhos persistiam de verdade. Corrigido nos 4 arquivos com `Config.X = Config.X or {}` antes de guardar a referência.
- **OverviewTab**: usava `State.LoadedAtTick`, que nunca existiu em `State.lua` — sempre caía no fallback `os.clock()`, fazendo o "Tempo de Uso" recomeçar do render da aba em vez do load real do hub. Adicionado `LoadedAtTick` em `RuntimeState`.

### Adicionado
- **Anti-AFK virou toggle de verdade** na aba Sistema (`Config.AntiAFK`, default ligado) — antes rodava sempre, sem controle na UI nem persistência. `Utils:AntiAFK()` virou `Utils:ToggleAntiAFK(state)`.
- **Parte-alvo do Aimbot** selecionável (HumanoidRootPart / Head / UpperTorso) — dropdown novo na aba Combate, ligado em `Aimbot.Settings.TargetPart`.
- **Fly encara a direção do voo**: o personagem agora gira pra apontar pra onde tá voando (like avião, incluindo inclinação de subida/descida) em vez de ficar travado olhando pro nada enquanto `PlatformStand` desliga o auto-rotate do Humanoid. Não é opcional — é comportamento padrão do Fly, sempre ativo.

### Removido
- **`dist/` e `tools/minify.py`**: o bundle minificado (`release.lua`, `release_bug.lua`, `1nxiter.min.lua`) e o script que o gerava foram removidos — o loadstring público sempre apontou direto pro `src/main.lua` (ver README), então o bundle era peso morto que ninguém mantinha atualizado.

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
