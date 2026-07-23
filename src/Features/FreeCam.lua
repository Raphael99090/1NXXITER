local FreeCam = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

FreeCam.Settings = { Enabled = false, Speed = 1, Sensitivity = 0.5 }
local Conn = nil
local LookConn = nil
local Rot = Vector2.new(0, 0)

-- GetMouseDelta só existe com mouse. Em touch (celular), a rotação da
-- câmera passa a vir do arrasto na tela — sem isso, FreeCam só funcionava no PC.
local touchDelta = Vector2.new(0, 0)
local lastTouchPos = nil

function FreeCam:Toggle(state)
    self.Settings.Enabled = state
    local Camera = workspace.CurrentCamera
    if not Camera then return end

    if state then
        Camera.CameraType = Enum.CameraType.Scriptable
        Rot = Vector2.new(0, 0)
        touchDelta = Vector2.new(0, 0)
        lastTouchPos = nil

        LookConn = UserInputService.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.Touch then
                if lastTouchPos then
                    touchDelta = Vector2.new(input.Position.X, input.Position.Y) - lastTouchPos
                end
                lastTouchPos = Vector2.new(input.Position.X, input.Position.Y)
            end
        end)

        UserInputService.TouchEnded:Connect(function()
            lastTouchPos = nil
        end)

        Conn = RunService.RenderStepped:Connect(function(dt)
            local cam = workspace.CurrentCamera -- busca de novo, nunca cacheado
            if not cam then return end

            local delta = UserInputService:GetMouseDelta()
            if delta.Magnitude == 0 then
                delta = touchDelta
                touchDelta = Vector2.new(0, 0) -- consome o delta do touch pra não repetir
            end

            Rot = Rot + (delta * -0.005 * self.Settings.Sensitivity)
            cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(0, Rot.X, 0) * CFrame.Angles(Rot.Y, 0, 0)

            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
            
            local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1
            if move.Magnitude > 0 then
                cam.CFrame = cam.CFrame + cam.CFrame:VectorToWorldSpace(move.Unit * self.Settings.Speed * mult)
            end
        end)
    else
        if Conn then Conn:Disconnect() Conn = nil end
        if LookConn then LookConn:Disconnect() LookConn = nil end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

function FreeCam:Unload()
    self:Toggle(false)
end

return FreeCam
