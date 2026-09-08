local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.ESP
    local Players = game:GetService("Players")

    local Status = WindowTab:Section({ Title = "Status Visual", Desc = "ESP desligado" })

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            if Mod.Settings.Enabled then
                local count = math.max(0, #Players:GetPlayers() - 1)
                Status:SetDesc(string.format("👁️ %d jogador(es) detectado(s)", count))
            else
                Status:SetDesc("ESP desligado")
            end
            task.wait(1)
        end
    end)

    WindowTab:Section({ Title = "Chams (Highlight)", Desc = "Ilumina jogadores através das paredes.", Icon = "eye" })
    WindowTab:Toggle({ Flag = "ESPE", Title = "Ativar Chams", Desc = "Liga a visão de raio-x nos personagens.", Icon = "eye", Value = false, Callback = function(v) Mod:Toggle(v) end })
    WindowTab:Toggle({ Flag = "ESPT", Title = "Ocultar Aliados", Desc = "Não exibe chams no seu próprio time.", Icon = "user-round-x", Value = false, Callback = function(v) Mod.Settings.TeamCheck = v; Mod:Refresh() end })
    WindowTab:Slider({ Flag = "ESPFill", Title = "Transparência do Chams", Desc = "0 = Sólido, 1 = Transparente.", Step = 0.01, Value = { Min = 0, Max = 1, Default = 0.6 }, Callback = function(v) Mod.Settings.FillTransparency = v; Mod:Refresh() end })

    WindowTab:Section({ Title = "Rastreamento Extra", Desc = "Indicadores de posição adicionais.", Icon = "sparkles" })
    WindowTab:Toggle({ Flag = "ESPTracer", Title = "Tracers", Desc = "Desenha uma linha guia até o alvo.", Icon = "route", Value = false, Callback = function(v) Mod.Settings.Tracers = v end })
    WindowTab:Toggle({ Flag = "ESPDist", Title = "Distância", Desc = "Mostra a distância em metros.", Icon = "ruler", Value = false, Callback = function(v) Mod.Settings.Distance = v end })
end

return Tab
