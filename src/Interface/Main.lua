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

    -- [2.5] BOTÃO FLUTUANTE (BOLINHA) PARA RESTAURAR
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    -- Cria ScreenGui para a bolinha
    local MinimizeGui = Instance.new("ScreenGui")
    MinimizeGui.Name = "InxiterMinimizeButton"
    MinimizeGui.ResetOnSpawn = false
    MinimizeGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    MinimizeGui.Parent = PlayerGui

    -- Botão circular
    local CircleButton = Instance.new("TextButton")
    CircleButton.Name = "RestoreButton"
    CircleButton.Size = UDim2.new(0, 50, 0, 50)
    CircleButton.Position = UDim2.new(1, -70, 0, 20) -- Canto superior direito
    CircleButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
    CircleButton.Text = "1NX"
    CircleButton.TextColor3 = Color3.new(1, 1, 1)
    CircleButton.TextSize = 14
    CircleButton.Font = Enum.Font.GothamBold
    CircleButton.BorderSizePixel = 0
    CircleButton.AutoButtonColor = true
    CircleButton.Parent = MinimizeGui

    -- Deixa circular
    local UICorner = Instance.new("UICorner")
    UICorner.CornerRadius = UDim.new(1, 0)
    UICorner.Parent = CircleButton

    -- Sombra/efeito
    local UIStroke = Instance.new("UIStroke")
    UIStroke.Color = Color3.fromRGB(200, 0, 0)
    UIStroke.Thickness = 2
    UIStroke.Parent = CircleButton

    -- Glow effect
    local UIGradient = Instance.new("UIGradient")
    UIGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 30, 30))
    })
    UIGradient.Parent = CircleButton

    -- Esconde a bolinha inicialmente (janela começa aberta)
    MinimizeGui.Enabled = false

    -- Draggable (arrastável)
    local dragging = false
    local dragStart, startPos

    CircleButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = CircleButton.Position
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
        end
    end)

    -- Clique para restaurar
    CircleButton.MouseButton1Click:Connect(function()
        Window:Minimize(false) -- Restaura a janela
        MinimizeGui.Enabled = false
    end)

    -- Detecta quando a janela é minimizada
    local oldMinimize = Window.Minimize
    if oldMinimize then
        Window.Minimize = function(self, state)
            oldMinimize(self, state)
            MinimizeGui.Enabled = state
        end
    end

    -- Hook no botão de minimizar da Fluent (se existir)
    task.spawn(function()
        task.wait(1)
        -- Tenta detectar o botão de minimizar da Fluent
        local fluentGui = PlayerGui:FindFirstChild("Fluent")
        if fluentGui then
            for _, obj in pairs(fluentGui:GetDescendants()) do
                if obj:IsA("TextButton") or obj:IsA("ImageButton") then
                    -- Procura por botão de minimizar (geralmente tem ícone de traço ou seta)
                    if obj.Name:lower():find("min") or obj.Name:lower():find("hide") then
                        obj.MouseButton1Click:Connect(function()
                            task.wait(0.1)
                            MinimizeGui.Enabled = true
                        end)
                    end
                end
            end
        end
    end)

    -- Também detecta via tecla de minimizar
    local UserInputService = game:GetService("UserInputService")
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
            task.wait(0.1)
            -- Verifica se a janela está minimizada
            local isMinimized = false
            pcall(function()
                -- Tenta detectar estado pela visibilidade
                local fluentGui = PlayerGui:FindFirstChild("Fluent")
                if fluentGui then
                    local mainFrame = fluentGui:FindFirstChildOfClass("Frame")
                    if mainFrame then
                        isMinimized = not mainFrame.Visible
                    end
                end
            end)
            MinimizeGui.Enabled = isMinimized
        end
    end)

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
