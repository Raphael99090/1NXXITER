local FreeCam = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

FreeCam.Settings = { Enabled = false, Speed = 1, Sensitivity = 0.5 }
local Conn = nil
local LookConn = nil
local TouchEndConn = nil -- antes não era guardada: cada Toggle(true) criava uma nova sem nunca desconectar a anterior
local Rot = Vector2.new(0, 0)

local MAX_PITCH = math.rad(89) -- sem isso a câmera passa da vertical e "vira de cabeça pra baixo"

-- Mesmo problema do Aimbot: CameraType Scriptable faz o Roblox desligar
-- o joystick de andar sozinho. Forçamos ele de volta.
local function KeepTouchControlsEnabled()
    pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
        PlayerModule:GetControls():Enable()
    end)
end

-- GetMouseDelta só existe com mouse. Em touch (celular), a rotação da
-- câmera passa a vir do arrasto na tela — sem isso, FreeCam só funcionava no PC.
local touchDelta = Vector2.new(0, 0)
local lastTouchPos = nil

function FreeCam:Toggle(state)
    self.Settings.Enabled = state
    local Camera = workspace.CurrentCamera
    if not Camera then return end

    if state then
        if Conn then Conn:Disconnect() Conn = nil end
        if LookConn then LookConn:Disconnect() LookConn = nil end
        if TouchEndConn then TouchEndConn:Disconnect() TouchEndConn = nil end

        Camera.CameraType = Enum.CameraType.Scriptable
        
        local Controls = nil
        pcall(function()
            local pm = LocalPlayer.PlayerScripts:WaitForChild("PlayerModule", 1)
            if pm then
                local PlayerModule = require(pm)
                Controls = PlayerModule:GetControls()
                Controls:Enable()
            end
        end)
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = true
        end

        Rot = Vector2.new(Camera.CFrame:ToEulerAnglesYXZ()) -- Inicia olhando pra onde já estava
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

        TouchEndConn = UserInputService.TouchEnded:Connect(function()
            lastTouchPos = nil
        end)

        Conn = RunService.RenderStepped:Connect(function(dt)
            local cam = workspace.CurrentCamera
            if not cam then return end

            local delta = UserInputService:GetMouseDelta()
            if delta.Magnitude == 0 then
                delta = touchDelta
                touchDelta = Vector2.new(0, 0)
            end

            Rot = Rot + (delta * -0.005 * self.Settings.Sensitivity)
            Rot = Vector2.new(Rot.X, math.clamp(Rot.Y, -MAX_PITCH, MAX_PITCH))
            cam.CFrame = CFrame.new(cam.CFrame.Position) * CFrame.Angles(0, Rot.X, 0) * CFrame.Angles(Rot.Y, 0, 0)

            local move = Vector3.new()
            
            if Controls then
                local joystickMove = Controls:GetMoveVector()
                move = Vector3.new(joystickMove.X, 0, joystickMove.Z)
            else
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + Vector3.new(0,0,-1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move + Vector3.new(0,0,1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move + Vector3.new(-1,0,0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + Vector3.new(1,0,0) end
            end
            
            if UserInputService:IsKeyDown(Enum.KeyCode.E) then move = move + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.Q) then move = move + Vector3.new(0,-1,0) end
            
            local mult = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) and 4 or 1
            if move.Magnitude > 0 then
                -- Normalize se for maior que 1 (evita andar muito rápido na diagonal no PC)
                if move.Magnitude > 1 then move = move.Unit end
                cam.CFrame = cam.CFrame + cam.CFrame:VectorToWorldSpace(move * self.Settings.Speed * mult)
            end
        end)
    else
        if Conn then Conn:Disconnect() Conn = nil end
        if LookConn then LookConn:Disconnect() LookConn = nil end
        if TouchEndConn then TouchEndConn:Disconnect() TouchEndConn = nil end
        Camera.CameraType = Enum.CameraType.Custom
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            LocalPlayer.Character.HumanoidRootPart.Anchored = false
        end
    end
end

function FreeCam:Unload()
    self:Toggle(false)
end

return FreeCam
