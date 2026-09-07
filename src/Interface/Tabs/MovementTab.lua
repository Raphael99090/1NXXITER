local Tab = {}

function Tab:Render(WindowTab, Hub, Config)
    local Mod = Hub.Features.PlayerMods

    WindowTab:Section({ Title = "Atributos", Desc = "Modifique as características físicas do seu personagem.", Icon = "gauge" })
    WindowTab:Toggle({ Flag = "SpeedE", Title = "Ativar Speed", Desc = "Permite correr mais rápido que o normal.", Icon = "gauge", Value = false, Callback = function(v) Mod:ToggleSpeed(v) end })
    WindowTab:Slider({
        Flag = "SpeedV", Title = "Velocidade", Desc = "O quão rápido o seu personagem vai correr.", Step = 1,
        Value = { Min = 16, Max = 500, Default = 50 },
        Callback = function(v) Mod.Settings.SpeedValue = v end
    })

    -- JumpEnabled/JumpValue já existiam no PlayerMods mas não tinham
    -- nenhum controle na UI — impossível de ligar sem editar o código.
    WindowTab:Toggle({ Flag = "JumpE", Title = "Ativar Jump Power", Desc = "Permite pular mais alto que o normal.", Icon = "arrow-up", Value = false, Callback = function(v) Mod:ToggleJumpPower(v) end })
    WindowTab:Slider({
        Flag = "JumpV", Title = "Força do Pulo", Desc = "A altura que seu personagem alcança ao pular.", Step = 1,
        Value = { Min = 50, Max = 500, Default = 100 },
        Callback = function(v) Mod.Settings.JumpValue = v end
    })

    WindowTab:Section({ Title = "Física", Desc = "Mude como seu personagem interage com o mundo.", Icon = "atom" })
    WindowTab:Toggle({ Flag = "NoclipE", Title = "Atravessar Paredes", Desc = "Seu corpo perde a colisão física (Noclip).", Icon = "move-3d", Value = false, Callback = function(v) Mod:ToggleNoclip(v) end })
    WindowTab:Toggle({ Flag = "InfJumpE", Title = "Pulo Infinito", Desc = "Permite pular no ar infinitamente.", Icon = "infinity", Value = false, Callback = function(v) Mod:ToggleInfJump(v) end })

    WindowTab:Section({ Title = "Voo", Desc = "Conquiste os céus com o modo de voo livre.", Icon = "plane" })
    WindowTab:Toggle({ Flag = "FlyE", Title = "Ativar Fly", Desc = "Levanta seu personagem do chão para voar.", Icon = "plane", Value = false, Callback = function(v) Mod:ToggleFly(v) end })
    WindowTab:Slider({
        Flag = "FlyV", Title = "Velocidade do Fly", Desc = "O quão rápido você voa pelo mapa.", Step = 1,
        Value = { Min = 10, Max = 300, Default = 50 },
        Callback = function(v) Mod.Settings.FlySpeed = v end
    })
    WindowTab:Section({
        Title = "Controles do Fly",
        Icon = "gamepad-2",
        Desc = "Anda com WASD/joystick. Espaço = subir, Ctrl = descer (teclado). No touch sem teclado, o botão de pulo dá um empurrão pra cima."
    })

    WindowTab:Section({ Title = "Segurança", Desc = "Sistemas de proteção passivos.", Icon = "shield-check" })
    WindowTab:Toggle({
        Flag = "AntiVoidE",
        Title = "Anti-Queda (void)",
        Desc = "Te teleporta de volta se você cair pra fora do mapa.",
        Icon = "shield-alert",
        Value = false,
        Callback = function(v) Mod:ToggleAntiVoid(v) end
    })
end

return Tab
