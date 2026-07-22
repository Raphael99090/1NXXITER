local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.AutoTrain
    
    WindowTab:AddSection("Controle de Treino")
    
    local Status = WindowTab:AddParagraph({
        Title = "Monitor",
        Content = "Aguardando início..."
    })

    WindowTab:AddButton({
        Title = "INICIAR / PARAR TREINO",
        Callback = function()
            if Mod then 
                Mod:Toggle(Config, State, Hub, function(t) Status:SetDesc(t) end) 
            end
        end
    })

    WindowTab:AddDropdown("TrainMode", {
        Title = "Modo de Exercício",
        Values = {"Canguru", "Flexão", "Polichinelo"},
        Default = Config.Mode or "Canguru",
        Callback = function(v) Config.Mode = v end
    })

    WindowTab:AddSection("Configurações da Série")
    
    WindowTab:AddInput("StartNum", {
        Title = "Número Inicial",
        Default = "0",
        Callback = function(v) Config.StartNum = tonumber(v) or 0 end
    })

    WindowTab:AddSlider("TrainDelay", {
        Title = "Velocidade (Delay)",
        Min = 0.5, Max = 5, Default = 1.4, Rounding = 1,
        Callback = function(v) Config.Delay = v end
    })

    WindowTab:AddToggle("AutoCrouch", { Title = "Auto Agachar (Canguru)", Default = false, Callback = function(v) Config.AutoCrouch = v end })
end

return Tab
