local AutoTrain = {}
local Players = game:GetService("Players")
local Player = Players.LocalPlayer

function AutoTrain:Toggle(Config, State, Hub, updateUI)
    if State.IsRunning then 
        State.IsRunning = false 
        if updateUI then updateUI("STATUS: PAUSADO") end
        return 
    end

    State.IsRunning = true
    task.spawn(function()
        local step = Config.IsCountdown and -1 or 1
        local finish = Config.IsCountdown and (Config.StartNum - Config.Quantity) or (Config.StartNum + Config.Quantity)

        for i = Config.StartNum, finish, step do
            if not State.IsRunning or not State.IsActive then break end
            
            if updateUI then updateUI("Contagem: " .. tostring(i)) end
            
            -- Envia ao Chat (Utils)
            local msg = (Hub.Core.Utils and Hub.Core.Utils:NumberToText(i)) or tostring(i)
            local ok, err = pcall(function()
                game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(msg .. " !", "All")
            end)
            if not ok then
                warn("⚠️ [1NXITER] AutoTrain: falha ao enviar chat -> " .. tostring(err))
            end
            
            -- Física
            if Player.Character and Player.Character:FindFirstChild("Humanoid") then
                Player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
            end
            
            task.wait(Config.Delay or 1.4)
        end
        State.IsRunning = false
    end)
end

return AutoTrain
