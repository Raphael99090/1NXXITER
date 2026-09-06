local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.PlayerMods

    WindowTab:Section({ Title = "Atributos", Icon = "gauge" })
    WindowTab:Toggle({ Flag = "SpeedE", Title = "Ativar Speed", Icon = "gauge", Value = false, Callback = function(v) Mod:ToggleSpeed(v) end })
    WindowTab:Slider({
        Flag = "SpeedV", Title = "Velocidade", Step = 1,
        Value = { Min = 16, Max = 500, Default = 50 },
        Callback = function(v) Mod.Settings.SpeedValue = v end
    })

    -- JumpEnabled/JumpValue já existiam no PlayerMods mas não tinham
    -- nenhum controle na UI — impossível de ligar sem editar o código.
    WindowTab:Toggle({ Flag = "JumpE", Title = "Ativar Jump Power", Icon = "arrow-up", Value = false, Callback = function(v) Mod:ToggleJumpPower(v) end })
    WindowTab:Slider({
        Flag = "JumpV", Title = "Força do Pulo", Step = 1,
        Value = { Min = 50, Max = 500, Default = 100 },
        Callback = function(v) Mod.Settings.JumpValue = v end
    })

    WindowTab:Section({ Title = "Física", Icon = "atom" })
    WindowTab:Toggle({ Flag = "NoclipE", Title = "Atravessar Paredes", Icon = "move-3d", Value = false, Callback = function(v) Mod:ToggleNoclip(v) end })
    WindowTab:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito", Icon = "infinity", Value = false, Callback = function(v) Mod:ToggleInfJump(v) end })

    WindowTab:Section({ Title = "Voo", Icon = "plane" })
    WindowTab:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Icon = "plane", Value = false, Callback = function(v) Mod:ToggleFly(v) end })
    WindowTab:Slider({
        Flag = "FlyV", Title = "Velocidade do Fly", Step = 1,
        Value = { Min = 10, Max = 300, Default = 50 },
        Callback = function(v) Mod.Settings.FlySpeed = v end
    })
    WindowTab:Section({
        Title = "Controles do Fly",
        Icon = "gamepad-2",
        Desc = "Anda com WASD/joystick. Espaço = subir, Ctrl = descer (teclado). No touch sem teclado, o botão de pulo dá um empurrão pra cima."
    })

    WindowTab:Section({ Title = "Segurança", Icon = "shield-check" })
    WindowTab:Toggle({
        Flag = "AntiVoidE",
        Title = "Anti-Queda (void)", Icon = "shield-alert",
        Value = false,
        Callback = function(v) Mod:ToggleAntiVoid(v) end
    })
end

return Tab
