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
        Acrylic = true, -- Efeito de desfoque (Blur)
        Theme = Config.UITheme or "Darker",
        MinimizeKey = Enum.KeyCode.LeftControl
    })

    -- [3] ESTRUTURA DE ABAS (DEFINIÇÃO)
    -- Criamos as abas físicas e depois passamos para os módulos de renderização
    local Tabs = {
        Train = Window:AddTab({ Title = "Treino", Icon = "dumbbell" }),
        Combat = Window:AddTab({ Title = "Combate", Icon = "swords" }),
        ESP = Window:AddTab({ Title = "Visual", Icon = "eye" }),
        Movement = Window:AddTab({ Title = "Movimento", Icon = "zap" }),
        Camera = Window:AddTab({ Title = "Câmera", Icon = "camera" }),
        System = Window:AddTab({ Title = "Sistema", Icon = "settings" })
    }

    -- [4] INICIALIZAÇÃO DOS MÓDULOS DE ABA (RENDER)
    -- Cada arquivo em Interface/Tabs tem uma função :Render()
    
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

    -- Chama a renderização para cada aba
    SafeRender("TrainTab", Tabs.Train)
    SafeRender("CombatTab", Tabs.Combat)
    SafeRender("ESPTab", Tabs.ESP)
    SafeRender("MovementTab", Tabs.Movement)
    SafeRender("CameraTab", Tabs.Camera)
    SafeRender("SystemTab", Tabs.System)

    -- [5] FINALIZAÇÃO
    Window:SelectTab(1) -- Abre na aba de treino por padrão

    Fluent:Notify({
        Title = "1NXITER HUB",
        Content = "Interface modular carregada com sucesso!",
        Duration = 5
    })

    -- Salva o objeto Fluent e Window no Hub caso precise fechar depois
    Hub.UI.Library = Fluent
    Hub.UI.Window = Window
end

return InterfaceMain
