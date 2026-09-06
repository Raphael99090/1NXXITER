
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
local flyUpPulseUntil = 0 -- sem teclado (touch), o botão de pulo dá um empurrão pra cima por um instante
local lastSafeCFrame = nil

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

-- Antes eram duas conexões separadas ao mesmo CharacterAdded (uma só pra
-- atualizar o cache, outra só pra escutar DescendantAdded) — junto em uma
-- só, e agora a conexão de DescendantAdded do char anterior é desconectada
-- no respawn seguinte em vez de empilhar uma nova a cada morte.
local descendantConn = nil
table.insert(Connections, LocalPlayer.CharacterAdded:Connect(function(char)
    RefreshCharacterPartsCache(char)

    if descendantConn then descendantConn:Disconnect() end
    descendantConn = char.DescendantAdded:Connect(function(desc)
        if desc:IsA("BasePart") then
            table.insert(cachedParts, desc)
            if PlayerMods.Settings.Noclip then desc.CanCollide = false end
        end
    end)
end))

-- Loop de persistência (Garante que o Speed/Jump não resete ao morrer)
table.insert(Connections, RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hum = GetHumanoid()
    local root = char and char:FindFirstChild("HumanoidRootPart")

    if hum then
        if PlayerMods.Settings.SpeedEnabled then hum.WalkSpeed = PlayerMods.Settings.SpeedValue end
        if PlayerMods.Settings.JumpEnabled then 
            hum.UseJumpPower = true
            hum.JumpPower = PlayerMods.Settings.JumpValue 
        end
    end

    -- Fly: reaproveita o MoveDirection que o próprio Roblox já calcula a
    -- partir do WASD/joystick (funciona igual em PC e touch), soma o
    -- vertical via teclado (Espaço/Ctrl) ou o pulso do botão de pulo.
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

    -- Anti-Void: só marca "posição segura" quando tá de pé em algo de
    -- verdade (senão salvaria posição no meio da queda). Se cair abaixo
    -- do limite do mapa, teleporta de volta pra última posição segura.
    if PlayerMods.Settings.AntiVoid and root then
        if hum and hum.FloorMaterial ~= Enum.Material.Air and root.Position.Y > VOID_Y then
            lastSafeCFrame = root.CFrame
        elseif root.Position.Y < VOID_Y and lastSafeCFrame then
            root.CFrame = lastSafeCFrame
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
    if PlayerMods.Settings.Fly then
        flyUpPulseUntil = tick() + 0.35
    end
end))

function PlayerMods:ToggleSpeed(v) self.Settings.SpeedEnabled = v end
function PlayerMods:ToggleJumpPower(v) self.Settings.JumpEnabled = v end
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
        if not root then self.Settings.Fly = false return end
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
    lastSafeCFrame = nil
end

function PlayerMods:DisableAll()
    self.Settings.SpeedEnabled = false
    self.Settings.JumpEnabled = false
    self.Settings.Noclip = false
    self.Settings.InfJump = false
    self.Settings.Fly = false
    self.Settings.AntiVoid = false
    RestoreCollisions()
    if FlyBV then FlyBV.Parent = nil end
    local hum = GetHumanoid()
    if hum then
        hum.WalkSpeed = 16
        hum.JumpPower = 50
        hum.PlatformStand = false
    end
end

function PlayerMods:Unload()
    self:DisableAll()
    for _, c in pairs(Connections) do c:Disconnect() end
    Connections = {}
    if descendantConn then descendantConn:Disconnect() descendantConn = nil end
    if FlyBV then FlyBV:Destroy() FlyBV = nil end
end

return PlayerMods
