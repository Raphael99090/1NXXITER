local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")
    
    local startTime = tick()
    if State.LoadedAtTick then startTime = State.LoadedAtTick else State.LoadedAtTick = startTime end

    WindowTab:Section({ Title = "Bem-vindo ao 1NXITER HUB", Desc = "Estatísticas em tempo real da sua sessão e do servidor.", Icon = "activity" })

    local PlayerStats = WindowTab:Section({ Title = "Informações do Jogador", Desc = "Carregando..." })
    local ServerStats = WindowTab:Section({ Title = "Informações do Servidor", Desc = "Carregando..." })
    local HubStats = WindowTab:Section({ Title = "Status da Sessão", Desc = "Carregando..." })

    local function formatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
        return string.format("%02d:%02d", m, s)
    end

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            local localPlayer = Players.LocalPlayer
            local displayName = localPlayer and localPlayer.DisplayName or "Desconhecido"
            local name = localPlayer and localPlayer.Name or "Desconhecido"
            PlayerStats:SetDesc(string.format("Usuário: %s (@%s)\nIniciado às: %s", displayName, name, State.LoadedAt or "N/A"))

            local ping, fps, memory = "N/A", "N/A", "N/A"
            pcall(function() ping = string.format("%.0f ms", Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pcall(function() fps = string.format("%.0f FPS", workspace:GetRealPhysicsFPS()) end)
            pcall(function() memory = string.format("%.0f MB", Stats:GetTotalMemoryUsageMb()) end)

            local playerCount = #Players:GetPlayers()
            local maxPlayers = Players.MaxPlayers
            
            ServerStats:SetDesc(string.format("Ping: %s  |  Desempenho: %s\nUso de Memória: %s\nJogadores no Mapa: %d/%d", ping, fps, memory, playerCount, maxPlayers))

            local elapsedTime = tick() - startTime
            local aimbotStatus = Hub.Features.Aimbot.Settings.Enabled and "Ativo 🟢" or "Inativo 🔴"
            local espStatus = Hub.Features.ESP.Settings.Enabled and "Ativo 🟢" or "Inativo 🔴"
            
            HubStats:SetDesc(string.format("Tempo de Uso: %s\nStatus Aimbot: %s  |  Status Chams: %s", formatTime(elapsedTime), aimbotStatus, espStatus))

            task.wait(1)
        end
    end)
end

return Tab
