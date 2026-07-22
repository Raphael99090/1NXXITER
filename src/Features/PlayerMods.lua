
local PlayerMods = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

PlayerMods.Settings = { 
    SpeedEnabled = false, SpeedValue = 50,
    JumpEnabled = false, JumpValue = 100,
    Noclip = false, InfJump = false
}

local function GetHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

-- Loop de persistência (Garante que o Speed/Jump não resete ao morrer)
RunService.RenderStepped:Connect(function()
    local hum = GetHumanoid()
    if hum then
        if PlayerMods.Settings.SpeedEnabled then hum.WalkSpeed = PlayerMods.Settings.SpeedValue end
        if PlayerMods.Settings.JumpEnabled then 
            hum.UseJumpPower = true
            hum.JumpPower = PlayerMods.Settings.JumpValue 
        end
    end
end)

-- Loop de Noclip
RunService.Stepped:Connect(function()
    if PlayerMods.Settings.Noclip and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end
end)

-- Pulo Infinito
UserInputService.JumpRequest:Connect(function()
    if PlayerMods.Settings.InfJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

function PlayerMods:ToggleSpeed(v) self.Settings.SpeedEnabled = v end
function PlayerMods:ToggleJumpPower(v) self.Settings.JumpEnabled = v end
function PlayerMods:ToggleNoclip(v) self.Settings.Noclip = v end
function PlayerMods:ToggleInfJump(v) self.Settings.InfJump = v end

function PlayerMods:DisableAll()
    self.Settings.SpeedEnabled = false
    self.Settings.JumpEnabled = false
    self.Settings.Noclip = false
    self.Settings.InfJump = false
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
end

return PlayerMods
