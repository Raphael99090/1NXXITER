local InterfaceMain = {}

function InterfaceMain:Load(Hub, Config, State)
    -- [1] CARREGAMENTO SEGURO DA FLUENT
    local success, Fluent = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)

    if not success or not Fluent then
        return warn("❌ [1NXITER]: Falha ao carregar a biblioteca Fluent.")
    end

    -- A Fluent NÃO tem Window:SetTheme() — o tema só é setado uma vez na
    -- criação da janela. Trocar em runtime exige o addon oficial InterfaceManager.
    local imOk, InterfaceManager = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    end)
    if not imOk or not InterfaceManager then
        warn("⚠️ [1NXITER]: Falha ao carregar InterfaceManager — troca de tema ficará indisponível.")
        InterfaceManager = nil
    end

    -- [2] CRIAÇÃO DA JANELA PRINCIPAL
    local Window = Fluent:CreateWindow({
        Title = "1NXITER HUB | V3.0",
        SubTitle = "Modular SRC System",
        TabWidth = 160,
        Size = UDim2.fromOffset(580, 460),
        Acrylic = true,
        Theme = Config.UITheme or "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- [2.5] BOTÃO FLUTUANTE (BOLINHA)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local RunService = game:GetService("RunService")
    local TweenService = game:GetService("TweenService")

    -- Cria ScreenGui
    local MinimizeGui = Instance.new("ScreenGui")
    MinimizeGui.Name = "InxiterMinimizeButton"
    MinimizeGui.ResetOnSpawn = false
    MinimizeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MinimizeGui.Parent = PlayerGui

    -- Botão circular
    local CircleButton = Instance.new("ImageButton")
    CircleButton.Name = "RestoreButton"
    CircleButton.Size = UDim2.new(0, 55, 0, 55)
    CircleButton.Position = UDim2.new(1, -75, 0, 25)
    CircleButton.BackgroundColor3 = Color3.fromRGB(40, 20, 60) -- roxo escuro, combina com a logo
    CircleButton.ScaleType = Enum.ScaleType.Crop
    CircleButton.Image = ""
    CircleButton.ImageTransparency = 1 -- some até a imagem carregar (fade in)
    CircleButton.BorderSizePixel = 0
    CircleButton.AutoButtonColor = true
    CircleButton.ZIndex = 2
    CircleButton.Parent = MinimizeGui

    -- Aspect ratio: garante que ela nunca vire uma "elipse" em telas diferentes
    local AspectRatio = Instance.new("UIAspectRatioConstraint")
    AspectRatio.AspectRatio = 1
    AspectRatio.Parent = CircleButton

    -- (sombra removida — como filha do CircleButton ela renderizava por
    -- cima do ícone em vez de atrás, tampando a imagem e o clique)

    -- Texto de fallback (aparece até a imagem carregar / se o executor não suportar)
    local FallbackLabel = Instance.new("TextLabel")
    FallbackLabel.Name = "FallbackText"
    FallbackLabel.Size = UDim2.new(1, 0, 1, 0)
    FallbackLabel.BackgroundTransparency = 1
    FallbackLabel.Text = "1NX"
    FallbackLabel.TextColor3 = Color3.new(1, 1, 1)
    FallbackLabel.TextSize = 13
    FallbackLabel.Font = Enum.Font.GothamBold
    FallbackLabel.ZIndex = 2
    FallbackLabel.Parent = CircleButton

    -- Circular
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = CircleButton

    -- Stroke (cores da paleta roxo/dourado da logo, no lugar do vermelho genérico)
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(200, 160, 60)
    UIStroke.Thickness = 2
    UIStroke.Transparency = 0
    UIStroke.Parent = CircleButton

    -- Gradient
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 60, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 30, 110))
    })
    UIGradient.Rotation = 45
    UIGradient.Parent = CircleButton

    -- Glow pulsante no stroke enquanto minimizado (chama atenção sem irritar)
    local glowTween = nil
    local function StartGlowPulse()
        if glowTween then return end
        glowTween = TweenService:Create(
            UIStroke,
            TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
            { Transparency = 0.7 }
        )
        glowTween:Play()
    end
    local function StopGlowPulse()
        if glowTween then
            glowTween:Cancel()
            glowTween = nil
            UIStroke.Transparency = 0
        end
    end

    -- Esconde inicialmente
    MinimizeGui.Enabled = false

    -- ============================================================
    -- ÍCONE CUSTOMIZADO (baixado do repo)
    -- ============================================================
    -- Troque essa URL pra apontar pro seu arquivo de imagem no repo
    local ICON_URL = "https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png"

    local function LoadCustomIcon()
        if not (writefile and getcustomasset and isfile) then
            warn("⚠️ [1NXITER]: Executor sem suporte a writefile/getcustomasset — mantendo texto '1NX'.")
            CircleButton.ImageTransparency = 1
            return
        end

        local fileName = "1nxiter_icon.png"

        local ok, err = pcall(function()
            if not isfile(fileName) then
                local data = game:HttpGet(ICON_URL .. "?cache=" .. math.random(1, 999999))
                writefile(fileName, data)
            end
            local assetId = getcustomasset(fileName)
            CircleButton.Image = assetId

            -- Fade in suave em vez de trocar de repente
            TweenService:Create(CircleButton, TweenInfo.new(0.3), { ImageTransparency = 0 }):Play()
            TweenService:Create(FallbackLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
            task.delay(0.3, function() FallbackLabel.Visible = false end)
        end)

        if not ok then
            warn("❌ [1NXITER]: Falha ao carregar ícone customizado -> " .. tostring(err))
        end
    end

    task.spawn(LoadCustomIcon)

    -- Estado
    local isMinimized = false

    -- Mostrar
    local function ShowButton()
        MinimizeGui.Enabled = true
        TweenService:Create(CircleButton, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
        StartGlowPulse()
    end

    -- Esconder
    local function HideButton()
        StopGlowPulse()
        TweenService:Create(CircleButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.2, function()
            if not isMinimized then
                MinimizeGui.Enabled = false
            end
        end)
    end

    -- Draggable (com snap na borda mais próxima ao soltar)
    -- IMPORTANTE: só passa a "arrastar" de verdade depois de um limiar
    -- mínimo de movimento. Sem isso, o micro-tremor natural de qualquer
    -- toque já reposicionava o botão, e o Roblox deixava de reconhecer
    -- aquilo como clique nativo (MouseButton1Click nunca disparava).
    local DRAG_THRESHOLD = 6 -- pixels
    local dragging = false          -- true enquanto o dedo/mouse está apertado
    local dragThresholdExceeded = false -- true só quando passou do limiar (arrasto real)
    local wasDragged = false        -- lido pelo MouseButton1Click, resetado depois
    local dragStart, startPos
    local Camera = workspace.CurrentCamera

    CircleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragThresholdExceeded = false
            dragStart = input.Position
            startPos = CircleButton.Position
        end
    end)

    CircleButton.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart

            if not dragThresholdExceeded and delta.Magnitude > DRAG_THRESHOLD then
                dragThresholdExceeded = true
                TweenService:Create(CircleButton, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 48, 0, 48)
                }):Play()
            end

            if dragThresholdExceeded then
                CircleButton.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    CircleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            wasDragged = dragThresholdExceeded

            if dragThresholdExceeded then
                TweenService:Create(CircleButton, TweenInfo.new(0.1), {
                    Size = UDim2.new(0, 55, 0, 55)
                }):Play()

                -- Snap na borda esquerda ou direita mais próxima da tela
                local viewportSize = Camera and Camera.ViewportSize or Vector2.new(1920, 1080)
                local absPos = CircleButton.AbsolutePosition
                local absSize = CircleButton.AbsoluteSize
                local centerX = absPos.X + absSize.X / 2

                local targetX
                if centerX < viewportSize.X / 2 then
                    targetX = 20 -- encosta na borda esquerda
                else
                    targetX = viewportSize.X - absSize.X - 20 -- encosta na borda direita
                end

                -- Trava o Y dentro da tela também, pra nunca sair pulando fora
                local targetY = math.clamp(absPos.Y, 10, viewportSize.Y - absSize.Y - 10)

                TweenService:Create(CircleButton, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    Position = UDim2.new(0, targetX, 0, targetY)
                }):Play()
            end

            dragThresholdExceeded = false
        end
    end)

    -- Clique para restaurar
    -- Em vez de chamar Window:Minimize() direto (a assinatura real da Fluent
    -- é incerta e já causou restaurações que não funcionavam), simulamos o
    -- próprio toque da tecla MinimizeKey (LeftControl) — o mesmo caminho que
    -- JÁ sabemos que funciona, porque é assim que a bolinha aparece hoje.
    local VirtualInputManager = game:GetService("VirtualInputManager")

    CircleButton.MouseButton1Click:Connect(function()
        if wasDragged then
            wasDragged = false
            return
        end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)

    -- ============================================================
    -- DETECÇÃO VIA HOOK DIRETO NO Window:Minimize
    -- ============================================================
    -- Em vez de adivinhar qual Frame é o principal (frágil: a v3 da
    -- Fluent anima minimize/restore e pode nem tocar em .Visible),
    -- interceptamos o próprio método que a Fluent usa internamente
    -- (inclusive quando o usuário aperta o MinimizeKey = LeftControl).

    local OriginalMinimize = Window.Minimize

    Window.Minimize = function(self, ...)
        local result = OriginalMinimize(self, ...)

        -- Descobre o novo estado real da janela após a chamada.
        -- Chamamos Minimize() sempre como toggle puro (sem boolean) —
        -- o parâmetro da Fluent não é "estado desejado", então
        -- alternamos nosso próprio isMinimized manualmente.
        local arg = ...
        local nowMinimized
        if arg == true or arg == false then
            nowMinimized = arg
        else
            nowMinimized = not isMinimized
        end

        isMinimized = nowMinimized
        if isMinimized then
            ShowButton()
        else
            HideButton()
        end

        return result
    end

    -- [3] ESTRUTURA DE ABAS
    local Tabs = {
        Train = Window:AddTab({ Title = "Treino", Icon = "lucide-activity" }), -- "dumbbell" não existe no pacote da Fluent
        Combat = Window:AddTab({ Title = "Combate", Icon = "lucide-swords" }),
        ESP = Window:AddTab({ Title = "Visual", Icon = "lucide-eye" }),
        Movement = Window:AddTab({ Title = "Movimento", Icon = "lucide-move" }), -- "zap" não existe no pacote da Fluent
        Camera = Window:AddTab({ Title = "Câmera", Icon = "lucide-camera" }),
        System = Window:AddTab({ Title = "Sistema", Icon = "lucide-settings" })
    }

    -- [4] INICIALIZAÇÃO DOS MÓDULOS DE ABA
    local function SafeRender(tabName, tabObject)
        local tabModule = Hub.UI.Tabs[tabName]
        if tabModule and tabModule.Render then
            local ok, err = pcall(function()
                tabModule:Render(tabObject, Hub, Config, State)
            end)
            if not ok then warn("❌ [1NXITER]: Erro ao renderizar aba " .. tabName .. ": " .. tostring(err)) end
        else
            warn("⚠️ [1NXITER]: Módulo de aba não encontrado: " .. tabName)
        end
    end

    SafeRender("TrainTab", Tabs.Train)
    SafeRender("CombatTab", Tabs.Combat)
    SafeRender("ESPTab", Tabs.ESP)
    SafeRender("MovementTab", Tabs.Movement)
    SafeRender("CameraTab", Tabs.Camera)
    SafeRender("SystemTab", Tabs.System)

    -- Constrói a seção de tema DE VERDADE (dropdown + preview) dentro da
    -- aba Sistema, usando o addon oficial. Isso substitui o dropdown manual
    -- que chamava Window:SetTheme (método que não existe na Fluent).
    if InterfaceManager then
        local imOk, imErr = pcall(function()
            InterfaceManager:SetLibrary(Fluent)
            InterfaceManager:SetFolder("InxiterHub")
            InterfaceManager:BuildInterfaceSection(Tabs.System)
        end)
        if not imOk then
            warn("❌ [1NXITER]: Erro ao montar seção de tema -> " .. tostring(imErr))
        end
    end

    -- [5] FINALIZAÇÃO
    Window:SelectTab(1)

    Fluent:Notify({
        Title = "1NXITER HUB",
        Content = "Interface modular carregada com sucesso!",
        Duration = 5
    })

    Hub.UI.Library = Fluent
    Hub.UI.Window = Window
    Hub.UI.MinimizeButton = CircleButton
    Hub.UI.MinimizeGui = MinimizeGui
end

return InterfaceMain
