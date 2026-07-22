local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Vis = Hub.Features.Visuals
    local Cam = Hub.Features.FreeCam
    local Spy = Hub.Features.SpyChat

    WindowTab:AddSection("Visual de Tela")
    WindowTab:AddToggle("StretchE", { Title = "Tela Esticada", Default = false, Callback = function(v) Vis:ToggleStretched(v) end })
    WindowTab:AddSlider("FOVVal", { Title = "Zoom", Min = 30, Max = 120, Default = 70, Rounding = 0, Callback = function(v) Vis:UpdateFOV(v) end })

    WindowTab:AddSection("Câmera Livre")
    WindowTab:AddToggle("FreeE", { Title = "Ativar FreeCam", Default = false, Callback = function(v) Cam:Toggle(v) end })
    
    WindowTab:AddSection("Espionagem")
    WindowTab:AddToggle("SpyE", { Title = "Logs Spy Chat", Default = false, Callback = function(v) Spy:Toggle(v) end })
end

return Tab
