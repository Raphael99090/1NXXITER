local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Utils = Hub.Core.Utils
    local StateMod = Hub.Core.State

    WindowTab:AddSection("Gerenciamento")
    WindowTab:AddButton({
        Title = "💾 SALVAR CONFIGURAÇÕES",
        Callback = function() 
            StateMod:SaveConfig(Config)
            Hub.UI.Library:Notify({ Title = "Salvo", Content = "JSON Atualizado!", Duration = 3 })
        end
    })

    WindowTab:AddDropdown("Theme", {
        Title = "Tema da Interface",
        Values = {"Dark", "Darker", "Light", "Aqua", "Amethyst"},
        Default = Config.UITheme or "Darker",
        Callback = function(v) 
            Hub.UI.Window:SetTheme(v) 
            Config.UITheme = v 
        end
    })

    WindowTab:AddSection("Utilitários")
    WindowTab:AddButton({ Title = "⚡ FPS BOOST", Callback = function() Utils:AntiLag() end })
    WindowTab:AddButton({ Title = "🔄 REJOIN", Callback = function() Utils:Rejoin() end })
    WindowTab:AddButton({ Title = "🌐 SERVER HOP", Callback = function() Utils:ServerHop() end })
    
    WindowTab:AddButton({ 
        Title = "FECHAR HUB", 
        Callback = function() 
            Hub.UI.Window:Destroy() 
            getgenv().InxiterHubLoaded = false 
        end 
    })
end

return Tab
