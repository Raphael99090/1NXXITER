local Visuals = {}
local Camera = workspace.CurrentCamera

Visuals.Settings = { StretchedEnabled = false, FOVValue = 100 }

function Visuals:ToggleStretched(v)
    self.Settings.StretchedEnabled = v
    if not v then Camera.FieldOfView = 70 end
end

function Visuals:UpdateFOV(v)
    self.Settings.FOVValue = v
    if self.Settings.StretchedEnabled then
        Camera.FieldOfView = v
    end
end

-- Mantém o FOV mesmo se o jogo tentar mudar
game:GetService("RunService").RenderStepped:Connect(function()
    if Visuals.Settings.StretchedEnabled then
        Camera.FieldOfView = Visuals.Settings.FOVValue
    end
end)

return Visuals
