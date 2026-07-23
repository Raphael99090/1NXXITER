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
    local CircleButton = Instance.new("ImageButton")
    CircleButton.Name = "RestoreButton"
    CircleButton.Size = UDim2.new(0, 55, 0, 55)
    CircleButton.Position = UDim2.new(1, -75, 0, 25)
    CircleButton.BackgroundColor3 = Color3.fromRGB(220, 40, 40)
    CircleButton.ScaleType = Enum.ScaleType.Crop
    CircleButton.Image = "" -- preenchido depois pelo LoadCustomIcon, se disponível
    CircleButton.BorderSizePixel = 0
    CircleButton.AutoButtonColor = true
    CircleButton.Parent = MinimizeGui

    -- Texto de fallback (aparece atrás da imagem; some se a imagem carregar)
    local FallbackLabel = Instance.new("TextLabel")
    FallbackLabel.Name = "FallbackText"
    FallbackLabel.Size = UDim2.new(1, 0, 1, 0)
    FallbackLabel.BackgroundTransparency = 1
    FallbackLabel.Text = "1NX"
    FallbackLabel.TextColor3 = Color3.new(1, 1, 1)
    FallbackLabel.TextSize = 13
    FallbackLabel.Font = Enum.Font.GothamBold
    FallbackLabel.ZIndex = CircleButton.ZIndex - 1
    FallbackLabel.Parent = CircleButton

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

    -- ============================================================
    -- ÍCONE CUSTOMIZADO (baixado do repo)
    -- ============================================================
    -- Troque essa URL pra apontar pro seu arquivo de imagem no repo
    local ICON_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/Assets/1784776415112.png"

    local function LoadCustomIcon()
        if not (writefile and getcustomasset and isfile) then
            warn("⚠️ [1NXITER]: Executor sem suporte a writefile/getcustomasset — mantendo texto '1NX'.")
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
            FallbackLabel.Visible = false
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
        Window:Minimize() -- toggle puro, igual o LeftControl interno da Fluent — o hook acima cuida do resto
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
