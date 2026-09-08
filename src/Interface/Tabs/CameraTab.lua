local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    local Spy = Hub.Features.SpyChat

    WindowTab:Section({ Title = "Visualização", Desc = "Modifique a lente e a proporção da tela.", Icon = "monitor" })
    WindowTab:Toggle({ Flag = "StretchE", Title = "Tela Esticada", Desc = "Deixa a tela mais larga (hitboxes maiores visivelmente).", Icon = "maximize-2", Value = false, Callback = function(v) Vis:ToggleStretched(v) end })
    WindowTab:Slider({ Flag = "FOVVal", Title = "Campo de Visão (FOV)", Desc = "Aumente para ver mais do cenário.", Step = 1, Value = { Min = 30, Max = 120, Default = 70 }, Callback = function(v) Vis:UpdateFOV(v) end })

    WindowTab:Section({ Title = "Câmera Orbital", Desc = "Desprenda-se do personagem.", Icon = "video" })
    WindowTab:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Desc = "Controle uma câmera livre invisível.", Icon = "video", Value = false, Callback = function(v) Cam:Toggle(v) end })
    WindowTab:Slider({ Flag = "FreeCamSpeed", Title = "Velocidade", Desc = "Rapidez de voo da câmera.", Step = 0.1, Value = { Min = 0.1, Max = 10, Default = 1 }, Callback = function(v) Cam.Settings.Speed = v end })
    WindowTab:Slider({ Flag = "FreeCamSens", Title = "Sensibilidade", Desc = "Sensibilidade ao girar a visão.", Step = 0.1, Value = { Min = 0.1, Max = 3, Default = 0.5 }, Callback = function(v) Cam.Settings.Sensitivity = v end })

    WindowTab:Section({ Title = "Inteligência", Desc = "Painéis utilitários de informação.", Icon = "message-square" })
    WindowTab:Toggle({ Flag = "SpyE", Title = "Ativar Spy Chat", Desc = "Lê chat privado e comandos do servidor em uma UI arrastável.", Icon = "message-square-more", Value = false, Callback = function(v) Spy:Toggle(v) end })
end

return Tab
