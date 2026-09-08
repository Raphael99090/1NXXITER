local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.PlayerMods

    WindowTab:Section({ Title = "Atributos", Desc = "Modifique a velocidade e o pulo do seu personagem.", Icon = "gauge" })
    WindowTab:Toggle({ Flag = "SpeedE", Title = "Ativar Super Velocidade", Desc = "Altera o WalkSpeed do seu boneco.", Icon = "gauge", Value = false, Callback = function(v) Mod:ToggleSpeed(v) end })
    WindowTab:Slider({ Flag = "SpeedV", Title = "Velocidade", Desc = "Ajusta a rapidez do movimento.", Step = 1, Value = { Min = 16, Max = 500, Default = 50 }, Callback = function(v) Mod.Settings.SpeedValue = v end })
    WindowTab:Toggle({ Flag = "JumpE", Title = "Ativar Super Pulo", Desc = "Altera o JumpPower.", Icon = "arrow-up", Value = false, Callback = function(v) Mod:ToggleJumpPower(v) end })
    WindowTab:Slider({ Flag = "JumpV", Title = "Força do Pulo", Desc = "Ajusta a altura alcançada.", Step = 1, Value = { Min = 50, Max = 500, Default = 100 }, Callback = function(v) Mod.Settings.JumpValue = v end })

    WindowTab:Section({ Title = "Física Espacial", Desc = "Modifique como você interage com o mapa.", Icon = "atom" })
    WindowTab:Toggle({ Flag = "NoclipE", Title = "Noclip (Atravessar Paredes)", Desc = "Remove a colisão física do corpo.", Icon = "move-3d", Value = false, Callback = function(v) Mod:ToggleNoclip(v) end })
    WindowTab:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito no Ar", Desc = "Permite pular várias vezes seguidas.", Icon = "infinity", Value = false, Callback = function(v) Mod:ToggleInfJump(v) end })

    WindowTab:Section({ Title = "Voo Livre", Desc = "Levite e ande pelo ar.", Icon = "plane" })
    WindowTab:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Desc = "Voo 3D (Consulte a aba Atalhos para controles).", Icon = "plane", Value = false, Callback = function(v) Mod:ToggleFly(v) end })
    WindowTab:Slider({ Flag = "FlyV", Title = "Velocidade de Voo", Desc = "Rapidez ao voar.", Step = 1, Value = { Min = 10, Max = 300, Default = 50 }, Callback = function(v) Mod.Settings.FlySpeed = v end })

    WindowTab:Section({ Title = "Segurança", Desc = "Evite mortes acidentais.", Icon = "shield-check" })
    WindowTab:Toggle({ Flag = "AntiVoidE", Title = "Anti-Void", Desc = "Teleporta você de volta caso caia do mapa.", Icon = "shield-alert", Value = false, Callback = function(v) Mod:ToggleAntiVoid(v) end })
end

return Tab
