local Visuals = {}
local RunService = game:GetService("RunService")

Visuals.Settings = { StretchedEnabled = false, FOVValue = 100 }

function Visuals:ToggleStretched(v)
    self.Settings.StretchedEnabled = v
    if not v then
        local Camera = workspace.CurrentCamera
        if Camera then Camera.FieldOfView = 70 end
    end
end

function Visuals:UpdateFOV(v)
    self.Settings.FOVValue = v
    if self.Settings.StretchedEnabled then
        local Camera = workspace.CurrentCamera
        if Camera then Camera.FieldOfView = v end
    end
end

-- Mantém o FOV mesmo se o jogo tentar mudar. Busca workspace.CurrentCamera
-- a cada frame em vez de cachear — se o jogo trocar a câmera (cutscene,
-- respawn especial), a feature não "morre" silenciosamente numa referência velha.
Visuals._conn = RunService.RenderStepped:Connect(function()
    if Visuals.Settings.StretchedEnabled then
        local Camera = workspace.CurrentCamera
        if Camera then Camera.FieldOfView = Visuals.Settings.FOVValue end
    end
end)

function Visuals:Unload()
    self.Settings.StretchedEnabled = false
    if self._conn then self._conn:Disconnect() self._conn = nil end
    local Camera = workspace.CurrentCamera
    if Camera then Camera.FieldOfView = 70 end
end

return Visuals
