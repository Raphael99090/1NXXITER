local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.AutoTrain

    WindowTab:Section({ Title = "Controle de Treino", Desc = "Gerencie o treinamento automático do seu personagem.", Icon = "dumbbell" })

    -- Antes era AddParagraph (Fluent) — na WindUI o equivalente com
    -- :SetDesc() pra atualizar o texto depois é Section({Title=, Desc=}).
    local Status = WindowTab:Section({ Title = "Monitor", Desc = "Aguardando início..." })

    WindowTab:Button({
        Title = "INICIAR / PARAR TREINO",
        Desc = "Inicia ou pausa a rotina de exercícios.",
        Icon = "play",
        Callback = function()
            if Mod then
                Mod:Toggle(Config, State, Hub, function(t) Status:SetDesc(t) end)
            end
        end
    })

    WindowTab:Dropdown({
        Flag = "TrainMode",
        Title = "Modo de Exercício",
        Desc = "Escolha a animação e o comportamento do exercício.",
        Values = {"Canguru", "Flexão", "Polichinelo"},
        Value = Config.Mode or "Canguru",
        Callback = function(v) Config.Mode = v end
    })

    WindowTab:Section({ Title = "Configurações da Série", Desc = "Ajuste os parâmetros da contagem do treino.", Icon = "sliders-horizontal" })

    WindowTab:Input({
        Flag = "StartNum",
        Title = "Número Inicial",
        Desc = "De onde a contagem deve começar (ex: 0, 10, 100).",
        Value = "0",
        Callback = function(v) Config.StartNum = tonumber(v) or 0 end
    })

    -- Sem isso, o AutoTrain quebrava: ele faz Config.StartNum + Config.Quantity,
    -- e Quantity nunca era definido em lugar nenhum (ficava nil).
    WindowTab:Input({
        Flag = "Quantity",
        Title = "Quantidade de Números",
        Desc = "Quantos números serão contados no total da série.",
        Value = "50",
        Callback = function(v) Config.Quantity = tonumber(v) or 50 end
    })
    Config.Quantity = Config.Quantity or 50

    WindowTab:Toggle({
        Flag = "IsCountdown",
        Title = "Contagem Regressiva",
        Desc = "Conta de trás para frente (ex: 50, 49, 48...).",
        Value = false,
        Callback = function(v) Config.IsCountdown = v end
    })

    WindowTab:Slider({
        Flag = "TrainDelay",
        Title = "Velocidade (Delay)",
        Desc = "Tempo de espera entre cada número falado (em segundos).",
        Step = 0.1,
        Value = { Min = 0.5, Max = 5, Default = 1.4 },
        Callback = function(v) Config.Delay = v end
    })

    WindowTab:Toggle({
        Flag = "AutoCrouch",
        Title = "Auto Agachar (Canguru)",
        Desc = "Abaixa o personagem automaticamente durante o canguru.",
        Value = false,
        Callback = function(v) Config.AutoCrouch = v end
    })
end

return Tab
