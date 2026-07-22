local Aimbot = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
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

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.new(1, 1, 1)
FOVCircle.Thickness = 1
FOVCircle.Filled = false

local function IsVisible(part)
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, params)
    return result == nil
end

local function GetTarget()
    local closestDist = Aimbot.Settings.FOVRadius
    local target = nil
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
            if Aimbot.Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local part = p.Character[Aimbot.Settings.TargetPart]
            local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < closestDist then
                    if Aimbot.Settings.WallCheck and not IsVisible(part) then continue end
                    closestDist = dist
                    target = part
                end
            end
        end
    end
    return target
end

RunService.RenderStepped:Connect(function(dt)
    -- FOV Visual
    FOVCircle.Visible = Aimbot.Settings.ShowFOV
    FOVCircle.Radius = Aimbot.Settings.FOVRadius
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)

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
        local target = GetTarget()
        if target then
            local targetPos = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetPos, Aimbot.Settings.Smoothness * (dt * 60))
        end
    end
end)

return Aimbot
