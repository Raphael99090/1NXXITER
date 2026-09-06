local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    local Spy = Hub.Features.SpyChat

    WindowTab:Section({ Title = "Visual de Tela", Icon = "monitor" })
    WindowTab:Toggle({ Flag = "StretchE", Title = "Tela Esticada", Icon = "maximize-2", Value = false, Callback = function(v) Vis:ToggleStretched(v) end })
    WindowTab:Slider({
        Flag = "FOVVal", Title = "Zoom", Step = 1,
        Value = { Min = 30, Max = 120, Default = 70 },
        Callback = function(v) Vis:UpdateFOV(v) end
    })

    WindowTab:Section({ Title = "Câmera Livre", Icon = "video" })
    WindowTab:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Icon = "video", Value = false, Callback = function(v) Cam:Toggle(v) end })

    WindowTab:Section({ Title = "Espionagem", Icon = "message-square" })
    WindowTab:Toggle({ Flag = "SpyE", Title = "Logs Spy Chat", Icon = "message-square-more", Value = false, Callback = function(v) Spy:Toggle(v) end })
end

return Tab
