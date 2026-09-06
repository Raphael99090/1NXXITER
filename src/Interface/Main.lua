local InterfaceMain = {}

-- Baixa/reaproveita o ícone customizado
local function GetCustomIconAsset()
    if not (writefile and getcustomasset and isfile) then
        return nil
    end

    local ICON_URL =
        "https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png"

    local fileName = "1nxiter_icon.png"

    local ok, result = pcall(function()
        if not isfile(fileName) then
            local data = game:HttpGet(
                ICON_URL .. "?cache=" .. math.random(1, 999999)
            )

            writefile(fileName, data)
        end

        return getcustomasset(fileName)
    end)

    return ok and result or nil
end


function InterfaceMain:Load(Hub, Config, State)

    -- =========================================================
    -- [1] CARREGAMENTO DA WINDUI
    -- =========================================================

    local success, WindUI = pcall(function()
        local source = game:HttpGet(
            "https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"
        )

        local loader = loadstring(source)

        assert(loader, "loadstring falhou ao carregar WindUI")

        return loader()
    end)

    if not success or not WindUI then
        return warn(
            "❌ [1NXITER]: Falha ao carregar a biblioteca WindUI -> "
            .. tostring(WindUI)
        )
    end


    -- =========================================================
    -- [2] CONFIGURAÇÕES GERAIS
    -- =========================================================

    pcall(function()
        WindUI:SetNotificationLower(true)
    end)

    local customIcon = GetCustomIconAsset()


    -- =========================================================
    -- [3] JANELA PRINCIPAL
    -- =========================================================
    --
    -- IMPORTANTE:
    -- Não passamos Config.UITheme para CreateWindow.
    --
    -- O Config antigo possui:
    -- UITheme = "Darker"
    --
    -- "Darker" pode não existir na versão atual do WindUI,
    -- causando:
    --
    -- attempt to index nil with 'PanelBackground'
    --
    -- Portanto a janela inicia com o tema padrão da biblioteca.
    -- O tema continua podendo ser alterado pela aba Sistema.
    --

    local windowConfig = {
        Title = "1NXITER HUB",
        Author = "V3.0 · Modular SRC",

        Icon = customIcon or "house",

        Folder = "InxiterHub",

        Size = UDim2.fromOffset(580, 460),

        ToggleKey = Enum.KeyCode.LeftControl,

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


    -- =========================================================
    -- [4] CRIAÇÃO DA JANELA
    -- =========================================================

    local ok, Window = pcall(function()
        return WindUI:CreateWindow(windowConfig)
    end)

    if not ok or not Window then
        return warn(
            "❌ [1NXITER]: Falha ao criar a janela WindUI -> "
            .. tostring(Window)
        )
    end


    -- =========================================================
    -- [5] CONTROLES MOBILE
    -- =========================================================

    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local UserInputService =
        game:GetService("UserInputService")


    local function KeepTouchControlsEnabled()

        pcall(function()

            local PlayerScripts =
                LocalPlayer:WaitForChild("PlayerScripts")

            local PlayerModule =
                require(
                    PlayerScripts:WaitForChild("PlayerModule")
                )

            PlayerModule:GetControls():Enable()

        end)


        pcall(function()
            UserInputService.ModalEnabled = false
        end)

    end


    KeepTouchControlsEnabled()


    pcall(function()
        Window:OnOpen(KeepTouchControlsEnabled)
    end)


    pcall(function()
        Window:OnClose(KeepTouchControlsEnabled)
    end)


    -- =========================================================
    -- [6] ABAS
    -- =========================================================

    local Tabs = {

        Train = Window:Tab({
            Title = "Treino",
            Icon = "activity"
        }),

        Combat = Window:Tab({
            Title = "Combate",
            Icon = "swords"
        }),

        ESP = Window:Tab({
            Title = "Visual",
            Icon = "eye"
        }),

        Movement = Window:Tab({
            Title = "Movimento",
            Icon = "move"
        }),

        Camera = Window:Tab({
            Title = "Câmera",
            Icon = "camera"
        }),

        System = Window:Tab({
            Title = "Sistema",
            Icon = "settings"
        }),

    }


    -- =========================================================
    -- [7] REFERÊNCIAS DA UI
    -- =========================================================

    Hub.UI.Library = WindUI
    Hub.UI.Window = Window


    -- =========================================================
    -- [8] RENDERIZAÇÃO SEGURA DAS ABAS
    -- =========================================================

    local function SafeRender(tabName, tabObject)

        local tabModule =
            Hub.UI.Tabs[tabName]


        if not tabModule then

            return warn(
                "⚠️ [1NXITER]: Módulo de aba não encontrado: "
                .. tabName
            )

        end


        if not tabModule.Render then

            return warn(
                "⚠️ [1NXITER]: Aba sem função Render: "
                .. tabName
            )

        end


        local renderOk, err = pcall(function()

            tabModule:Render(
                tabObject,
                Hub,
                Config,
                State
            )

        end)


        if not renderOk then

            warn(
                "❌ [1NXITER]: Erro ao renderizar aba "
                .. tabName
                .. " -> "
                .. tostring(err)
            )

        end

    end


    -- =========================================================
    -- [9] CARREGAR ABAS
    -- =========================================================

    SafeRender(
        "TrainTab",
        Tabs.Train
    )

    SafeRender(
        "CombatTab",
        Tabs.Combat
    )

    SafeRender(
        "ESPTab",
        Tabs.ESP
    )

    SafeRender(
        "MovementTab",
        Tabs.Movement
    )

    SafeRender(
        "CameraTab",
        Tabs.Camera
    )

    SafeRender(
        "SystemTab",
        Tabs.System
    )


    -- =========================================================
    -- [10] ABA INICIAL
    -- =========================================================

    pcall(function()
        Tabs.Train:Select()
    end)


    -- =========================================================
    -- [11] NOTIFICAÇÃO
    -- =========================================================

    pcall(function()

        WindUI:Notify({

            Title = "1NXITER HUB",

            Content =
                "Interface carregada com sucesso!",

            Icon = "solar:bell-bold",

            Duration = 5

        })

    end)

end


return InterfaceMain
