local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    Config.Camera = Config.Camera or {}
    local Cfg = Config.Camera

    if Vis then
        local Visual = WindowTab:Section({ Title = "Visualização", Desc = "Modifique a lente e a proporção da tela.", Icon = "monitor", Opened = true })
        Visual:Toggle({ Flag = "StretchE", Title = "Tela Esticada", Desc = "Deixa a tela mais larga (hitboxes maiores visivelmente).", Icon = "maximize-2", Value = Cfg.StretchedEnabled == true, Callback = function(v) Cfg.StretchedEnabled = v; Vis:ToggleStretched(v) end })
        Visual:Slider({ Flag = "FOVVal", Title = "Campo de Visão (FOV)", Desc = "Aumente para ver mais do cenário.", Step = 1, Value = { Min = 30, Max = 120, Default = Cfg.FOVValue or 70 }, Callback = function(v) Cfg.FOVValue = v; Vis:UpdateFOV(v) end })
    else
        WindowTab:Section({ Title = "⚠️ Visualização indisponível", Desc = "O módulo Visuals falhou ao carregar nessa sessão.", Icon = "alert-triangle" })
    end

    if Cam then
        local Orbital = WindowTab:Section({ Title = "Câmera Orbital", Desc = "Desprenda-se do personagem.", Icon = "video", Opened = false })
        Orbital:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Desc = "Controle uma câmera livre invisível.", Icon = "video", Value = Cfg.FreeCamEnabled == true, Callback = function(v) Cfg.FreeCamEnabled = v; Cam:Toggle(v) end })
        Orbital:Slider({ Flag = "FreeCamSpeed", Title = "Velocidade", Desc = "Rapidez de voo da câmera.", Step = 0.1, Value = { Min = 0.1, Max = 10, Default = Cfg.FreeCamSpeed or 1 }, Callback = function(v) Cfg.FreeCamSpeed = v; Cam.Settings.Speed = v end })
        Orbital:Slider({ Flag = "FreeCamSens", Title = "Sensibilidade", Desc = "Sensibilidade ao girar a visão.", Step = 0.1, Value = { Min = 0.1, Max = 3, Default = Cfg.FreeCamSensitivity or 0.5 }, Callback = function(v) Cfg.FreeCamSensitivity = v; Cam.Settings.Sensitivity = v end })
    else
        WindowTab:Section({ Title = "⚠️ FreeCam indisponível", Desc = "O módulo FreeCam falhou ao carregar nessa sessão.", Icon = "alert-triangle" })
    end
end

return Tab
