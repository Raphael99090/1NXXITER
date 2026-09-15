local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Players = game:GetService("Players")
    local Stats = game:GetService("Stats")

    local startTime = State.LoadedAtTick or os.clock()

    WindowTab:Section({ Title = "Bem-vindo ao 1NXITER HUB", Desc = "Estatísticas em tempo real da sua sessão.", Icon = "activity", Opened = true })

    -- Reduzido pras 3 informações que realmente importam de relance
    -- (FPS, Ping, Jogadores) + status das funções principais — o resto
    -- (usuário, memória) era mais "painel administrativo" do que útil.
    local Sessao = WindowTab:Section({ Title = "FPS | Ping | Jogadores", Desc = "Carregando...", Opened = true })
    local StatusFuncoes = WindowTab:Section({ Title = "Status", Desc = "Carregando...", Opened = true })

    local function formatTime(seconds)
        local h = math.floor(seconds / 3600)
        local m = math.floor((seconds % 3600) / 60)
        local s = math.floor(seconds % 60)
        if h > 0 then return string.format("%02d:%02d:%02d", h, m, s) end
        return string.format("%02d:%02d", m, s)
    end

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            local ping, fps = "N/A", "N/A"
            pcall(function() ping = string.format("%.0f ms", Stats.Network.ServerStatsItem["Data Ping"]:GetValue()) end)
            pcall(function() fps = string.format("%.0f FPS", workspace:GetRealPhysicsFPS()) end)

            local playerCount = #Players:GetPlayers()
            local maxPlayers = Players.MaxPlayers

            Sessao:SetDesc(string.format("%s  |  %s  |  %d/%d jogadores", fps, ping, playerCount, maxPlayers))

            local elapsedTime = os.clock() - startTime
            local aim, esp = Hub.Features.Aimbot, Hub.Features.ESP
            local aimbotStatus = aim and (aim.Settings.Enabled and "Ativo 🟢" or "Inativo 🔴") or "Indisponível ⚠️"
            local espStatus = esp and (esp.Settings.Enabled and "Ativo 🟢" or "Inativo 🔴") or "Indisponível ⚠️"

            StatusFuncoes:SetDesc(string.format("Tempo de Uso: %s\nAimbot: %s  |  ESP: %s", formatTime(elapsedTime), aimbotStatus, espStatus))

            task.wait(1)
        end
    end)
end

return Tab
