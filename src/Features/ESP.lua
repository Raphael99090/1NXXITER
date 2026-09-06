local ESP = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Trocado de Box/Skeleton/HealthBar (Drawing API) pra só Chams (Highlight
-- que enxerga através de parede). Pedido explícito: minimalista e simples —
-- menos código, menos coisa rodando todo frame, sem Drawings pra gerenciar.
-- Tracers/Distância são opt-in (desligados por padrão) — só ligam Drawings
-- de novo se o jogador realmente pedir.
ESP.Settings = {
    Enabled = false,
    TeamCheck = false,
    Color = Color3.fromRGB(255, 40, 40),
    FillTransparency = 0.6,
    Tracers = false,
    Distance = false
}

ESP._connections = {}

-- Aplica/atualiza (ou remove) o Highlight de um personagem específico.
local function UpdateChams(player, char)
    if not char then return end
    local highlight = char:FindFirstChild("InxiterChams")

    local shouldShow = ESP.Settings.Enabled
        and player ~= LocalPlayer
        and not (ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team)

    if not shouldShow then
        if highlight then highlight:Destroy() end
        return
    end

    if not highlight then
        highlight = Instance.new("Highlight")
        highlight.Name = "InxiterChams"
        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        highlight.Parent = char
    end

    highlight.FillColor = ESP.Settings.Color
    highlight.OutlineColor = ESP.Settings.Color
    highlight.FillTransparency = ESP.Settings.FillTransparency
    highlight.OutlineTransparency = 0
end

local function UpdateAll()
    for _, player in pairs(Players:GetPlayers()) do
        UpdateChams(player, player.Character)
    end
end

-- [ TRACERS / DISTÂNCIA ] — Drawings à parte do Highlight, só existem
-- enquanto pelo menos um dos dois estiver ligado. Um cache por jogador,
-- limpo no Toggle(false) e quando alguém sai da partida.
local drawCache = {}

local function ClearDrawing(player)
    local data = drawCache[player]
    if not data then return end
    if data.Line then pcall(function() data.Line:Remove() end) end
    if data.Text then pcall(function() data.Text:Remove() end) end
    drawCache[player] = nil
end

local function EnsureDrawing(player)
    local data = drawCache[player]
    if data then return data end
    local okLine, line = pcall(function()
        local l = Drawing.new("Line")
        l.Thickness = 1
        l.Visible = false
        return l
    end)
    local okText, text = pcall(function()
        local t = Drawing.new("Text")
        t.Size = 13
        t.Center = true
        t.Outline = true
        t.Color = Color3.new(1, 1, 1)
        t.Visible = false
        return t
    end)
    data = { Line = okLine and line or nil, Text = okText and text or nil }
    drawCache[player] = data
    return data
end

local function UpdateDrawings()
    if not (ESP.Settings.Tracers or ESP.Settings.Distance) then return end
    local camera = Workspace.CurrentCamera
    if not camera then return end
    local screenBottom = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y)

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            local char = player.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local shouldShow = ESP.Settings.Enabled and root
                and not (ESP.Settings.TeamCheck and player.Team == LocalPlayer.Team)

            if shouldShow then
                local pos, onScreen = camera:WorldToViewportPoint(root.Position)
                local data = EnsureDrawing(player)
                if onScreen then
                    if data.Line then
                        data.Line.Visible = ESP.Settings.Tracers
                        data.Line.From = screenBottom
                        data.Line.To = Vector2.new(pos.X, pos.Y)
                        data.Line.Color = ESP.Settings.Color
                    end
                    if data.Text then
                        local dist = (camera.CFrame.Position - root.Position).Magnitude
                        data.Text.Visible = ESP.Settings.Distance
                        data.Text.Position = Vector2.new(pos.X, pos.Y - 16)
                        data.Text.Text = math.floor(dist) .. "m"
                    end
                else
                    if data.Line then data.Line.Visible = false end
                    if data.Text then data.Text.Visible = false end
                end
            elseif drawCache[player] then
                ClearDrawing(player)
            end
        end
    end
end

local function HookPlayer(player)
    table.insert(ESP._connections, player.CharacterAdded:Connect(function(char)
        task.wait() -- deixa o char popular (Humanoid, etc.) antes de aplicar
        UpdateChams(player, char)
    end))
    UpdateChams(player, player.Character)
end

function ESP:Toggle(state)
    ESP.Settings.Enabled = state
    if state then
        -- Guard: desconecta tudo antes de religar (previne duplicatas
        -- se o toggle for clicado rápido demais sem desligar primeiro)
        if #ESP._connections > 0 then
            for _, c in pairs(ESP._connections) do c:Disconnect() end
            ESP._connections = {}
        end
        for _, player in pairs(Players:GetPlayers()) do HookPlayer(player) end
        table.insert(ESP._connections, Players.PlayerAdded:Connect(HookPlayer))
        table.insert(ESP._connections, RunService.RenderStepped:Connect(UpdateDrawings))
        table.insert(ESP._connections, Players.PlayerRemoving:Connect(ClearDrawing))
        -- Sem cleanup manual do Highlight pro PlayerRemoving: ele é filho do
        -- Character, então some sozinho quando o Roblox destrói o
        -- Character do jogador que saiu. Os Drawings de Tracer/Distância
        -- já têm o ClearDrawing acima porque esses não são filhos de nada.
    else
        for _, c in pairs(ESP._connections) do c:Disconnect() end
        ESP._connections = {}
        for _, player in pairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local hl = char:FindFirstChild("InxiterChams")
                if hl then hl:Destroy() end
            end
            ClearDrawing(player)
        end
    end
end

-- TeamCheck e cor mudam em runtime — reaplica em todo mundo na hora,
-- sem esperar o próximo respawn.
function ESP:Refresh()
    if ESP.Settings.Enabled then UpdateAll() end
end

function ESP:Unload()
    self:Toggle(false)
end

return ESP
