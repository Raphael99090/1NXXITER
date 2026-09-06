local Visuals = {}
local RunService = game:GetService("RunService")

Visuals.Settings = { StretchedEnabled = false, FOVValue = 100 }
Visuals._conn = nil

function Visuals:ToggleStretched(v)
    self.Settings.StretchedEnabled = v
    if v then
        -- Aplica imediatamente
        local Camera = workspace.CurrentCamera
        if Camera then Camera.FieldOfView = self.Settings.FOVValue end

        -- Conecta só quando ativa — mantém o FOV mesmo se o jogo tentar
        -- mudar (cutscene, respawn especial, etc.)
        if not self._conn then
            self._conn = RunService.RenderStepped:Connect(function()
                if Visuals.Settings.StretchedEnabled then
                    local cam = workspace.CurrentCamera
                    if cam then cam.FieldOfView = Visuals.Settings.FOVValue end
                end
            end)
        end
    else
        -- Desconecta quando desativa (não roda callback à toa)
        if self._conn then self._conn:Disconnect() self._conn = nil end
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

function Visuals:Unload()
    self.Settings.StretchedEnabled = false
    if self._conn then self._conn:Disconnect() self._conn = nil end
    local Camera = workspace.CurrentCamera
    if Camera then Camera.FieldOfView = 70 end
end

return Visuals
