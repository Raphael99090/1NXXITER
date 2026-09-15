local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.PlayerMods
    Config.Movement = Config.Movement or {}
    local Cfg = Config.Movement

    if not Mod then
        WindowTab:Section({ Title = "⚠️ Movimento indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

    local Atributos = WindowTab:Section({ Title = "Atributos", Desc = "Modifique a velocidade e o pulo do seu personagem.", Icon = "gauge", Opened = true })
    Atributos:Toggle({ Flag = "SpeedE", Title = "Ativar Super Velocidade", Desc = "Altera o WalkSpeed do seu boneco.", Icon = "gauge", Value = Cfg.SpeedEnabled == true, Callback = function(v) Cfg.SpeedEnabled = v; Mod:ToggleSpeed(v) end })
    Atributos:Slider({ Flag = "SpeedV", Title = "Velocidade", Desc = "Ajusta a rapidez do movimento.", Step = 1, Value = { Min = 16, Max = 500, Default = Cfg.SpeedValue or 50 }, Callback = function(v) Cfg.SpeedValue = v; Mod.Settings.SpeedValue = v end })
    Atributos:Toggle({ Flag = "JumpE", Title = "Ativar Super Pulo", Desc = "Altera o JumpPower.", Icon = "arrow-up", Value = Cfg.JumpEnabled == true, Callback = function(v) Cfg.JumpEnabled = v; Mod:ToggleJumpPower(v) end })
    Atributos:Slider({ Flag = "JumpV", Title = "Força do Pulo", Desc = "Ajusta a altura alcançada.", Step = 1, Value = { Min = 50, Max = 500, Default = Cfg.JumpValue or 100 }, Callback = function(v) Cfg.JumpValue = v; Mod.Settings.JumpValue = v end })

    local Fisica = WindowTab:Section({ Title = "Física Espacial", Desc = "Modifique como você interage com o mapa.", Icon = "atom", Opened = false })
    Fisica:Toggle({ Flag = "NoclipE", Title = "Noclip (Atravessar Paredes)", Desc = "Remove a colisão física do corpo.", Icon = "move-3d", Value = Cfg.Noclip == true, Callback = function(v) Cfg.Noclip = v; Mod:ToggleNoclip(v) end })
    Fisica:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito no Ar", Desc = "Permite pular várias vezes seguidas.", Icon = "infinity", Value = Cfg.InfJump == true, Callback = function(v) Cfg.InfJump = v; Mod:ToggleInfJump(v) end })

    local Voo = WindowTab:Section({ Title = "Voo Livre", Desc = "Levite e ande pelo ar.", Icon = "plane", Opened = false })
    Voo:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Desc = "Voo 3D.", Icon = "plane", Value = Cfg.Fly == true, Callback = function(v) Cfg.Fly = v; Mod:ToggleFly(v) end })
    Voo:Slider({ Flag = "FlyV", Title = "Velocidade de Voo", Desc = "Rapidez ao voar.", Step = 1, Value = { Min = 10, Max = 300, Default = Cfg.FlySpeed or 50 }, Callback = function(v) Cfg.FlySpeed = v; Mod.Settings.FlySpeed = v end })
    Voo:Paragraph({
        Title = "Controles",
        Desc = "• W, A, S, D ou Joystick para mover.\n• Espaço para subir.\n• Ctrl (Control) para descer.\n• Botão de Pulo (Mobile) dá um empurrão para cima.",
        Color = "White"
    })

    local Seguranca = WindowTab:Section({ Title = "Segurança", Desc = "Evite mortes acidentais.", Icon = "shield-check", Opened = false })
    Seguranca:Toggle({ Flag = "AntiVoidE", Title = "Anti-Void", Desc = "Teleporta você de volta caso caia do mapa.", Icon = "shield-alert", Value = Cfg.AntiVoid == true, Callback = function(v) Cfg.AntiVoid = v; Mod:ToggleAntiVoid(v) end })
end

return Tab
