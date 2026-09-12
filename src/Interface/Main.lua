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
        -- Descarta qualquer WindUI antiga deixada por outra execução.
        -- Uma instância antiga pode ser um ScreenGui e causar:
        -- "Window is not a valid member of ScreenGui WindUI".
        getgenv().WindUI = nil
        local url = "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua?cache=" .. tostring(os.clock())
        local lib = loadstring(game:HttpGet(url))()
        assert(type(lib) == "table" and type(lib.CreateWindow) == "function", "WindUI carregada sem CreateWindow")
        getgenv().WindUI = lib
        return lib
    end)

    if not success or not WindUI then
        return warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI.")
    end

    -- No mobile o botão de abrir fica embaixo da tela — sem isso as
    -- notificações ficariam empilhadas por cima dele.
    pcall(function() WindUI:SetNotificationLower(true) end)

    local customIcon = GetCustomIconAsset()

    -- Gradiente escuro-pra-ciano sutil pro fundo da janela (a mesma tela
    -- que mostra a key gate antes das abas aparecerem). Calculado uma vez
    -- só; cai pro visual padrão do tema se WindUI:Gradient não existir
    -- nessa versão da lib ou se o pcall falhar por qualquer motivo.
    local windowBackground = nil
    if type(WindUI.Gradient) == "function" then
        local ok, gradient = pcall(function()
            return WindUI:Gradient({
                ["0"] = { Color = Color3.fromHex("#050B14"), Transparency = 1 },
                ["100"] = { Color = Color3.fromHex("#0B2438"), Transparency = 0.85 },
            }, { Rotation = 45 })
        end)
        if ok then windowBackground = gradient end
    end

    -- [2] CRIAÇÃO DA JANELA PRINCIPAL
    -- A WindUI já resolve minimizar/restaurar em mobile sozinha via
    -- OpenButton (arrastável, com Draggable=true). O hack de bolinha
    -- customizada + hook em Window.Minimize + simulação de tecla via
    -- VirtualInputManager que a Fluent exigia (~250 linhas) não existe
    -- mais — é só configuração.
    --
    -- Acrylic = true quebrava no seu executor ("attempt to index nil with
    -- 'AcrylicMain'") — bug interno da WindUI (ainda em Beta) nesse efeito
    -- de vidro fosco. Tirado por enquanto; o resto da janela funciona igual.
    local windowConfig = {
        Title = "1NXITER HUB",
        Author = "V3.0 · Modular SRC",
        Icon = customIcon or "house",
        Folder = "InxiterHub",
        Size = UDim2.fromOffset(580, 460),
        ToggleKey = Enum.KeyCode[Config.UIToggleKey or "LeftControl"] or Enum.KeyCode.LeftControl,

        -- KeySystem nativo da WindUI — troca as ~220 linhas que existiam
        -- antes (HWID manual, fetch da lib PUSL do Panda, janela própria)
        -- por isto. "pandadevelopment" não pede Secret, só o ServiceId
        -- que já é público (aparece até na URL do GetKey). SaveKey evita
        -- pedir a key de novo toda vez que o hub carrega.
        --
        -- Note/URL/Thumbnail e o Title/Desc/Icon do provedor são só pra
        -- deixar a tela de key com a cara do hub em vez do formulário
        -- genérico padrão da lib — reaproveita o mesmo ícone customizado
        -- (customIcon) que já usamos no topo da janela.
        KeySystem = Hub.KeyConfig and {
            Note = "🐼 Ainda não tem key? Clica no link abaixo pra pegar a sua — travada automaticamente no seu HWID.",
            URL = "https://ads.pandauth.com/getkey/" .. Hub.KeyConfig.ServiceId,
            Thumbnail = {
                Image = customIcon or "https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png",
                Title = "1NXITER HUB",
            },
            API = {
                {
                    Title = "Panda Auth",
                    Desc = "Validação server-side, key travada no seu HWID.",
                    Icon = "shield-check",
                    Type = "pandadevelopment",
                    ServiceId = Hub.KeyConfig.ServiceId,
                },
            },
            Key = Hub.KeyConfig.TestKey and { Hub.KeyConfig.TestKey } or nil,
            SaveKey = true,
        } or nil,

        -- Gradiente escuro-pra-ciano sutil no fundo da janela (a mesma tela
        -- que mostra a key gate antes das abas aparecerem) — só estética,
        -- cai pro visual padrão do tema se WindUI:Gradient não existir
        -- nessa versão da lib.
        Background = windowBackground,

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
    }

    local ok, Window = pcall(function() return WindUI:CreateWindow(windowConfig) end)
    if not ok or not Window then
        -- Tenta uma única vez com uma biblioteca totalmente nova.
        -- Isso recupera de cache/estado corrompido sem duplicar a UI.
        warn("⚠️ [1NXITER]: WindUI falhou ao criar a janela; recarregando a biblioteca...")
        local reloadOk, freshWindUI = pcall(function()
            getgenv().WindUI = nil
            local url = "https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua?retry=" .. tostring(os.clock())
            local lib = loadstring(game:HttpGet(url))()
            assert(type(lib) == "table" and type(lib.CreateWindow) == "function", "WindUI recarregada sem CreateWindow")
            getgenv().WindUI = lib
            return lib
        end)
        if reloadOk and freshWindUI then
            WindUI = freshWindUI
            ok, Window = pcall(function() return WindUI:CreateWindow(windowConfig) end)
        end
    end
    if not ok or not Window then
        return warn("❌ [1NXITER]: Falha ao criar a janela WindUI -> " .. tostring(Window))
    end

    -- Mesmo problema de sempre: alguma coisa desabilita os controles touch
    -- (joystick de andar) quando a janela abre/fecha. Força de volta pra
    -- garantir que o jogador sempre consegue andar.
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local UserInputService = game:GetService("UserInputService")
    local function KeepTouchControlsEnabled()
        getgenv().InxiterKeepTouchControls = function()
            local Players = game:GetService("Players")
            local LocalPlayer = Players.LocalPlayer
            local UserInputService = game:GetService("UserInputService")
            pcall(function()
                local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
                PlayerModule:GetControls():Enable()
            end)
            pcall(function() UserInputService.ModalEnabled = false end)
        end
        getgenv().InxiterKeepTouchControls()
    end
    KeepTouchControlsEnabled()
    Window:OnOpen(KeepTouchControlsEnabled)
    Window:OnClose(KeepTouchControlsEnabled)

    -- [3] ESTRUTURA DE ABAS
    local Tabs = {
        Overview = Window:Tab({ Title = "Visão Geral", Icon = "layout-dashboard" }),
        Combat = Window:Tab({ Title = "Combate", Icon = "swords" }),
        ESP = Window:Tab({ Title = "Visual", Icon = "eye" }),
        Movement = Window:Tab({ Title = "Movimento", Icon = "move" }),
        Train = Window:Tab({ Title = "Treino", Icon = "dumbbell" }),
        Camera = Window:Tab({ Title = "Câmera", Icon = "camera" }),
        TAS = Window:Tab({ Title = "TAS", Icon = "film" }),
        Shortcuts = Window:Tab({ Title = "Atalhos", Icon = "keyboard" }),
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

    SafeRender("OverviewTab", Tabs.Overview)
    SafeRender("CombatTab", Tabs.Combat)
    SafeRender("ESPTab", Tabs.ESP)
    SafeRender("MovementTab", Tabs.Movement)
    SafeRender("TrainTab", Tabs.Train)
    SafeRender("CameraTab", Tabs.Camera)
    SafeRender("TASTab", Tabs.TAS)
    SafeRender("ShortcutsTab", Tabs.Shortcuts)
    SafeRender("SystemTab", Tabs.System)

    -- [5] FINALIZAÇÃO
    Tabs.Overview:Select()

    WindUI:Notify({
        Title = "1NXITER HUB",
        Content = "Interface carregada com sucesso!",
        Icon = "solar:bell-bold",
        Duration = 5
    })
end

return InterfaceMain
