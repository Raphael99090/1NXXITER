local FreeCam = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

FreeCam.Settings = { Enabled = false, Speed = 1, Sensitivity = 0.5 }
local Conn = nil
local Rot = Vector2.new(0, 0)

function FreeCam:Toggle(state)
    self.Settings.Enabled = state
    if state then
        Camera.CameraType = Enum.CameraType.Scriptable
        Rot = Vector2.new(0, 0)
        Conn = RunService.RenderStepped:Connect(function(dt)
            local delta = UserInputService:GetMouseDelta()
            Rot = Rot + (delta * -0.005 * self.Settings.Sensitivity)
            Camera.CFrame = CFrame.new(Camera.CFrame.Position) * CFrame.Angles(0, Rot.X, 0) * CFrame.Angles(Rot.Y, 0, 0)

            local move = Vector3.new()
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
            
            local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1
            if move.Magnitude > 0 then
                Camera.CFrame = Camera.CFrame + Camera.CFrame:VectorToWorldSpace(move.Unit * self.Settings.Speed * mult)
            end
        end)
    else
        if Conn then Conn:Disconnect() end
        Camera.CameraType = Enum.CameraType.Custom
    end
end

return FreeCam
