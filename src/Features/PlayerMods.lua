local PlayerMods = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

PlayerMods.Settings = { 
    SpeedEnabled = false, SpeedValue = 50,
    JumpEnabled = false, JumpValue = 100,
    Noclip = false, InfJump = false,
    Fly = false, FlySpeed = 50,
    AntiVoid = false
}

local VOID_Y = -500 -- abaixo disso conta como "caiu do mapa"

local FlyBV = nil
local flyUpPulseUntil = 0
local lastSafeCFrame = nil

local originalStates = {
    Speed = nil,
    JumpPower = nil,
    JumpHeight = nil,
    UseJumpPower = nil,
    Collisions = {} -- [part] = original CanCollide boolean
}

local function GetHumanoid()
    return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end

local cachedParts = {}
local function RefreshCharacterPartsCache(char)
    cachedParts = {}
    originalStates.Collisions = {}
    if not char then return end
    
    for _, part in pairs(char:GetDescendants()) do
        if part:IsA("BasePart") then 
            table.insert(cachedParts, part)
            originalStates.Collisions[part] = part.CanCollide
            if PlayerMods.Settings.Noclip then part.CanCollide = false end
        end
    end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        originalStates.Speed = hum.WalkSpeed
        originalStates.JumpPower = hum.JumpPower
        originalStates.JumpHeight = hum.JumpHeight
        originalStates.UseJumpPower = hum.UseJumpPower
    end
    
    if PlayerMods.Settings.Fly then
        task.defer(function() PlayerMods:ToggleFly(true) end)
    end
    if PlayerMods.Settings.AntiVoid then
        lastSafeCFrame = nil
    end
end

local function RestoreCollisions()
    for _, part in pairs(cachedParts) do
        if part and part.Parent and originalStates.Collisions[part] ~= nil then 
            part.CanCollide = originalStates.Collisions[part] 
        end
    end
end

local Connections = {}

if LocalPlayer.Character then RefreshCharacterPartsCache(LocalPlayer.Character) end

local descendantConn = nil
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    RefreshCharacterPartsCache(char)

    if descendantConn then descendantConn:Disconnect() end
    descendantConn = char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedParts, desc)
            originalStates.Collisions[desc] = desc.CanCollide
            if PlayerMods.Settings.Noclip then desc.CanCollide = false end
        elseif desc:IsA("Humanoid") then
            -- Captura imediata antes do RenderStepped alterar
            originalStates.Speed = desc.WalkSpeed
            originalStates.JumpPower = desc.JumpPower
            originalStates.JumpHeight = desc.JumpHeight
            originalStates.UseJumpPower = desc.UseJumpPower
        end
    end)
end))

table.insert(Connections, RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = GetHumanoid()
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if hum then
        if PlayerMods.Settings.SpeedEnabled then 
            hum.WalkSpeed = PlayerMods.Settings.SpeedValue 
        end
        
        if PlayerMods.Settings.JumpEnabled then 
            hum.UseJumpPower = true
            hum.JumpPower = PlayerMods.Settings.JumpValue 
        end
    end

    if PlayerMods.Settings.Fly and root and FlyBV then
        local moveDir = hum and hum.MoveDirection or Vector3.new()
        local vertical = 0
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            vertical = 1
        elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            vertical = -1
        elseif tick() < flyUpPulseUntil then
            vertical = 1
        end
        FlyBV.Velocity = (moveDir * PlayerMods.Settings.FlySpeed) + Vector3.new(0, vertical * PlayerMods.Settings.FlySpeed, 0)
    end

    if PlayerMods.Settings.AntiVoid and root then
        if hum and hum.FloorMaterial ~= Enum.Material.Air and root.Position.Y > VOID_Y then
            lastSafeCFrame = root.CFrame
        elseif root.Position.Y < VOID_Y and lastSafeCFrame then
            root.CFrame = lastSafeCFrame
        end
    end
end))

table.insert(Connections, RunService.Stepped:Connect(function()
    if PlayerMods.Settings.Noclip then
        for _, part in pairs(cachedParts) do
            if part and part.Parent then part.CanCollide = false end
        end
    end
end))

table.insert(Connections, UserInputService.JumpRequest:Connect(function()
    if PlayerMods.Settings.InfJump then
        local hum = GetHumanoid()
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
    if PlayerMods.Settings.Fly then
        flyUpPulseUntil = tick() + 0.35
    end
end))

function PlayerMods:ToggleSpeed(v) 
    self.Settings.SpeedEnabled = v 
    if v then
        local hum = GetHumanoid()
        if hum and hum.WalkSpeed ~= self.Settings.SpeedValue then
            originalStates.Speed = hum.WalkSpeed
        end
    else
        local hum = GetHumanoid()
        if hum and originalStates.Speed ~= nil then
            hum.WalkSpeed = originalStates.Speed
        end
    end
end

function PlayerMods:ToggleJumpPower(v) 
    self.Settings.JumpEnabled = v 
    if v then
        local hum = GetHumanoid()
        if hum and hum.JumpPower ~= self.Settings.JumpValue then
            originalStates.JumpPower = hum.JumpPower
            originalStates.JumpHeight = hum.JumpHeight
            originalStates.UseJumpPower = hum.UseJumpPower
        end
    else
        local hum = GetHumanoid()
        if hum and originalStates.UseJumpPower ~= nil then
            hum.UseJumpPower = originalStates.UseJumpPower
            hum.JumpPower = originalStates.JumpPower
            hum.JumpHeight = originalStates.JumpHeight
        end
    end
end

function PlayerMods:ToggleNoclip(v)
    self.Settings.Noclip = v
    if not v then RestoreCollisions() end
end
function PlayerMods:ToggleInfJump(v) self.Settings.InfJump = v end

function PlayerMods:ToggleFly(v)
    self.Settings.Fly = v
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if v then
        if not root then return end
        if not FlyBV then
            FlyBV = Instance.new("BodyVelocity")
            FlyBV.Name = "InxiterFly"
            FlyBV.MaxForce = Vector3.new(1e9, 1e9, 1e9)
        end
        FlyBV.Velocity = Vector3.new()
        FlyBV.Parent = root
        if hum then hum.PlatformStand = true end
    else
        if FlyBV then FlyBV.Parent = nil end
        if hum then hum.PlatformStand = false end
    end
end

function PlayerMods:ToggleAntiVoid(v)
    self.Settings.AntiVoid = v
    if not v then lastSafeCFrame = nil end
end

function PlayerMods:DisableAll()
    self:ToggleSpeed(false)
    self:ToggleJumpPower(false)
    self:ToggleNoclip(false)
    self:ToggleInfJump(false)
    self:ToggleFly(false)
    self:ToggleAntiVoid(false)
end

function PlayerMods:Unload()
    self:DisableAll()
    for _, c in pairs(Connections) do c:Disconnect() end
    Connections = {}
    if descendantConn then descendantConn:Disconnect() descendantConn = nil end
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
    cachedParts = {}
    originalStates.Collisions = {}
end

return PlayerMods
