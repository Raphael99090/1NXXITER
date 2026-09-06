local InterfaceMain = {}

-- Baixa (ou reaproveita, se já tiver em cache) o ícone customizado do repo
-- como um asset local, pra usar no topo da janela. Se o executor não
-- suportar writefile/getcustomasset, cai pro ícone padrão da lib.
local function GetCustomIconAsset()
    if not (writefile and getcustomasset and isfile) then return nil end
    local ICON_URL = "https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png"
    local fileName = "1nxiter_icon.png"
    local ok, result = pcall(function()
        if not isfile(fileName) then
            local data = game:HttpGet(ICON_URL .. "?cache=" .. math.random(1, 999999))
            writefile(fileName, data)
        end
        return getcustomasset(fileName)
    end)
    return ok and result or nil
end

function InterfaceMain:Load(Hub, Config, State)
    -- [1] CARREGAMENTO SEGURO DA WINDUI
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)

    if not success or not WindUI then
        return warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI.")
    end

    -- No mobile o botão de abrir fica embaixo da tela — sem isso as
    -- notificações ficariam empilhadas por cima dele.
    pcall(function() WindUI:SetNotificationLower(true) end)

    local customIcon = GetCustomIconAsset()

    -- [2] CRIAÇÃO DA JANELA PRINCIPAL
    -- A WindUI já resolve minimizar/restaurar em mobile sozinha via
    -- OpenButton (arrastável, com Draggable=true). O hack de bolinha
    -- customizada + hook em Window.Minimize + simulação de tecla via
    -- VirtualInputManager que a Fluent exigia (~250 linhas) não existe
    -- mais — é só configuração.
    local Window = WindUI:CreateWindow({
        Title = "1NXITER HUB",
        Author = "V3.0 · Modular SRC",
        Icon = customIcon or "house",
        Folder = "InxiterHub",
        Theme = Config.UITheme or "Dark",
        Size = UDim2.fromOffset(580, 460),
        ToggleKey = Enum.KeyCode.LeftControl,
        Acrylic = true,

        OpenButton = {
            Title = "1NX",
            Enabled = true,
            Draggable = true,
            OnlyMobile = false,
            Color = ColorSequence.new(
                Color3.fromRGB(120, 60, 200),
                Color3.fromRGB(60, 30, 110)
            ),
        },
    })

    -- Mesmo problema de sempre: alguma coisa desabilita os controles touch
    -- (joystick de andar) quando a janela abre/fecha. Força de volta pra
    -- garantir que o jogador sempre consegue andar.
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local function KeepTouchControlsEnabled()
        pcall(function()
            local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
            PlayerModule:GetControls():Enable()
        end)
        pcall(function() UserInputService.ModalEnabled = false end)
    end
    KeepTouchControlsEnabled()
    Window:OnOpen(KeepTouchControlsEnabled)
    Window:OnClose(KeepTouchControlsEnabled)

    -- [3] ESTRUTURA DE ABAS
    local Tabs = {
        Train = Window:Tab({ Title = "Treino", Icon = "activity" }),
        Combat = Window:Tab({ Title = "Combate", Icon = "swords" }),
        ESP = Window:Tab({ Title = "Visual", Icon = "eye" }),
        Movement = Window:Tab({ Title = "Movimento", Icon = "move" }),
        Camera = Window:Tab({ Title = "Câmera", Icon = "camera" }),
        System = Window:Tab({ Title = "Sistema", Icon = "settings" })
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

    -- Hub.UI.Library precisa existir ANTES de renderizar as abas — a
    -- SystemTab usa Hub.UI.Library pro dropdown de tema e pros Notify.
    Hub.UI.Library = WindUI
    Hub.UI.Window = Window

    SafeRender("TrainTab", Tabs.Train)
    SafeRender("CombatTab", Tabs.Combat)
    SafeRender("ESPTab", Tabs.ESP)
    SafeRender("MovementTab", Tabs.Movement)
    SafeRender("CameraTab", Tabs.Camera)
    SafeRender("SystemTab", Tabs.System)

    -- [5] FINALIZAÇÃO
    Tabs.Train:Select()

    WindUI:Notify({
        Title = "1NXITER HUB",
        Content = "Interface carregada com sucesso!",
        Icon = "solar:bell-bold",
        Duration = 5
    })
end

return InterfaceMain
