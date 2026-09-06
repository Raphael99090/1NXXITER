local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.PlayerMods

    WindowTab:Section({ Title = "Atributos" })
    WindowTab:Toggle({ Flag = "SpeedE", Title = "Ativar Speed", Value = false, Callback = function(v) Mod:ToggleSpeed(v) end })
    WindowTab:Slider({
        Flag = "SpeedV", Title = "Velocidade", Step = 1,
        Value = { Min = 16, Max = 500, Default = 50 },
        Callback = function(v) Mod.Settings.SpeedValue = v end
    })

    -- JumpEnabled/JumpValue já existiam no PlayerMods mas não tinham
    -- nenhum controle na UI — impossível de ligar sem editar o código.
    WindowTab:Toggle({ Flag = "JumpE", Title = "Ativar Jump Power", Value = false, Callback = function(v) Mod:ToggleJumpPower(v) end })
    WindowTab:Slider({
        Flag = "JumpV", Title = "Força do Pulo", Step = 1,
        Value = { Min = 50, Max = 500, Default = 100 },
        Callback = function(v) Mod.Settings.JumpValue = v end
    })

    WindowTab:Section({ Title = "Física" })
    WindowTab:Toggle({ Flag = "NoclipE", Title = "Atravessar Paredes", Value = false, Callback = function(v) Mod:ToggleNoclip(v) end })
    WindowTab:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito", Value = false, Callback = function(v) Mod:ToggleInfJump(v) end })

    WindowTab:Section({ Title = "Voo" })
    WindowTab:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Value = false, Callback = function(v) Mod:ToggleFly(v) end })
    WindowTab:Slider({
        Flag = "FlyV", Title = "Velocidade do Fly", Step = 1,
        Value = { Min = 10, Max = 300, Default = 50 },
        Callback = function(v) Mod.Settings.FlySpeed = v end
    })
    WindowTab:Section({
        Title = "Controles do Fly",
        Desc = "Anda com WASD/joystick. Espaço = subir, Ctrl = descer (teclado). No touch sem teclado, o botão de pulo dá um empurrão pra cima."
    })

    WindowTab:Section({ Title = "Segurança" })
    WindowTab:Toggle({
        Flag = "AntiVoidE",
        Title = "Anti-Queda (void)",
        Value = false,
        Callback = function(v) Mod:ToggleAntiVoid(v) end
    })
end

return Tab
