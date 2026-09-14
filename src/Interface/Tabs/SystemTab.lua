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

    local Aparencia = WindowTab:Section({ Title = "Aparência", Desc = "Mude o estilo visual do menu.", Icon = "palette", Opened = true })

    Aparencia:Dropdown({
        Flag = "UITheme", Title = "Tema do Hub", Desc = "Altera as cores da interface instantaneamente.",
        Values = (function() local names = {}; for name in pairs(WindUI:GetThemes()) do table.insert(names, name) end table.sort(names); return names end)(),
        Value = WindUI:GetCurrentTheme(),
        Callback = function(v) WindUI:SetTheme(v); Config.UITheme = v end
    })

    local Servidor = WindowTab:Section({ Title = "Ferramentas do Servidor", Desc = "Ações para reconectar e estabilizar.", Icon = "server", Opened = false })

    Servidor:Button({ Title = "FPS BOOST (Anti-Lag)", Desc = "Remove texturas do mapa para melhorar FPS.", Icon = "zap", Callback = function() Utils:AntiLag() end })
    Servidor:Button({ Title = "REJOIN", Desc = "Entra novamente neste mesmo servidor.", Icon = "rotate-cw", Callback = function() Utils:Rejoin() end })
    Servidor:Button({ Title = "SERVER HOP", Desc = "Busca e entra em um servidor mais vazio.", Icon = "globe", Callback = function() Utils:ServerHop() end })
    Servidor:Toggle({ Flag = "AutoRejoinE", Title = "Auto-Rejoin (Crash/Kick)", Desc = "Volta ao jogo se for desconectado.", Value = Config.AutoRejoin or false, Callback = function(v) Config.AutoRejoin = v end })
    Servidor:Toggle({ Flag = "AntiAFKE", Title = "Anti-AFK", Desc = "Evita ser kickado por inatividade.", Icon = "user-check", Value = Config.AntiAFK ~= false, Callback = function(v) Config.AntiAFK = v; Utils:ToggleAntiAFK(v) end })

    local Comunidade = WindowTab:Section({ Title = "Comunidade", Desc = "Fique por dentro das atualizações.", Icon = "users", Opened = false })

    Comunidade:Paragraph({
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

    local Dados = WindowTab:Section({ Title = "Gerenciamento de Dados", Desc = "Salvar e restaurar dados locais.", Icon = "database", Opened = false })

    Dados:Button({ Title = "SALVAR CONFIGURAÇÕES", Desc = "O hub já salva automaticamente a cada 8s, mas você pode forçar.", Icon = "save", Callback = function()
        StateMod:SaveConfig(Config); WindUI:Notify({Title="Salvo", Content="JSON atualizado!", Duration=3})
    end })

    Dados:Button({ Title = "RESTAURAR PADRÕES DE FÁBRICA", Desc = "Desativa recursos e restaura as configurações para os valores originais.", Icon = "rotate-ccw", Callback = function()
        local Window = Hub.UI.Window
        local function DoReset()
            StateMod:ResetConfig(Config)
            StateMod:SaveConfig(Config)
            if Hub.ApplyConfig then Hub:ApplyConfig() end
            WindUI:Notify({Title="Resetado", Content="Configurações restauradas e recursos desativados.", Duration=4})
        end
        if Window and Window.Dialog then
            Window:Dialog({
                Title = "Restaurar padrões?",
                Content = "Isso desativa Combate/Visual/Movimento/Câmera e apaga suas configurações salvas. Não dá pra desfazer.",
                Buttons = {
                    { Title = "Cancelar", Variant = "Tertiary" },
                    { Title = "Restaurar", Variant = "Primary", Callback = DoReset },
                }
            })
        else
            DoReset()
        end
    end })

    -- Status do Diagnóstico fica sempre visível (não fecha), o botão de
    -- imprimir fica dentro da categoria que pode ser minimizada.
    local Lifecycle = Hub.Core.Lifecycle
    local DoctorStatus = WindowTab:Section({ Title = "Status dos Módulos", Desc = "Carregando...", Opened = true })

    if Lifecycle then
        task.spawn(function()
            while getgenv().InxiterHubLoaded do
                local report = Lifecycle:Report()
                local failed = {}
                local okCount = 0
                for _, r in ipairs(report) do
                    if r.State == "FAILED" then
                        table.insert(failed, r.Name)
                    else
                        okCount = okCount + 1
                    end
                end
                if #failed > 0 then
                    DoctorStatus:SetDesc(string.format("⚠️ %d/%d módulos OK\nFalharam: %s", okCount, #report, table.concat(failed, ", ")))
                else
                    DoctorStatus:SetDesc(string.format("✅ %d/%d módulos OK", okCount, #report))
                end
                task.wait(3)
            end
        end)
    else
        DoctorStatus:SetDesc("Lifecycle Manager indisponível nessa sessão.")
    end

    local Diagnostico = WindowTab:Section({ Title = "Diagnóstico", Desc = "Estado real de cada módulo do Hub (Hub Doctor).", Icon = "stethoscope", Opened = false })

    Diagnostico:Button({ Title = "IMPRIMIR DIAGNÓSTICO (F9)", Desc = "Mostra estágio e erro de cada módulo, um por um, no console.", Icon = "terminal", Callback = function()
        if Lifecycle then
            Lifecycle:Print()
            WindUI:Notify({Title="Diagnóstico", Content="Impresso no console (F9).", Duration=3})
        else
            WindUI:Notify({Title="Diagnóstico", Content="Lifecycle Manager não carregou nessa sessão.", Duration=4})
        end
    end })

    local Perigo = WindowTab:Section({ Title = "Perigo", Desc = "Encerramento total do script.", Icon = "alert-triangle", Opened = false })

    Perigo:Button({ Title = "FECHAR HUB TOTALMENTE", Desc = "Remove do jogo e para todos os loops de fundo.", Icon = "power", Callback = function()
        local Window = Hub.UI.Window
        local function DoClose()
            Hub:Unload()
            getgenv().InxiterHubLoaded = false
            getgenv().InxiterHubInstance = nil
        end
        if Window and Window.Dialog then
            Window:Dialog({
                Title = "Fechar o hub?",
                Content = "Isso para o Aimbot, ESP, Fly e tudo mais que estiver ativo agora.",
                Buttons = {
                    { Title = "Cancelar", Variant = "Tertiary" },
                    { Title = "Fechar", Variant = "Primary", Callback = DoClose },
                }
            })
        else
            DoClose()
        end
    end })
end

return Tab
