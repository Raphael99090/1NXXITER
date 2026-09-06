local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    local Spy = Hub.Features.SpyChat

    WindowTab:Section({ Title = "Visual de Tela" })
    WindowTab:Toggle({ Flag = "StretchE", Title = "Tela Esticada", Value = false, Callback = function(v) Vis:ToggleStretched(v) end })
    WindowTab:Slider({
        Flag = "FOVVal", Title = "Zoom", Step = 1,
        Value = { Min = 30, Max = 120, Default = 70 },
        Callback = function(v) Vis:UpdateFOV(v) end
    })

    WindowTab:Section({ Title = "Câmera Livre" })
    WindowTab:Toggle({ Flag = "FreeE", Title = "Ativar FreeCam", Value = false, Callback = function(v) Cam:Toggle(v) end })

    WindowTab:Section({ Title = "Espionagem" })
    WindowTab:Toggle({ Flag = "SpyE", Title = "Logs Spy Chat", Value = false, Callback = function(v) Spy:Toggle(v) end })
end

return Tab
