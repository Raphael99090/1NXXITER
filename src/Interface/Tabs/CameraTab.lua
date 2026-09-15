local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    Config.Camera = Config.Camera or {}
    local Cfg = Config.Camera

    if Vis then
        local Visual = WindowTab:Section({ Title = "Visualização", Desc = "Campo de visão customizado.", Icon = "monitor", Opened = true })
        Visual:Toggle({ Flag = "FOVCustomE", Title = "FOV Customizado", Desc = "Altera o campo de visão da câmera pro valor definido abaixo.", Icon = "eye", Value = Cfg.CustomFOVEnabled == true, Callback = function(v) Cfg.CustomFOVEnabled = v; Vis:ToggleCustomFOV(v) end })
        Visual:Slider({ Flag = "FOVVal", Title = "Campo de Visão (FOV)", Desc = "Aumente para ver mais do cenário.", Step = 1, Value = { Min = 30, Max = 120, Default = Cfg.FOVValue or 90 }, Callback = function(v) Cfg.FOVValue = v; Vis:UpdateFOV(v) end })
    else
        WindowTab:Section({ Title = "⚠️ Visualização indisponível", Desc = "O módulo Visuals falhou ao carregar nessa sessão.", Icon = "alert-triangle" })
    end

    if Cam then
        local Orbital = WindowTab:Section({ Title = "Câmera Orbital", Desc = "Desprenda-se do personagem.", Icon = "video", Opened = false })
        Orbital:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Desc = "Controle uma câmera livre invisível.", Icon = "video", Value = Cfg.FreeCamEnabled == true, Callback = function(v) Cfg.FreeCamEnabled = v; Cam:Toggle(v) end })
        Orbital:Slider({ Flag = "FreeCamSpeed", Title = "Velocidade", Desc = "Rapidez de voo da câmera.", Step = 0.1, Value = { Min = 0.1, Max = 10, Default = Cfg.FreeCamSpeed or 1 }, Callback = function(v) Cfg.FreeCamSpeed = v; Cam.Settings.Speed = v end })
        Orbital:Slider({ Flag = "FreeCamSens", Title = "Sensibilidade", Desc = "Sensibilidade ao girar a visão.", Step = 0.1, Value = { Min = 0.1, Max = 3, Default = Cfg.FreeCamSensitivity or 0.5 }, Callback = function(v) Cfg.FreeCamSensitivity = v; Cam.Settings.Sensitivity = v end })
        Orbital:Paragraph({
            Title = "Controles",
            Desc = "• Arraste a tela ou mova o mouse para olhar.\n• W, A, S, D para mover.\n• E para subir, Q para descer.\n• Shift esquerdo para voar rápido.",
            Color = "White"
        })
    else
        WindowTab:Section({ Title = "⚠️ FreeCam indisponível", Desc = "O módulo FreeCam falhou ao carregar nessa sessão.", Icon = "alert-triangle" })
    end
end

return Tab
