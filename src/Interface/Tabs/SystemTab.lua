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

    -- O dropdown de tema não fica mais aqui: era manual e chamava
    -- Hub.UI.Window:SetTheme(v), método que não existe na Fluent. A troca
    -- de tema de verdade é construída pelo addon InterfaceManager, logo
    -- abaixo desta seção (veja Interface/Main.lua).

    WindowTab:AddSection("Utilitários")
    WindowTab:AddButton({ Title = "⚡ FPS BOOST", Callback = function() Utils:AntiLag() end })
    WindowTab:AddButton({ Title = "🔄 REJOIN", Callback = function() Utils:Rejoin() end })
    WindowTab:AddButton({ Title = "🌐 SERVER HOP", Callback = function() Utils:ServerHop() end })
    
    WindowTab:AddButton({ 
        Title = "FECHAR HUB", 
        Callback = function() 
            -- Antes só destruía a janela e deixava aimbot/noclip/FOV
            -- esticado etc. rodando pra sempre em segundo plano.
            Hub:Unload()
            getgenv().InxiterHubLoaded = false 
            getgenv().InxiterHubInstance = nil
        end 
    })
end

return Tab
