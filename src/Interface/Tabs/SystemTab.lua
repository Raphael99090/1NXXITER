local Tab = {}

local function IsPlaceholderLink(link)
    if not link or link == "" then return true end
    if link:find("SEU%-") or link:find("YOUR%-") or link:find("PLACEHOLDER") then return true end
    return false
end

local function CopyToClipboard(text)
    local copier = setclipboard or toclipboard
    if type(copier) ~= "function" then return false end
    return pcall(copier, text)
end

function Tab:Render(WindowTab, Hub, Config, State)
    local Utils = Hub.Core.Utils
    local StateMod = Hub.Core.State
    local WindUI = Hub.UI.Library

    WindowTab:Section({ Title = "Aparência", Desc = "Mude o estilo visual do menu.", Icon = "palette" })
    
    WindowTab:Dropdown({
        Flag = "UITheme", Title = "Tema do Hub", Desc = "Altera as cores da interface instantaneamente.",
        Values = (function() local names = {}; for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end table.sort(names); return names end)(),
        Value = WindUI:GetCurrentTheme(),
        Callback = function(v) WindUI:SetTheme(v); Config.UITheme = v end
    })

    WindowTab:Section({ Title = "Ferramentas do Servidor", Desc = "Ações para reconectar e estabilizar.", Icon = "server" })
    
    WindowTab:Button({ Title = "FPS BOOST (Anti-Lag)", Desc = "Remove texturas do mapa para melhorar FPS.", Icon = "zap", Callback = function() Utils:AntiLag() end })
    WindowTab:Button({ Title = "REJOIN", Desc = "Entra novamente neste mesmo servidor.", Icon = "rotate-cw", Callback = function() Utils:Rejoin() end })
    WindowTab:Button({ Title = "SERVER HOP", Desc = "Busca e entra em um servidor mais vazio.", Icon = "globe", Callback = function() Utils:ServerHop() end })
    WindowTab:Toggle({ Flag = "AutoRejoinE", Title = "Auto-Rejoin (Crash/Kick)", Desc = "Volta ao jogo se for desconectado.", Value = Config.AutoRejoin or false, Callback = function(v) Config.AutoRejoin = v end })

    WindowTab:Section({ Title = "Comunidade", Desc = "Fique por dentro das atualizações.", Icon = "users" })

    WindowTab:Paragraph({
        Title = "Servidor do Discord",
        Desc = 'Comunidade 1NXITER Oficial.',
        Image = "https://cdn.simpleicons.org/discord", ImageSize = 28, Color = "White",
        Buttons = {
            { Title = "Copiar link", Icon = "copy", Variant = "Tertiary", Callback = function()
                local link = Config.DiscordLink
                if IsPlaceholderLink(link) then WindUI:Notify({Title="Aviso", Content="Configure Config.DiscordLink.", Duration=4}); return end
                if CopyToClipboard(link) then WindUI:Notify({Title="Sucesso", Content="Link copiado!", Duration=3})
                else WindUI:Notify({Title="Discord", Content=link, Duration=5}) end
            end}
        }
    })

    WindowTab:Section({ Title = "Gerenciamento de Dados", Desc = "Salvar e restaurar dados locais.", Icon = "database" })

    WindowTab:Button({ Title = "SALVAR CONFIGURAÇÕES", Desc = "O hub já salva automaticamente a cada 8s, mas você pode forçar.", Icon = "save", Callback = function()
        StateMod:SaveConfig(Config); WindUI:Notify({Title="Salvo", Content="JSON atualizado!", Duration=3})
    end })

    WindowTab:Button({ Title = "RESTAURAR PADRÕES DE FÁBRICA", Desc = "Reseta todas as abas. Requer reabrir o hub.", Icon = "rotate-ccw", Callback = function()
        StateMod:ResetConfig(Config); StateMod:SaveConfig(Config); WindUI:Notify({Title="Resetado", Content="Reabra o hub para ver os botões resetados.", Duration=5})
    end })

    WindowTab:Section({ Title = "Perigo", Desc = "Encerramento total do script.", Icon = "alert-triangle" })

    WindowTab:Button({ Title = "FECHAR HUB TOTALMENTE", Desc = "Remove do jogo e para todos os loops de fundo.", Icon = "power", Callback = function()
        Hub:Unload()
        getgenv().InxiterHubLoaded = false
        getgenv().InxiterHubInstance = nil
    end })
end

return Tab
