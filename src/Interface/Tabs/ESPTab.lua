local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.ESP
    local Players = game:GetService("Players")

    WindowTab:Section({ Title = "Chams", Desc = "Rastreie a posição de outros jogadores através das paredes.", Icon = "eye" })

    local Status = WindowTab:Section({ Title = "Jogadores detectados", Desc = "ESP desligado" })

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            if Mod.Settings.Enabled then
                local count = math.max(0, #Players:GetPlayers() - 1) -- -1 pra não contar você mesmo
                Status:SetDesc(tostring(count) .. " jogador(es) na partida")
            else
                Status:SetDesc("ESP desligado")
            end
            task.wait(1)
        end
    end)

    WindowTab:Toggle({ Flag = "ESPE", Title = "Ativar Chams", Desc = "Destaca os personagens no mapa.", Icon = "eye", Value = false, Callback = function(v) Mod:Toggle(v) end })
    WindowTab:Toggle({
        Flag = "ESPT",
        Title = "Ocultar Aliados",
        Desc = "Não desenha o Chams nos membros do seu próprio time.",
        Icon = "user-round-x",
        Value = false,
        Callback = function(v)
            Mod.Settings.TeamCheck = v
            Mod:Refresh()
        end
    })
    WindowTab:Slider({
        Flag = "ESPFill",
        Title = "Transparência do Preenchimento",
        Desc = "O quão transparente a pintura nos jogadores será.",
        Step = 0.01,
        Value = { Min = 0, Max = 1, Default = 0.6 },
        Callback = function(v)
            Mod.Settings.FillTransparency = v
            Mod:Refresh()
        end
    })

    WindowTab:Section({ Title = "Extras", Desc = "Informações adicionais sobre os alvos.", Icon = "sparkles" })
    WindowTab:Toggle({ Flag = "ESPTracer", Title = "Tracers (linha até o jogador)", Desc = "Desenha uma linha do centro da sua tela até cada jogador.", Icon = "route", Value = false, Callback = function(v) Mod.Settings.Tracers = v end })
    WindowTab:Toggle({ Flag = "ESPDist", Title = "Mostrar Distância", Desc = "Exibe a distância em blocos/studs até o jogador.", Icon = "ruler", Value = false, Callback = function(v) Mod.Settings.Distance = v end })
end

return Tab
