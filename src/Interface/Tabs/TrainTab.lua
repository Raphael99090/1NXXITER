local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.AutoTrain

    local Status = WindowTab:Section({ Title = "Status do Treinamento", Desc = "Aguardando início..." })

    WindowTab:Section({ Title = "Automação", Desc = "Controle o macro de treinamento e mensagens no chat.", Icon = "bot" })
    
    WindowTab:Button({ Title = "INICIAR / PARAR TREINO", Desc = "Liga ou pausa a contagem.", Icon = "play", Callback = function()
        if Mod then Mod:Toggle(Config, State, Hub, function(t) Status:SetDesc(t) end) end
    end })

    WindowTab:Dropdown({ Flag = "TrainMode", Title = "Tipo de Animação", Desc = "Define como o boneco se move durante a série.", Values = {"Canguru", "Flexão", "Polichinelo"}, Value = Config.Mode or "Canguru", Callback = function(v) Config.Mode = v end })
    WindowTab:Toggle({ Flag = "AutoCrouch", Title = "Auto Agachar (Só Canguru)", Desc = "Abaixa automaticamente antes de pular.", Value = Config.AutoCrouch or false, Callback = function(v) Config.AutoCrouch = v end })

    WindowTab:Section({ Title = "Configurações da Contagem", Desc = "Ajuste os parâmetros dos números falados.", Icon = "sliders-horizontal" })

    WindowTab:Input({ Flag = "StartNum", Title = "Número Inicial", Desc = "Ex: 0, 10, 100", Value = tostring(Config.StartNum or "0"), Callback = function(v) Config.StartNum = tonumber(v) or 0 end })
    Config.Quantity = Config.Quantity or 50
    WindowTab:Input({ Flag = "Quantity", Title = "Quantidade Total", Desc = "Ex: 50, 130", Value = tostring(Config.Quantity), Callback = function(v) Config.Quantity = tonumber(v) or 50 end })

    WindowTab:Toggle({ Flag = "IsCountdown", Title = "Ordem Regressiva", Desc = "Conta de trás pra frente.", Value = Config.IsCountdown or false, Callback = function(v) Config.IsCountdown = v end })
    WindowTab:Slider({ Flag = "TrainDelay", Title = "Intervalo (Segundos)", Desc = "Tempo de espera entre falas.", Step = 0.1, Value = { Min = 0.5, Max = 5, Default = Config.Delay or 1.4 }, Callback = function(v) Config.Delay = v end })
end

return Tab
