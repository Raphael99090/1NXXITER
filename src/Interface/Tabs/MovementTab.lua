local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.PlayerMods
    
    WindowTab:AddSection("Atributos")
    WindowTab:AddToggle("SpeedE", { Title = "Ativar Speed", Default = false, Callback = function(v) Mod:ToggleSpeed(v) end })
    WindowTab:AddSlider("SpeedV", { Title = "Velocidade", Min = 16, Max = 500, Default = 50, Rounding = 0, Callback = function(v) Mod.Settings.SpeedValue = v end })
    
    WindowTab:AddSection("Física")
    WindowTab:AddToggle("NoclipE", { Title = "Atravessar Paredes", Default = false, Callback = function(v) Mod:ToggleNoclip(v) end })
    WindowTab:AddToggle("InfJumpE", { Title = "Pulo Infinito", Default = false, Callback = function(v) Mod:ToggleInfJump(v) end })
end

return Tab
