local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

ESP.Settings = {
    Enabled = false,
    TeamCheck = false,
    Aura = false,
    Box = false,
    Skeleton = false,
    AuraColor = Color3.fromRGB(255, 0, 0),
    BoxColor = Color3.fromRGB(255, 255, 255),
    SkeletonColor = Color3.fromRGB(255, 255, 255),
    AuraTransparency = 0.5,
    Thickness = 1.5
}

ESP.Cache = {}

local R15Bones = {
    {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

local function CreateDrawing(class, props)
    local ok, drawing = pcall(function()
        local d = Drawing.new(class)
        for k, v in pairs(props) do d[k] = v end
        return d
    end)
    return ok and drawing or nil
end

local function UpdateAura(player, char)
    if not char then return end 
    local highlight = char:FindFirstChild("InxiterAura")
    if not ESP.Settings.Enabled or not ESP.Settings.Aura or (ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team) then
        if highlight then highlight:Destroy() end
        return
    end
    if not highlight then
        highlight = Instance.new("Highlight", char)
        highlight.Name = "InxiterAura"
    end
    highlight.FillColor = ESP.Settings.AuraColor
    highlight.FillAlpha = ESP.Settings.AuraTransparency
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

function ESP:CreateDrawings(player)
    if ESP.Cache[player] ~= nil then return end
    local lines = {}
    for i = 1, 15 do
        local l = CreateDrawing("Line", {Thickness = ESP.Settings.Thickness, Transparency = 1, Visible = false})
        if l then lines[i] = l end
    end
    local box = CreateDrawing("Square", {Thickness = ESP.Settings.Thickness, Filled = false, Visible = false})
    local out = CreateDrawing("Square", {Thickness = ESP.Settings.Thickness + 1, Color = Color3.new(0,0,0), Visible = false})
    
    if box and out then
        ESP.Cache[player] = { Box = box, BoxOutline = out, Skeleton = lines }
    else
        ESP.Cache[player] = false
    end
end

function ESP:Update()
    local Camera = workspace.CurrentCamera
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local char = player.Character
        if ESP.Cache[player] == nil then ESP:CreateDrawings(player) end
        local data = ESP.Cache[player]
        
        UpdateAura(player, char)
        if not data then continue end

        if ESP.Settings.Enabled and char and char:FindFirstChild("HumanoidRootPart") and char.Humanoid.Health > 0 then
            local root = char.HumanoidRootPart
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            
            if onScreen and not (ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team) then
                if ESP.Settings.Box then
                    data.Box.Visible = true
                    data.Box.Size = Vector2.new(2000/pos.Z, 3000/pos.Z)
                    data.Box.Position = Vector2.new(pos.X - data.Box.Size.X/2, pos.Y - data.Box.Size.Y/2)
                    data.Box.Color = ESP.Settings.BoxColor
                else data.Box.Visible = false end
            else
                data.Box.Visible = false
                data.BoxOutline.Visible = false
                for _, l in pairs(data.Skeleton) do l.Visible = false end
            end
        else
            if data then data.Box.Visible = false data.BoxOutline.Visible = false end
        end
    end
end

function ESP:Toggle(state)
    ESP.Settings.Enabled = state
    if state then
        ESP.Conn = RunService.RenderStepped:Connect(function() pcall(ESP.Update, ESP) end)
    else
        if ESP.Conn then ESP.Conn:Disconnect() end
        for p, _ in pairs(ESP.Cache) do pcall(function() ESP.Cache[p].Box:Remove() end) end
        ESP.Cache = {}
    end
end

return ESP
