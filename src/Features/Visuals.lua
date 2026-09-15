local Visuals = {}
local RunService = game:GetService("RunService")

Visuals.Settings = { CustomFOVEnabled = false, FOVValue = 100 }
Visuals._conn = nil
Visuals._originalFOV = nil -- capturado na 1ª ativação, restaurado ao desligar (não hardcoded 70)

local function GetCamera()
    return workspace.CurrentCamera
end

function Visuals:ToggleCustomFOV(v)
    self.Settings.CustomFOVEnabled = v
    local Camera = GetCamera()

    if v then
        if self._originalFOV == nil and Camera then
            self._originalFOV = Camera.FieldOfView -- guarda o FOV real do jogo antes de mexer
        end
        if Camera then Camera.FieldOfView = self.Settings.FOVValue end

        if not self._conn then
            self._conn = RunService.RenderStepped:Connect(function()
                if Visuals.Settings.CustomFOVEnabled then
                    local cam = GetCamera()
                    if cam then cam.FieldOfView = Visuals.Settings.FOVValue end
                end
            end)
        end
    else
        if self._conn then self._conn:Disconnect(); self._conn = nil end
        if Camera and self._originalFOV then Camera.FieldOfView = self._originalFOV end
        self._originalFOV = nil
    end
end

function Visuals:UpdateFOV(v)
    self.Settings.FOVValue = v
    if self.Settings.CustomFOVEnabled then
        local Camera = GetCamera()
        if Camera then Camera.FieldOfView = v end
    end
end

function Visuals:Unload()
    local Camera = GetCamera()
    if self._conn then self._conn:Disconnect(); self._conn = nil end
    if Camera and self.Settings.CustomFOVEnabled and self._originalFOV then
        Camera.FieldOfView = self._originalFOV
    end
    self.Settings.CustomFOVEnabled = false
    self._originalFOV = nil
end

return Visuals
