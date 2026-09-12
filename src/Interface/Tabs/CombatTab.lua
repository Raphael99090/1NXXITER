local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Aim = Hub.Features.Aimbot
    Config.Aimbot = Config.Aimbot or {}
    local Cfg = Config.Aimbot

    if not Aim then
        WindowTab:Section({ Title = "⚠️ Aimbot indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

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

    WindowTab:Toggle({ Flag = "AimE", Title = "Ativar Auto-Mira", Desc = "Liga o Aimbot (usa FOV para buscar alvos).", Icon = "crosshair", Value = Cfg.Enabled == true, Callback = function(v) Cfg.Enabled = v; Aim.Settings.Enabled = v end })
    WindowTab:Toggle({ Flag = "AimSilent", Title = "Silent Aim (Câmera Livre)", Desc = "Acerta o alvo sem girar sua câmera.", Icon = "target", Value = Cfg.SilentAim == true, Callback = function(v) Cfg.SilentAim = v; Aim.Settings.SilentAim = v end })
    WindowTab:Toggle({ Flag = "AimKeyOnly", Title = "Ativar por Tecla", Desc = "Só trava a mira segurando a tecla definida na aba Atalhos.", Icon = "keyboard", Value = Cfg.AimKeyOnly == true, Callback = function(v) Cfg.AimKeyOnly = v; Aim.Settings.AimKeyOnly = v end })

    WindowTab:Section({ Title = "Configurações Visuais e Dinâmica", Desc = "Ajuste suavidade e área de detecção.", Icon = "settings" })

    WindowTab:Toggle({ Flag = "AimW", Title = "Wall Check", Desc = "Ignora inimigos atrás de paredes.", Icon = "scan-eye", Value = Cfg.WallCheck ~= false, Callback = function(v) Cfg.WallCheck = v; Aim.Settings.WallCheck = v end })
    WindowTab:Toggle({ Flag = "AimFOVShow", Title = "Mostrar FOV", Desc = "Desenha o círculo de busca de alvos na tela.", Icon = "circle-dot", Value = Cfg.ShowFOV == true, Callback = function(v) Cfg.ShowFOV = v; Aim.Settings.ShowFOV = v end })
    WindowTab:Slider({ Flag = "AimF", Title = "Raio do FOV", Desc = "Tamanho da área de busca de alvos.", Step = 1, Value = { Min = 30, Max = 800, Default = Cfg.FOVRadius or 150 }, Callback = function(v) Cfg.FOVRadius = v; Aim.Settings.FOVRadius = v end })
    WindowTab:Slider({ Flag = "AimS", Title = "Suavidade (Smoothness)", Desc = "Velocidade que a câmera puxa (menor = mais firme).", Step = 0.1, Value = { Min = 0.1, Max = 1, Default = Cfg.Smoothness or 0.5 }, Callback = function(v) Cfg.Smoothness = v; Aim.Settings.Smoothness = v end })
    WindowTab:Dropdown({ Flag = "AimTargetPart", Title = "Parte Alvo", Desc = "Onde a mira trava no personagem.", Values = { "HumanoidRootPart", "Head", "UpperTorso" }, Value = Cfg.TargetPart or "HumanoidRootPart", Callback = function(v) Cfg.TargetPart = v; Aim.Settings.TargetPart = v end })

    WindowTab:Section({ Title = "Filtros de Alvo", Desc = "Defina quem o Aimbot deve ignorar ou focar.", Icon = "users" })

    WindowTab:Dropdown({ Flag = "AimPriority", Title = "Prioridade de Alvo", Desc = "Escolha quem focar primeiro no FOV.", Values = { "Mais perto da mira", "Menor vida" }, Value = (Cfg.Priority == "LowHealth") and "Menor vida" or "Mais perto da mira", Callback = function(v) Cfg.Priority = (v == "Menor vida") and "LowHealth" or "Closest"; Aim.Settings.Priority = Cfg.Priority end })
    WindowTab:Toggle({ Flag = "AimTeam", Title = "Ignorar Próprio Time", Desc = "Não mira nos aliados.", Icon = "users", Value = Cfg.TeamCheck == true, Callback = function(v) Cfg.TeamCheck = v; Aim.Settings.TeamCheck = v end })

    local TeamsList = {}; pcall(function() for _, t in pairs(game:GetService("Teams"):GetChildren()) do table.insert(TeamsList, t.Name) end end)
    local TeamDropdown = WindowTab:Dropdown({ Flag = "AimIgnoredTeams", Title = "Ignorar Times Específicos", Desc = "Times imunes ao seu Aimbot.", Values = TeamsList, Multi = true, Value = Cfg.IgnoredTeams or {}, Callback = function(v) Cfg.IgnoredTeams = v; Aim.Settings.IgnoredTeams = v end })

    local PlayersList = {}; pcall(function() for _, p in pairs(game:GetService("Players"):GetPlayers()) do if p ~= game:GetService("Players").LocalPlayer then table.insert(PlayersList, p.Name) end end end)
    local PlayerDropdown = WindowTab:Dropdown({ Flag = "AimTargetPlayers", Title = "Whitelist de Jogadores", Desc = "Mirar APENAS nestes jogadores.", Values = PlayersList, Multi = true, Value = Cfg.TargetPlayers or {}, Callback = function(v) Cfg.TargetPlayers = v; Aim.Settings.TargetPlayers = v end })

    WindowTab:Button({ Title = "Atualizar Listas", Icon = "refresh-cw", Callback = function()
        local newTeams = {}; pcall(function() for _, t in pairs(game:GetService("Teams"):GetChildren()) do table.insert(newTeams, t.Name) end end)
        TeamDropdown:Refresh(newTeams)
        local newPlayers = {}; pcall(function() for _, p in pairs(game:GetService("Players"):GetPlayers()) do if p ~= game:GetService("Players").LocalPlayer then table.insert(newPlayers, p.Name) end end end)
        PlayerDropdown:Refresh(newPlayers)
    end})

    WindowTab:Section({ Title = "Hitbox Expander", Desc = "Aumenta o volume físico dos inimigos.", Icon = "scan" })
    WindowTab:Toggle({ Flag = "HitE", Title = "Aumentar Hitbox", Desc = "Amplia a área de dano dos outros jogadores.", Icon = "expand", Value = Cfg.HitboxExpander == true, Callback = function(v) Cfg.HitboxExpander = v; Aim.Settings.HitboxExpander = v end })
    WindowTab:Slider({ Flag = "HitS", Title = "Tamanho da Hitbox", Desc = "Volume da área aumentada.", Step = 1, Value = { Min = 2, Max = 50, Default = Cfg.HitboxSize or 10 }, Callback = function(v) Cfg.HitboxSize = v; Aim.Settings.HitboxSize = v end })
end

return Tab
