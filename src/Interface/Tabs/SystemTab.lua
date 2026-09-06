local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Utils = Hub.Core.Utils
    local StateMod = Hub.Core.State
    local WindUI = Hub.UI.Library

    WindowTab:Section({ Title = "Aparência" })
    -- Antes isso era montado pelo addon InterfaceManager da Fluent (que
    -- nem tinha SetTheme nativo). A WindUI já tem troca de tema embutida
    -- (WindUI:SetTheme), então é só um dropdown normal.
    WindowTab:Dropdown({
        Flag = "UITheme",
        Title = "Tema",
        Values = (function()
            local names = {}
            for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end
            table.sort(names)
            return names
        end)(),
        Value = WindUI:GetCurrentTheme(),
        Callback = function(v)
            WindUI:SetTheme(v)
            Config.UITheme = v
        end
    })

    WindowTab:Section({ Title = "Gerenciamento" })
    WindowTab:Button({
        Title = "💾 SALVAR CONFIGURAÇÕES",
        Callback = function()
            StateMod:SaveConfig(Config)
            WindUI:Notify({ Title = "Salvo", Content = "JSON Atualizado!", Duration = 3 })
        end
    })

    WindowTab:Button({
        Title = "↩️ RESTAURAR PADRÕES",
        Callback = function()
            StateMod:ResetConfig(Config)
            StateMod:SaveConfig(Config)
            WindUI:Notify({
                Title = "Configurações restauradas",
                Content = "Reabra o hub pra ver os controles atualizados.",
                Duration = 5
            })
        end
    })

    -- Config.AutoRejoin já existia (Utils:AutoRejoin escuta ErrorMessageChanged
    -- e confere essa flag) mas não tinha toggle nenhum na UI pra ligar.
    WindowTab:Toggle({
        Flag = "AutoRejoinE",
        Title = "Auto-Rejoin (ao cair do servidor)",
        Value = Config.AutoRejoin or false,
        Callback = function(v) Config.AutoRejoin = v end
    })

    WindowTab:Section({ Title = "Utilitários" })
    WindowTab:Button({ Title = "⚡ FPS BOOST", Callback = function() Utils:AntiLag() end })
    WindowTab:Button({ Title = "🔄 REJOIN", Callback = function() Utils:Rejoin() end })
    WindowTab:Button({ Title = "🌐 SERVER HOP", Callback = function() Utils:ServerHop() end })

    WindowTab:Button({
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
