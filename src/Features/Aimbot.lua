local Aimbot = {}
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- Guarda o Size original do HumanoidRootPart de cada jogador antes de
-- expandir — sem isso, desligar o Hitbox Expander não devolvia o tamanho
-- original e os personagens ficavam com colliders gigantes pra sempre.
local originalHitboxes = {}

-- Quando a câmera vira Scriptable (usado pra mirar), o script padrão de
-- controles touch do Roblox se desliga por conta própria — é assim que
-- o joystick de andar "desaparece" no celular. Forçar Enable() aqui
-- mantém ele visível mesmo com a câmera em modo Scriptable.
local function KeepTouchControlsEnabled()
    local ok = pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
        PlayerModule:GetControls():Enable()
    end)
    return ok
end

Aimbot.Settings = {
    Enabled = false,
    TeamCheck = false,
    WallCheck = true,
    ShowFOV = false,
    FOVRadius = 150,
    Smoothness = 0.5,
    TargetPart = "HumanoidRootPart",
    HitboxExpander = false,
    HitboxSize = 10,
    SilentAim = false, -- trava o alvo sem girar a câmera (ver nota abaixo)
    Priority = "Closest", -- "Closest" (mais perto da mira) ou "LowHealth" (menor vida)
    AimKeyOnly = false, -- só mira enquanto segura AimKey, em vez de sempre que tiver alvo
    AimKey = Enum.KeyCode.E
}

-- Marcador do alvo travado, só aparece no modo Silent Aim (pra ainda dar
-- um retorno visual de quem tá marcado, já que a câmera não se mexe).
local LockMarker = nil
do
    local ok, circle = pcall(function()
        local c = Drawing.new("Circle")
        c.Color = Color3.fromRGB(255, 60, 60)
        c.Thickness = 2
        c.Radius = 10
        c.Filled = false
        c.NumSides = 3
        c.Visible = false
        return c
    end)
    if ok then LockMarker = circle end
end

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
    local target = nil
    local bestScore = nil
    local center = Vector2.new(camera.ViewportSize.X/2, camera.ViewportSize.Y/2)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
            if Aimbot.Settings.TeamCheck and p.Team == LocalPlayer.Team then continue end
            
            local part = p.Character[Aimbot.Settings.TargetPart]
            local pos, onScreen = camera:WorldToViewportPoint(part.Position)
            
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < Aimbot.Settings.FOVRadius then
                    if Aimbot.Settings.WallCheck and not IsVisible(part, camera) then continue end

                    -- "Closest" pontua por distância até a mira (menor = melhor,
                    -- igual sempre foi). "LowHealth" pontua pela vida atual —
                    -- ainda só considera quem tá dentro do FOV e visível.
                    local score = dist
                    if Aimbot.Settings.Priority == "LowHealth" then
                        local hum = p.Character:FindFirstChildOfClass("Humanoid")
                        score = hum and hum.Health or math.huge
                    end

                    if not bestScore or score < bestScore then
                        bestScore = score
                        target = part
                    end
                end
            end
        end
    end
    return target
end

