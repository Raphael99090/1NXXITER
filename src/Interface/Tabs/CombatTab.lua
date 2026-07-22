local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Aim = Hub.Features.Aimbot
    
    WindowTab:AddSection("Aimbot Master")
    
    WindowTab:AddToggle("AimE", { Title = "Ativar Auto-Mira", Default = false, Callback = function(v) Aim.Settings.Enabled = v end })
    WindowTab:AddToggle("AimW", { Title = "Wall Check", Default = true, Callback = function(v) Aim.Settings.WallCheck = v end })
    WindowTab:AddSlider("AimS", { Title = "Suavidade", Min = 0.1, Max = 1, Default = 0.5, Rounding = 1, Callback = function(v) Aim.Settings.Smoothness = v end })
    WindowTab:AddSlider("AimF", { Title = "Raio do FOV", Min = 30, Max = 800, Default = 150, Rounding = 0, Callback = function(v) Aim.Settings.FOVRadius = v end })
    
    WindowTab:AddSection("Hitbox Expander")
    WindowTab:AddToggle("HitE", { Title = "Aumentar Hitbox", Default = false, Callback = function(v) Aim.Settings.HitboxExpander = v end })
    WindowTab:AddSlider("HitS", { Title = "Tamanho da Hitbox", Min = 2, Max = 50, Default = 10, Rounding = 0, Callback = function(v) Aim.Settings.HitboxSize = v end })
end

return Tab
