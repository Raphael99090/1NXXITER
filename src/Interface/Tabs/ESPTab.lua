local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.ESP
    
    WindowTab:AddSection("Visual Master")
    WindowTab:AddToggle("ESPE", { Title = "Ativar ESP", Default = false, Callback = function(v) Mod:Toggle(v) end })
    WindowTab:AddToggle("ESPT", { Title = "Ocultar Aliados", Default = false, Callback = function(v) Mod.Settings.TeamCheck = v end })

    WindowTab:AddSection("Estilos")
    WindowTab:AddToggle("AuraE", { Title = "Aura (Highlight)", Default = false, Callback = function(v) Mod.Settings.Aura = v end })
    WindowTab:AddToggle("BoxE", { Title = "Caixas (Box)", Default = false, Callback = function(v) Mod.Settings.Box = v end })
    WindowTab:AddToggle("SkeleE", { Title = "Esqueleto", Default = false, Callback = function(v) Mod.Settings.Skeleton = v end })
    WindowTab:AddToggle("HealthE", { Title = "Barra de Vida", Default = false, Callback = function(v) Mod.Settings.HealthBar = v end })
end

return Tab
