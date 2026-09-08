local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Aim = Hub.Features.Aimbot

    local Status = WindowTab:Section({ Title = "Status da Mira", Desc = "Aimbot desligado" })

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            if not Aim.Settings.Enabled then
                Status:SetDesc("Aimbot desligado")
            elseif Aim.Settings.SilentAim and Aim.IsAiming then
                Status:SetDesc("🔒 Alvo travado (Silent Aim)")
            elseif Aim.IsAiming then
                Status:SetDesc("🎯 Mirando em alvo")
            else
                Status:SetDesc("👀 Procurando alvo...")
            end
            task.wait(0.3)
        end
    end)

    WindowTab:Section({ Title = "Controles Principais", Desc = "Ative e configure o comportamento básico da mira.", Icon = "crosshair" })

    WindowTab:Toggle({ Flag = "AimE", Title = "Ativar Auto-Mira", Desc = "Liga o Aimbot (usa FOV para buscar alvos).", Icon = "crosshair", Value = false, Callback = function(v) Aim.Settings.Enabled = v end })
    WindowTab:Toggle({ Flag = "AimSilent", Title = "Silent Aim (Câmera Livre)", Desc = "Acerta o alvo sem girar sua câmera.", Icon = "target", Value = false, Callback = function(v) Aim.Settings.SilentAim = v end })
    WindowTab:Toggle({ Flag = "AimKeyOnly", Title = "Ativar por Tecla", Desc = "Só trava a mira segurando a tecla definida na aba Atalhos.", Icon = "keyboard", Value = false, Callback = function(v) Aim.Settings.AimKeyOnly = v end })

    WindowTab:Section({ Title = "Configurações Visuais e Dinâmica", Desc = "Ajuste suavidade e área de detecção.", Icon = "settings" })

    WindowTab:Toggle({ Flag = "AimW", Title = "Wall Check", Desc = "Ignora inimigos atrás de paredes.", Icon = "scan-eye", Value = true, Callback = function(v) Aim.Settings.WallCheck = v end })
    WindowTab:Toggle({ Flag = "AimFOVShow", Title = "Mostrar FOV", Desc = "Desenha o círculo de busca de alvos na tela.", Icon = "circle-dot", Value = false, Callback = function(v) Aim.Settings.ShowFOV = v end })
    WindowTab:Slider({ Flag = "AimF", Title = "Raio do FOV", Desc = "Tamanho da área de busca de alvos.", Step = 1, Value = { Min = 30, Max = 800, Default = 150 }, Callback = function(v) Aim.Settings.FOVRadius = v end })
    WindowTab:Slider({ Flag = "AimS", Title = "Suavidade (Smoothness)", Desc = "Velocidade que a câmera puxa (menor = mais firme).", Step = 0.1, Value = { Min = 0.1, Max = 1, Default = 0.5 }, Callback = function(v) Aim.Settings.Smoothness = v end })

    WindowTab:Section({ Title = "Filtros de Alvo", Desc = "Defina quem o Aimbot deve ignorar ou focar.", Icon = "users" })

    WindowTab:Dropdown({ Flag = "AimPriority", Title = "Prioridade de Alvo", Desc = "Escolha quem focar primeiro no FOV.", Values = { "Mais perto da mira", "Menor vida" }, Value = "Mais perto da mira", Callback = function(v) Aim.Settings.Priority = (v == "Menor vida") and "LowHealth" or "Closest" end })
    WindowTab:Toggle({ Flag = "AimTeam", Title = "Ignorar Próprio Time", Desc = "Não mira nos aliados.", Icon = "users", Value = false, Callback = function(v) Aim.Settings.TeamCheck = v end })

    local TeamsList = {}; pcall(function() for _, t in pairs(game:GetService("Teams"):GetChildren()) do table.insert(TeamsList, t.Name) end end)
    local TeamDropdown = WindowTab:Dropdown({ Flag = "AimIgnoredTeams", Title = "Ignorar Times Específicos", Desc = "Times imunes ao seu Aimbot.", Values = TeamsList, Multi = true, Callback = function(v) Aim.Settings.IgnoredTeams = v end })

    local PlayersList = {}; pcall(function() for _, p in pairs(game:GetService("Players"):GetPlayers()) do if p ~= game:GetService("Players").LocalPlayer then table.insert(PlayersList, p.Name) end end end)
    local PlayerDropdown = WindowTab:Dropdown({ Flag = "AimTargetPlayers", Title = "Whitelist de Jogadores", Desc = "Mirar APENAS nestes jogadores.", Values = PlayersList, Multi = true, Callback = function(v) Aim.Settings.TargetPlayers = v end })

    WindowTab:Button({ Title = "Atualizar Listas", Icon = "refresh-cw", Callback = function()
        local newTeams = {}; pcall(function() for _, t in pairs(game:GetService("Teams"):GetChildren()) do table.insert(newTeams, t.Name) end end)
        TeamDropdown:Refresh(newTeams)
        local newPlayers = {}; pcall(function() for _, p in pairs(game:GetService("Players"):GetPlayers()) do if p ~= game:GetService("Players").LocalPlayer then table.insert(newPlayers, p.Name) end end end)
        PlayerDropdown:Refresh(newPlayers)
    end})

    WindowTab:Section({ Title = "Hitbox Expander", Desc = "Aumenta o volume físico dos inimigos.", Icon = "scan" })
    WindowTab:Toggle({ Flag = "HitE", Title = "Aumentar Hitbox", Desc = "Amplia a área de dano dos outros jogadores.", Icon = "expand", Value = false, Callback = function(v) Aim.Settings.HitboxExpander = v end })
    WindowTab:Slider({ Flag = "HitS", Title = "Tamanho da Hitbox", Desc = "Volume da área aumentada.", Step = 1, Value = { Min = 2, Max = 50, Default = 10 }, Callback = function(v) Aim.Settings.HitboxSize = v end })
end

return Tab
