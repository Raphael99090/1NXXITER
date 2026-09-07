local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Aim = Hub.Features.Aimbot

    WindowTab:Section({
        Title = "Aimbot Master",
        Desc = "Domine o combate com mira automática.",
        Icon = "crosshair"
    })

    local Status = WindowTab:Section({
        Title = "Status",
        Desc = "Aimbot desligado"
    })

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            if not Aim.Settings.Enabled then
                Status:SetDesc("Aimbot desligado")
            elseif Aim.Settings.SilentAim and Aim.IsAiming then
                Status:SetDesc("🔒 Alvo travado (Silent Aim — câmera livre)")
            elseif Aim.IsAiming then
                Status:SetDesc("🎯 Mirando em alvo")
            else
                Status:SetDesc("👀 Procurando alvo...")
            end

            task.wait(0.3)
        end
    end)

    WindowTab:Toggle({
        Flag = "AimE",
        Title = "Ativar Auto-Mira",
        Desc = "Ativa o funcionamento geral do Aimbot.",
        Icon = "crosshair",
        Value = false,
        Callback = function(v)
            Aim.Settings.Enabled = v
        end
    })

    WindowTab:Toggle({
        Flag = "AimSilent",
        Title = "Silent Aim (não gira a câmera)",
        Desc = "O tiro vai no alvo, mas sua câmera continua livre.",
        Icon = "target",
        Value = false,
        Callback = function(v)
            Aim.Settings.SilentAim = v
        end
    })

    WindowTab:Toggle({
        Flag = "AimKeyOnly",
        Title = "Só mirar segurando E",
        Desc = "Se ativo, o aimbot só trava quando você segura a tecla (E no PC, botão custom no Mobile).",
        Icon = "keyboard",
        Value = false,
        Callback = function(v)
            Aim.Settings.AimKeyOnly = v
        end
    })

    WindowTab:Dropdown({
        Flag = "AimPriority",
        Title = "Prioridade de Alvo",
        Desc = "Define quem o Aimbot deve focar primeiro.",
        Values = {
            "Mais perto da mira",
            "Menor vida"
        },
        Value = "Mais perto da mira",
        Callback = function(v)
            Aim.Settings.Priority =
                (v == "Menor vida") and "LowHealth" or "Closest"
        end
    })

    WindowTab:Toggle({
        Flag = "AimTeam",
        Title = "Ignorar Time",
        Desc = "Não mira em jogadores que estão no mesmo time que você.",
        Icon = "users",
        Value = false,
        Callback = function(v)
            Aim.Settings.TeamCheck = v
        end
    })

    WindowTab:Toggle({
        Flag = "AimW",
        Title = "Wall Check",
        Desc = "Ignora jogadores que estão atrás de paredes.",
        Icon = "scan-eye",
        Value = true,
        Callback = function(v)
            Aim.Settings.WallCheck = v
        end
    })

    WindowTab:Toggle({
        Flag = "AimFOVShow",
        Title = "Mostrar Círculo do FOV",
        Desc = "Desenha o raio de detecção na sua tela.",
        Icon = "circle-dot",
        Value = false,
        Callback = function(v)
            Aim.Settings.ShowFOV = v
        end
    })

    WindowTab:Slider({
        Flag = "AimS",
        Title = "Suavidade",
        Desc = "Velocidade que a câmera puxa para o alvo (menor = mais travado).",
        Step = 0.1,
        Value = {
            Min = 0.1,
            Max = 1,
            Default = 0.5
        },
        Callback = function(v)
            Aim.Settings.Smoothness = v
        end
    })

    WindowTab:Slider({
        Flag = "AimF",
        Title = "Raio do FOV",
        Desc = "Tamanho da área de busca de alvos na tela.",
        Step = 1,
        Value = {
            Min = 30,
            Max = 800,
            Default = 150
        },
        Callback = function(v)
            Aim.Settings.FOVRadius = v
        end
    })

    WindowTab:Section({
        Title = "Hitbox Expander",
        Desc = "Aumenta o tamanho dos inimigos para facilitar o acerto.",
        Icon = "scan"
    })

    WindowTab:Toggle({
        Flag = "HitE",
        Title = "Aumentar Hitbox",
        Desc = "Ativa a expansão da área de dano dos outros jogadores.",
        Icon = "expand",
        Value = false,
        Callback = function(v)
            Aim.Settings.HitboxExpander = v
        end
    })

    WindowTab:Slider({
        Flag = "HitS",
        Title = "Tamanho da Hitbox",
        Desc = "Define quão gigante o hitbox vai ficar.",
        Step = 1,
        Value = {
            Min = 2,
            Max = 50,
            Default = 10
        },
        Callback = function(v)
            Aim.Settings.HitboxSize = v
        end
    })
end

return Tab
