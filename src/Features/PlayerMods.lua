
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

-- Cache das partes do personagem pro noclip, atualizado só quando o
-- personagem muda (respawn) — em vez de rodar GetDescendants() a cada frame.
local cachedParts = {}
local function RefreshCharacterPartsCache(char)
    cachedParts = {}
    if not char then return end
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then table.insert(cachedParts, part) end
    end
end

local function RestoreCollisions()
    for _, part in pairs(cachedParts) do
        if part and part.Parent then part.CanCollide = true end
    end
end

local Connections = {}

if LocalPlayer.Character then RefreshCharacterPartsCache(LocalPlayer.Character) end

table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    RefreshCharacterPartsCache(char)
end))
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    -- Pega partes novas que aparecem depois do spawn inicial (acessórios, etc.)
    char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedParts, desc)
            if PlayerMods.Settings.Noclip then desc.CanCollide = false end
        end
    end)
end))

-- Loop de persistência (Garante que o Speed/Jump não resete ao morrer)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local hum = GetHumanoid()
    if hum then
        if PlayerMods.Settings.SpeedEnabled then hum.WalkSpeed = PlayerMods.Settings.SpeedValue end
        if PlayerMods.Settings.JumpEnabled then 
            hum.UseJumpPower = true
            hum.JumpPower = PlayerMods.Settings.JumpValue 
        end
    end
end))

-- Loop de Noclip (usa o cache em vez de varrer o personagem todo frame)
table.insert(Connections, RunService.Stepped:Connect(function()
    if PlayerMods.Settings.Noclip then
        for _, part in pairs(cachedParts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end
end))

-- Pulo Infinito
table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if PlayerMods.Settings.InfJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end))

function PlayerMods:ToggleSpeed(v) self.Settings.SpeedEnabled = v end
function PlayerMods:ToggleJumpPower(v) self.Settings.JumpEnabled = v end
function PlayerMods:ToggleNoclip(v)
    self.Settings.Noclip = v
    if not v then RestoreCollisions() end
end
function PlayerMods:ToggleInfJump(v) self.Settings.InfJump = v end

function PlayerMods:DisableAll()
    self.Settings.SpeedEnabled = false
    self.Settings.JumpEnabled = false
    self.Settings.Noclip = false
    self.Settings.InfJump = false
    RestoreCollisions()
    local hum = GetHumanoid()
    if hum then hum.WalkSpeed = 16 hum.JumpPower = 50 end
end

function PlayerMods:Unload()
    self:DisableAll()
    for _, c in pairs(Connections) do c:Disconnect() end
    Connections = {}
end

return PlayerMods
