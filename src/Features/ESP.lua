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
    HealthBar = false,  -- ADICIONADO: compatível com a Tab
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
    -- ADICIONADO: HealthBar
    local healthBar = CreateDrawing("Square", {Thickness = 1, Filled = true, Visible = false, Color = Color3.fromRGB(0,255,0)})
    local healthBarBg = CreateDrawing("Square", {Thickness = 1, Filled = true, Visible = false, Color = Color3.fromRGB(255,0,0)})

    if box and out then
        ESP.Cache[player] = { 
            Box = box, 
            BoxOutline = out, 
            Skeleton = lines,
            HealthBar = healthBar,
            HealthBarBg = healthBarBg
        }
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

        local shouldShow = ESP.Settings.Enabled and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Humanoid") and char.Humanoid.Health > 0
        local isEnemy = not (ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team)

        if shouldShow and isEnemy then
            local root = char.HumanoidRootPart
            local humanoid = char.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)

            if onScreen then
                -- Calcular bounds do personagem
                local head = char:FindFirstChild("Head")
                local headPos = head and Camera:WorldToViewportPoint(head.Position)
                local feetPos = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

                local boxHeight = math.abs((headPos and headPos.Y or pos.Y - 50) - feetPos.Y)
                local boxWidth = boxHeight * 0.6
                local boxX = pos.X - boxWidth / 2
                local boxY = headPos and headPos.Y or (pos.Y - boxHeight / 2)

                -- BOX + OUTLINE
                if ESP.Settings.Box then
                    data.Box.Visible = true
                    data.BoxOutline.Visible = true
                    data.Box.Size = Vector2.new(boxWidth, boxHeight)
                    data.Box.Position = Vector2.new(boxX, boxY)
                    data.Box.Color = ESP.Settings.BoxColor

                    data.BoxOutline.Size = data.Box.Size + Vector2.new(2, 2)
                    data.BoxOutline.Position = data.Box.Position - Vector2.new(1, 1)
                else
                    data.Box.Visible = false
                    data.BoxOutline.Visible = false
                end

                -- SKELETON
                if ESP.Settings.Skeleton then
                    for i, bonePair in ipairs(R15Bones) do
                        local part1 = char:FindFirstChild(bonePair[1])
                        local part2 = char:FindFirstChild(bonePair[2])
                        local line = data.Skeleton[i]

                        if part1 and part2 and line then
                            local p1 = Camera:WorldToViewportPoint(part1.Position)
                            local p2 = Camera:WorldToViewportPoint(part2.Position)

                            if p1.Z > 0 and p2.Z > 0 then
                                line.Visible = true
                                line.From = Vector2.new(p1.X, p1.Y)
                                line.To = Vector2.new(p2.X, p2.Y)
                                line.Color = ESP.Settings.SkeletonColor
                            else
                                line.Visible = false
                            end
                        elseif line then
                            line.Visible = false
                        end
                    end
                else
                    for _, l in pairs(data.Skeleton) do l.Visible = false end
                end

                -- HEALTH BAR
                if ESP.Settings.HealthBar then
                    local healthPercent = humanoid.Health / humanoid.MaxHealth
                    local barWidth = 4
                    local barHeight = boxHeight
                    local barX = boxX - barWidth - 4
                    local barY = boxY

                    data.HealthBarBg.Visible = true
                    data.HealthBarBg.Size = Vector2.new(barWidth, barHeight)
                    data.HealthBarBg.Position = Vector2.new(barX, barY)

                    data.HealthBar.Visible = true
                    data.HealthBar.Size = Vector2.new(barWidth, barHeight * healthPercent)
                    data.HealthBar.Position = Vector2.new(barX, barY + barHeight * (1 - healthPercent))
                else
                    data.HealthBar.Visible = false
                    data.HealthBarBg.Visible = false
                end

            else
                -- Fora da tela: esconder tudo
                data.Box.Visible = false
                data.BoxOutline.Visible = false
                for _, l in pairs(data.Skeleton) do l.Visible = false end
                data.HealthBar.Visible = false
                data.HealthBarBg.Visible = false
            end
        else
            -- Desligado ou morto: esconder tudo
            data.Box.Visible = false
            data.BoxOutline.Visible = false
            for _, l in pairs(data.Skeleton) do l.Visible = false end
            data.HealthBar.Visible = false
            data.HealthBarBg.Visible = false
        end
    end
end

function ESP:Toggle(state)
    ESP.Settings.Enabled = state
    if state then
        ESP.Conn = RunService.RenderStepped:Connect(function() pcall(ESP.Update, ESP) end)
    else
        if ESP.Conn then ESP.Conn:Disconnect() end
        -- Remove todos os Highlights
        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local hl = char:FindFirstChild("InxiterAura")
                if hl then hl:Destroy() end
            end
        end
        -- Remove todos os Drawings
        for p, data in pairs(ESP.Cache) do
            if data then
                pcall(function() data.Box:Remove() end)
                pcall(function() data.BoxOutline:Remove() end)
                pcall(function() data.HealthBar:Remove() end)
                pcall(function() data.HealthBarBg:Remove() end)
                for _, l in pairs(data.Skeleton) do pcall(function() l:Remove() end) end
            end
        end
        ESP.Cache = {}
    end
end

return ESP
