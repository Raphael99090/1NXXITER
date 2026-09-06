local AutoTrain = {}
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Player = Players.LocalPlayer

-- Detecta qual sistema de chat o jogo usa (mesmo método do SpyChat).
-- TextChatService é o novo padrão — jogos que migraram não têm mais
-- DefaultChatSystemChatEvents no ReplicatedStorage, então o FireServer
-- antigo simplesmente não faz nada (sem erro, mas sem mensagem).
local usingTextChatService = false
pcall(function()
    usingTextChatService = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
end)

-- Tenta enviar pelo sistema certo, com fallback pro outro.
local function SendChat(message)
    if usingTextChatService then
        local ok = pcall(function()
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(message)
            end
        end)
        if ok then return true end
    end

    -- Legacy chat (jogos que ainda usam o sistema antigo)
    local ok = pcall(function()
        game:GetService("ReplicatedStorage")
            .DefaultChatSystemChatEvents
            .SayMessageRequest:FireServer(message, "All")
    end)
    return ok
end

function AutoTrain:Toggle(Config, State, Hub, updateUI)
    -- Guarda a referência do State: sem isso, Unload() não tinha como
    -- parar o loop que já estava rodando em segundo plano (task.spawn).
    self._state = State

    if State.IsRunning then 
        State.IsRunning = false 
        if updateUI then updateUI("STATUS: PAUSADO") end
        return 
    end

    State.IsRunning = true
    task.spawn(function()
        local ok, err = pcall(function()
            local step = Config.IsCountdown and -1 or 1
            local finish = Config.IsCountdown 
                and (Config.StartNum - Config.Quantity) 
                or  (Config.StartNum + Config.Quantity)

            for i = Config.StartNum, finish, step do
                if not State.IsRunning or not State.IsActive then break end
                
                local mode = Config.Mode or "Canguru"
                if updateUI then updateUI(mode .. " — Contagem: " .. tostring(i)) end
                
                -- Converte número pra texto PT-BR (Utils)
                local msg = (Hub.Core.Utils and Hub.Core.Utils:NumberToText(i)) or tostring(i)
                
                -- Envia no chat (suporta TextChatService + legacy)
                local sent = SendChat(msg .. " !")
                if not sent then
                    warn("⚠️ [1NXITER] AutoTrain: falha ao enviar no chat — verifique se o chat está disponível")
                end
                
                -- Ação física conforme o modo de exercício
                if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                    local hum = Player.Character.Humanoid

                    if mode == "Canguru" then
                        -- Pulo + agachar (se AutoCrouch estiver ligado)
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    elseif mode == "Flexão" then
                        -- Simula flexão: agacha e levanta
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    elseif mode == "Polichinelo" then
                        -- Simula polichinelo: pulo
                        hum:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
                
                task.wait(Config.Delay or 1.4)
            end
        end)

        if not ok then
            warn("❌ [1NXITER] AutoTrain: erro na rotina -> " .. tostring(err))
            if updateUI then updateUI("STATUS: ERRO (veja o console F9)") end
        else
            if updateUI then updateUI("STATUS: CONCLUÍDO ✅") end
        end

        State.IsRunning = false
    end)
end

-- Antes o AutoTrain não tinha Unload nenhum: Hub:Unload() só chama Unload()
-- nas features que o definem, então um treino em andamento sobrevivia ao
-- "FECHAR HUB" e continuava mandando mensagem no chat pra sempre, sem UI
-- pra pausar. IsActive no State também nunca era setado false em lugar
-- nenhum, então aquele check já existente no loop nunca disparava de verdade.
function AutoTrain:Unload()
    if self._state then
        self._state.IsRunning = false
        self._state.IsActive = false
    end
end

return AutoTrain
