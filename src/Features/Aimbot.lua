local Aimbot = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

Aimbot.Settings = {
    Enabled = false,
    TeamCheck = false,
    WallCheck = true,
    ShowFOV = false,
    FOVRadius = 150,
    Smoothness = 0.5,
    TargetPart = "HumanoidRootPart",
    HitboxExpander = false,
    HitboxSize = 10
}

local FOVCircle = nil
do
    local ok, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Color = Color3.new(1, 1, 1)
        c.Thickness = 1
        c.Filled = false
        return c
    end)
    if ok then FOVCircle = circle end
end

local function IsVisible(part, camera)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(camera.CFrame.Position, part.Position - camera.CFrame.Position, params)
    return result == nil
end

local function GetTarget(camera)
    local closestDist = Aimbot.Settings.FOVRadius
    local target = nil
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
            if Aimbot.Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local part = p.Character[Aimbot.Settings.TargetPart]
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < closestDist then
                    if Aimbot.Settings.WallCheck and not IsVisible(part, camera) then continue end
                    closestDist = dist
                    target = part
                end
            end
        end
    end
    return target
end

local wasAiming = false

Aimbot._conn = RunService.RenderStepped:Connect(function(dt)
    -- Sempre pega a câmera atual (não cacheada) — se o jogo trocar a
    -- CurrentCamera em algum momento, a feature não fica "morta" em silêncio.
    local Camera = Workspace.CurrentCamera
    if not Camera then return end

    -- FOV Visual
    if FOVCircle then
        FOVCircle.Visible = Aimbot.Settings.ShowFOV
        FOVCircle.Radius = Aimbot.Settings.FOVRadius
        FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    end

    -- Hitbox Expander Logic
    if Aimbot.Settings.HitboxExpander then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(Aimbot.Settings.HitboxSize, Aimbot.Settings.HitboxSize, Aimbot.Settings.HitboxSize)
                p.Character.HumanoidRootPart.Transparency = 0.7
                p.Character.HumanoidRootPart.CanCollide = false
            end
        end
    end

    -- Aimbot Logic
    if Aimbot.Settings.Enabled then
        local target = GetTarget(Camera)
        if target then
            -- Scriptable enquanto mira, senão a câmera padrão do Roblox
            -- briga com o Lerp e fica tremendo.
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Scriptable
            end
            wasAiming = true

            local targetPos = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetPos, Aimbot.Settings.Smoothness * (dt * 60))
        elseif wasAiming then
            -- Sem alvo: devolve o controle pro jogo em vez de deixar
            -- Scriptable travado pra sempre.
            Camera.CameraType = Enum.CameraType.Custom
            wasAiming = false
        end
    elseif wasAiming then
        Camera.CameraType = Enum.CameraType.Custom
        wasAiming = false
    end
end)

function Aimbot:Unload()
    self.Settings.Enabled = false
    if self._conn then self._conn:Disconnect() self._conn = nil end
    local Camera = Workspace.CurrentCamera
    if Camera then Camera.CameraType = Enum.CameraType.Custom end
    if FOVCircle then FOVCircle:Remove() end
end

return Aimbot
