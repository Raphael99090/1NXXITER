local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    local Spy = Hub.Features.SpyChat

    WindowTab:Section({ Title = "Visual de Tela", Desc = "Altere o ângulo de visão e estilo visual do jogo.", Icon = "monitor" })
    WindowTab:Toggle({ Flag = "StretchE", Title = "Tela Esticada", Desc = "Estica a imagem (útil para ganhar FPS e acertar hitboxes maiores).", Icon = "maximize-2", Value = false, Callback = function(v) Vis:ToggleStretched(v) end })
    WindowTab:Slider({
        Flag = "FOVVal", Title = "Zoom (Campo de Visão)", Desc = "Aumenta ou diminui o campo de visão (FOV).", Step = 1,
        Value = { Min = 30, Max = 120, Default = 70 },
        Callback = function(v) Vis:UpdateFOV(v) end
    })

    WindowTab:Section({ Title = "Câmera Livre", Desc = "Desprenda a câmera do seu corpo e voe pelo mapa.", Icon = "video" })
    WindowTab:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Desc = "Movimente sua câmera pelo mundo inteiro livremente.", Icon = "video", Value = false, Callback = function(v) Cam:Toggle(v) end })
    WindowTab:Slider({
        Flag = "FreeCamSpeed", Title = "Velocidade da Câmera", Desc = "Velocidade de movimento da câmera livre.", Step = 0.1,
        Value = { Min = 0.1, Max = 10, Default = 1 },
        Callback = function(v) Cam.Settings.Speed = v end
    })
    WindowTab:Slider({
        Flag = "FreeCamSens", Title = "Sensibilidade", Desc = "Velocidade de rotação (movimento do mouse ou dedo).", Step = 0.1,
        Value = { Min = 0.1, Max = 3, Default = 0.5 },
        Callback = function(v) Cam.Settings.Sensitivity = v end
    })

    WindowTab:Section({ Title = "Espionagem", Desc = "Funcionalidades de coleta de informações.", Icon = "message-square" })
    WindowTab:Toggle({ Flag = "SpyE", Title = "Logs Spy Chat", Desc = "Lê mensagens de chat privadas de outros jogadores ou do sistema.", Icon = "message-square-more", Value = false, Callback = function(v) Spy:Toggle(v) end })
end

return Tab