local wasAiming = false
Aimbot.IsAiming = false -- exposto pra UI poder mostrar status ao vivo (CombatTab)
Aimbot.LockedTarget = nil -- exposto pra UI/outras features saberem quem tá marcado

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

    -- Hitbox Expander Logic (com salvamento/restauração de tamanho original)
    if Aimbot.Settings.HitboxExpander then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = p.Character.HumanoidRootPart
                if not originalHitboxes[p] then
                    originalHitboxes[p] = root.Size
                end
                root.Size = Vector3.new(Aimbot.Settings.HitboxSize, Aimbot.Settings.HitboxSize, Aimbot.Settings.HitboxSize)
                root.Transparency = 0.7
                root.CanCollide = false
            end
        end
        -- Cleanup players that left or respawned
        for p, origSize in pairs(originalHitboxes) do
            if not p.Parent or not p.Character or not p.Character:FindFirstChild("HumanoidRootPart") then
                originalHitboxes[p] = nil
            elseif p.Character.HumanoidRootPart.Size == origSize then
                -- if somehow it was reset, we clear it so we can capture it again if needed
                -- this prevents the table holding onto old references forever
                originalHitboxes[p] = nil
            end
        end
    elseif next(originalHitboxes) then
        -- Restaura hitboxes originais quando desligado
        for p, origSize in pairs(originalHitboxes) do
            pcall(function()
                if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                    local root = p.Character.HumanoidRootPart
                    root.Size = origSize
                    root.Transparency = 0
                    root.CanCollide = true
                end
            end)
        end
        originalHitboxes = {}
    end

    -- Aimbot Logic
    if Aimbot.Settings.Enabled then
        -- Com AimKeyOnly ligado, só busca alvo enquanto a tecla tá
        -- segurada — soltou, cai igualzinho no caminho de "sem alvo"
        -- logo abaixo (devolve a câmera pro jogador).
        local keyOk = not Aimbot.Settings.AimKeyOnly or UserInputService:IsKeyDown(Aimbot.Settings.AimKey)
        local target = keyOk and GetTarget(Camera) or nil
        Aimbot.LockedTarget = target

        if target and Aimbot.Settings.SilentAim then
            -- SILENT AIM: só marca o alvo internamente (LockedTarget/IsAiming)
            -- e desenha um indicador na tela — a câmera fica 100% livre na
            -- sua mão, nunca gira sozinha. Não existe um hook de disparo
            -- genérico pra esse jogo, então isso não redireciona tiro
            -- sozinho: é o modo "mira sem se mexer" pra mirar você mesmo
            -- em cima da marcação, sem ninguém perceber a câmera travando.
            if Camera.CameraType ~= Enum.CameraType.Custom then
                Camera.CameraType = Enum.CameraType.Custom
            end
            wasAiming = false
            Aimbot.IsAiming = true

            if LockMarker then
                local pos, onScreen = Camera:WorldToViewportPoint(target.Position)
                LockMarker.Visible = onScreen
                LockMarker.Position = Vector2.new(pos.X, pos.Y)
            end
        elseif target then
            if LockMarker then LockMarker.Visible = false end
            -- Scriptable enquanto mira, senão a câmera padrão do Roblox
            -- briga com o Lerp e fica tremendo.
            if Camera.CameraType ~= Enum.CameraType.Scriptable then
                Camera.CameraType = Enum.CameraType.Scriptable
                KeepTouchControlsEnabled() -- sem isso o joystick de andar some no celular
            end
            wasAiming = true
            Aimbot.IsAiming = true

            local targetPos = CFrame.new(Camera.CFrame.Position, target.Position)
            Camera.CFrame = Camera.CFrame:Lerp(targetPos, Aimbot.Settings.Smoothness * (dt * 60))
        else
            if LockMarker then LockMarker.Visible = false end
            if wasAiming then
                -- Sem alvo: devolve o controle pro jogo em vez de deixar
                -- Scriptable travado pra sempre.
                Camera.CameraType = Enum.CameraType.Custom
                wasAiming = false
            end
            Aimbot.IsAiming = false
        end
    else
        if LockMarker then LockMarker.Visible = false end
        Aimbot.LockedTarget = nil
        if wasAiming then
            Camera.CameraType = Enum.CameraType.Custom
            wasAiming = false
        end
        Aimbot.IsAiming = false
    end
end)

function Aimbot:Unload()
    self.Settings.Enabled = false
    self.Settings.HitboxExpander = false
    self.IsAiming = false
    self.LockedTarget = nil

    -- Restaura hitboxes antes de desconectar
    for p, origSize in pairs(originalHitboxes) do
        pcall(function()
            if p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                local root = p.Character.HumanoidRootPart
                root.Size = origSize
                root.Transparency = 0
                root.CanCollide = true
            end
        end)
    end
    originalHitboxes = {}

    if self._conn then self._conn:Disconnect() self._conn = nil end
    local Camera = Workspace.CurrentCamera
    if Camera then Camera.CameraType = Enum.CameraType.Custom end
    if FOVCircle then FOVCircle:Remove() end
    if LockMarker then LockMarker:Remove() end
end

return Aimbot
