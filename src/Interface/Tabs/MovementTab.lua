local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.PlayerMods
    Config.Movement = Config.Movement or {}
    local Cfg = Config.Movement

    WindowTab:Section({ Title = "Atributos", Desc = "Modifique a velocidade e o pulo do seu personagem.", Icon = "gauge" })
    WindowTab:Toggle({ Flag = "SpeedE", Title = "Ativar Super Velocidade", Desc = "Altera o WalkSpeed do seu boneco.", Icon = "gauge", Value = Cfg.SpeedEnabled == true, Callback = function(v) Cfg.SpeedEnabled = v; Mod:ToggleSpeed(v) end })
    WindowTab:Slider({ Flag = "SpeedV", Title = "Velocidade", Desc = "Ajusta a rapidez do movimento.", Step = 1, Value = { Min = 16, Max = 500, Default = Cfg.SpeedValue or 50 }, Callback = function(v) Cfg.SpeedValue = v; Mod.Settings.SpeedValue = v end })
    WindowTab:Toggle({ Flag = "JumpE", Title = "Ativar Super Pulo", Desc = "Altera o JumpPower.", Icon = "arrow-up", Value = Cfg.JumpEnabled == true, Callback = function(v) Cfg.JumpEnabled = v; Mod:ToggleJumpPower(v) end })
    WindowTab:Slider({ Flag = "JumpV", Title = "Força do Pulo", Desc = "Ajusta a altura alcançada.", Step = 1, Value = { Min = 50, Max = 500, Default = Cfg.JumpValue or 100 }, Callback = function(v) Cfg.JumpValue = v; Mod.Settings.JumpValue = v end })

    WindowTab:Section({ Title = "Física Espacial", Desc = "Modifique como você interage com o mapa.", Icon = "atom" })
    WindowTab:Toggle({ Flag = "NoclipE", Title = "Noclip (Atravessar Paredes)", Desc = "Remove a colisão física do corpo.", Icon = "move-3d", Value = Cfg.Noclip == true, Callback = function(v) Cfg.Noclip = v; Mod:ToggleNoclip(v) end })
    WindowTab:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito no Ar", Desc = "Permite pular várias vezes seguidas.", Icon = "infinity", Value = Cfg.InfJump == true, Callback = function(v) Cfg.InfJump = v; Mod:ToggleInfJump(v) end })

    WindowTab:Section({ Title = "Voo Livre", Desc = "Levite e ande pelo ar.", Icon = "plane" })
    WindowTab:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Desc = "Voo 3D (Consulte a aba Atalhos para controles).", Icon = "plane", Value = Cfg.Fly == true, Callback = function(v) Cfg.Fly = v; Mod:ToggleFly(v) end })
    WindowTab:Slider({ Flag = "FlyV", Title = "Velocidade de Voo", Desc = "Rapidez ao voar.", Step = 1, Value = { Min = 10, Max = 300, Default = Cfg.FlySpeed or 50 }, Callback = function(v) Cfg.FlySpeed = v; Mod.Settings.FlySpeed = v end })

    WindowTab:Section({ Title = "Segurança", Desc = "Evite mortes acidentais.", Icon = "shield-check" })
    WindowTab:Toggle({ Flag = "AntiVoidE", Title = "Anti-Void", Desc = "Teleporta você de volta caso caia do mapa.", Icon = "shield-alert", Value = Cfg.AntiVoid == true, Callback = function(v) Cfg.AntiVoid = v; Mod:ToggleAntiVoid(v) end })
end

return Tab
