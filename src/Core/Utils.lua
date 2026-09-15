
-- Anti-Lag reversível: guarda os valores originais de cada instância
-- antes de mexer, pra dar pra restaurar depois — antes disso era uma
-- alteração destrutiva sem volta na sessão inteira.
local Utils = {}
Utils._connections = {}
Utils._antiLagBackup = nil

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local Lighting = game:GetService("Lighting")

local Player = Players.LocalPlayer

-- ======================================================
-- NÚMEROS PARA TEXTO (PT-BR)
-- ======================================================
local UNIDADES = {"ZERO", "UM", "DOIS", "TRÊS", "QUATRO", "CINCO", "SEIS", "SETE", "OITO", "NOVE"}
local ESPECIAIS = {"DEZ", "ONZE", "DOZE", "TREZE", "QUATORZE", "QUINZE", "DEZESSEIS", "DEZESSETE", "DEZOITO", "DEZENOVE"}
local DEZENAS = {"", "", "VINTE", "TRINTA", "QUARENTA", "CINQUENTA", "SESSENTA", "SETENTA", "OITENTA", "NOVENTA"}
local CENTENAS = {"", "CENTO", "DUZENTOS", "TREZENTOS", "QUATROCENTOS", "QUINHENTOS", "SEISCENTOS", "SETECENTOS", "OITOCENTOS", "NOVECENTOS"}

function Utils:NumberToText(n)
    n = math.floor(tonumber(n) or 0)
    if n == 0 then return UNIDADES[1] end
    if n > 9999 then return tostring(n) end

    local function parse(num)
        if num == 0 then return "" end
        if num == 100 then return "CEM" end
        local partes = {}
        local c = math.floor(num / 100)
        local resto = num % 100
        if c > 0 then table.insert(partes, CENTENAS[c + 1]) end
        if resto > 0 then
            if resto >= 10 and resto <= 19 then
                table.insert(partes, ESPECIAIS[resto - 9])
            else
                local d = math.floor(resto / 10)
                local u = resto % 10
                if d >= 2 then table.insert(partes, DEZENAS[d + 1]) end
                if u > 0 then table.insert(partes, UNIDADES[u + 1]) end
            end
        end
        return table.concat(partes, " E ")
    end

    if n >= 1000 then
        local milhar = math.floor(n / 1000)
        local resto = n % 1000
        local txtMilhar = (milhar == 1) and "MIL" or (parse(milhar) .. " MIL")
        if resto > 0 then
            local sep = (resto < 100 or resto % 100 == 0) and " E " or " "
            return txtMilhar .. sep .. parse(resto)
        end
        return txtMilhar
    end
    return parse(n)
end

-- ======================================================
-- SISTEMA E CONEXÕES
-- ======================================================

function Utils:ToggleAntiAFK(state)
    if state then
        if self._connections["AntiAFK"] then return end
        self._connections["AntiAFK"] = Player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    else
        if self._connections["AntiAFK"] then
            self._connections["AntiAFK"]:Disconnect()
            self._connections["AntiAFK"] = nil
        end
    end
end

function Utils:AutoRejoin(Config)
    if self._connections["AutoRejoin"] then self._connections["AutoRejoin"]:Disconnect() end
    self._connections["AutoRejoin"] = GuiService.ErrorMessageChanged:Connect(function()
        if Config.AutoRejoin then
            task.wait(5)
            self:Rejoin()
        end
    end)
end

function Utils:Rejoin()
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(game.PlaceId, Player)
    else
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, Player)
    end
end

function Utils:ServerHop()
    local Api = "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Desc&limit=100"
    local success, result = pcall(function()
        local raw = game:HttpGet(Api)
        local data = game:GetService("HttpService"):JSONDecode(raw)
        for _, s in pairs(data.data) do
            if s.playing < s.maxPlayers and s.id ~= game.JobId then
                TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, Player)
                return
            end
        end
    end)
    if not success then TeleportService:Teleport(game.PlaceId, Player) end
end

function Utils:ToggleAntiLag(state)
    if state then
        if self._antiLagBackup then return end -- já ativo, não sobrescreve o backup

        local backup = { parts = {}, decals = {}, particles = {}, effects = {}, lighting = {} }

        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain then
            backup.terrain = {
                WaterWaveSize = Terrain.WaterWaveSize,
                WaterWaveSpeed = Terrain.WaterWaveSpeed,
                WaterReflectance = Terrain.WaterReflectance,
                WaterTransparency = Terrain.WaterTransparency,
            }
            Terrain.WaterWaveSize = 0
            Terrain.WaterWaveSpeed = 0
            Terrain.WaterReflectance = 0
            Terrain.WaterTransparency = 0
            pcall(function() sethiddenproperty(Terrain, "Decoration", false) end)
        end

        backup.lighting = {
            GlobalShadows = Lighting.GlobalShadows,
            FogEnd = Lighting.FogEnd,
            Brightness = Lighting.Brightness,
        }
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 9e9
        Lighting.Brightness = 2

        for _, v in pairs(Lighting:GetDescendants()) do
            if v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("ColorCorrectionEffect") or v:IsA("BloomEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("Atmosphere") then
                backup.effects[v] = v.Enabled
                v.Enabled = false
            end
        end

        backup.qualityLevel = settings().Rendering.QualityLevel
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01

        for _, v in pairs(workspace:GetDescendants()) do
            if v:IsA("BasePart") then
                backup.parts[v] = { Material = v.Material, Reflectance = v.Reflectance, CastShadow = v.CastShadow }
                v.Material = Enum.Material.SmoothPlastic
                v.Reflectance = 0
                v.CastShadow = false
            elseif v:IsA("Decal") or v:IsA("Texture") then
                backup.decals[v] = v.Transparency
                v.Transparency = 1
            elseif v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then
                backup.particles[v] = v.Enabled
                v.Enabled = false
            end
        end

        self._antiLagBackup = backup
    else
        local backup = self._antiLagBackup
        if not backup then return end

        local Terrain = workspace:FindFirstChildOfClass("Terrain")
        if Terrain and backup.terrain then
            for prop, val in pairs(backup.terrain) do pcall(function() Terrain[prop] = val end) end
        end

        for prop, val in pairs(backup.lighting) do pcall(function() Lighting[prop] = val end) end
        if backup.qualityLevel then pcall(function() settings().Rendering.QualityLevel = backup.qualityLevel end) end

        for inst, wasEnabled in pairs(backup.effects) do
            if inst and inst.Parent then pcall(function() inst.Enabled = wasEnabled end) end
        end
        for inst, props in pairs(backup.parts) do
            if inst and inst.Parent then
                pcall(function()
                    inst.Material = props.Material
                    inst.Reflectance = props.Reflectance
                    inst.CastShadow = props.CastShadow
                end)
            end
        end
        for inst, transp in pairs(backup.decals) do
            if inst and inst.Parent then pcall(function() inst.Transparency = transp end) end
        end
        for inst, wasEnabled in pairs(backup.particles) do
            if inst and inst.Parent then pcall(function() inst.Enabled = wasEnabled end) end
        end

        self._antiLagBackup = nil
    end
end

function Utils:IsAntiLagActive()
    return self._antiLagBackup ~= nil
end

function Utils:StopAll()
    for _, c in pairs(self._connections) do c:Disconnect() end
    self._connections = {}
    if self._antiLagBackup then self:ToggleAntiLag(false) end -- devolve o visual original ao fechar o hub
end

return Utils
