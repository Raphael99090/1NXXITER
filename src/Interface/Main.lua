local InterfaceMain = {}

function InterfaceMain:Load(Hub, Config, State)
    -- [1] CARREGAMENTO SEGURO DA FLUENT
    local success, Fluent = pcall(function()
        return loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    end)

    if not success or not Fluent then
        return warn("❌ [1NXITER]: Falha ao carregar a biblioteca Fluent.")
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
    local CircleButton = Instance.new("TextButton")
    CircleButton.Name = "RestoreButton"
    CircleButton.Size = UDim2.new(0, 55, 0, 55)
    CircleButton.Position = UDim2.new(1, -75, 0, 25)
    CircleButton.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    CircleButton.Text = "1NX"
    CircleButton.TextColor3 = Color3.new(1, 1, 1)
    CircleButton.TextSize = 13
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.BorderSizePixel = 0
    CircleButton.AutoButtonColor = true
    CircleButton.Parent = MinimizeGui

    -- Circular
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = CircleButton

    -- Stroke
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(180, 20, 20)
    UIStroke.Thickness = 2
    UIStroke.Parent = CircleButton

    -- Gradient
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))
    })
    UIGradient.Rotation = 45
    UIGradient.Parent = CircleButton

    -- Esconde inicialmente
    MinimizeGui.Enabled = false

    -- Estado
    local isMinimized = false

    -- Mostrar
    local function ShowButton()
        MinimizeGui.Enabled = true
        TweenService:Create(CircleButton, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 55, 0, 55)
        }):Play()
    end

    -- Esconder
    local function HideButton()
        TweenService:Create(CircleButton, TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0)
        }):Play()
        task.delay(0.2, function()
            if not isMinimized then
                MinimizeGui.Enabled = false
            end
        end)
    end

    -- Draggable
    local dragging = false
    local dragStart, startPos

    CircleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = CircleButton.Position
            TweenService:Create(CircleButton, TweenInfo.new(0.1), {
                Size = UDim2.new(0, 48, 0, 48)
            }):Play()
        end
    end)

    CircleButton.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            CircleButton.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)

    CircleButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            TweenService:Create(CircleButton, TweenInfo.new(0.1), {
                Size = UDim2.new(0, 55, 0, 55)
            }):Play()
        end
    end)

    -- Clique para restaurar
    CircleButton.MouseButton1Click:Connect(function()
        if dragging then return end
        Window:Minimize(false) -- o hook acima já atualiza isMinimized e esconde a bolinha
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
        -- A Fluent aceita Minimize(true/false); se vier sem argumento
        -- (toggle via keybind), consultamos uma flag própria conhecida
        -- da lib como fallback, senão alternamos o nosso próprio estado.
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
        Train = Window:AddTab({ Title = "Treino", Icon = "dumbbell" }),
        Combat = Window:AddTab({ Title = "Combate", Icon = "swords" }),
        ESP = Window:AddTab({ Title = "Visual", Icon = "eye" }),
        Movement = Window:AddTab({ Title = "Movimento", Icon = "zap" }),
        Camera = Window:AddTab({ Title = "Câmera", Icon = "camera" }),
        System = Window:AddTab({ Title = "Sistema", Icon = "settings" })
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
