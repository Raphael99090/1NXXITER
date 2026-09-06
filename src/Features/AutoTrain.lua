local AutoTrain = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

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
            local finish = Config.IsCountdown and (Config.StartNum - Config.Quantity) or (Config.StartNum + Config.Quantity)

            for i = Config.StartNum, finish, step do
                if not State.IsRunning or not State.IsActive then break end
                
                if updateUI then updateUI("Contagem: " .. tostring(i)) end
                
                -- Envia ao Chat (Utils)
                local msg = (Hub.Core.Utils and Hub.Core.Utils:NumberToText(i)) or tostring(i)
                local sendOk, sendErr = pcall(function()
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg .. " !", "All")
                end)
                if not sendOk then
                    warn("⚠️ [1NXITER] AutoTrain: falha ao enviar chat -> " .. tostring(sendErr))
                end
                
                -- Física
                if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                    Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
                
                task.wait(Config.Delay or 1.4)
            end
        end)

        if not ok then
            warn("❌ [1NXITER] AutoTrain: erro na rotina -> " .. tostring(err))
            if updateUI then updateUI("STATUS: ERRO (veja o console)") end
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
