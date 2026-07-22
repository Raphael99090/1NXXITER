
local Utils = {}
Utils._connections = {}

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

function Utils:AntiAFK()
    if self._connections["AntiAFK"] then return end
    self._connections["AntiAFK"] = Player.Idled:Connect(function()
        VirtualUser:CaptureController()
        VirtualUser:ClickButton2(Vector2.new())
    end)
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

function Utils:AntiLag()
    settings().Rendering.QualityLevel = 1
    Lighting.GlobalShadows = false
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("BasePart") then
            v.Material = Enum.Material.SmoothPlastic
            v.Reflectance = 0
        elseif v:IsA("Decal") or v:IsA("Texture") then
            v.Transparency = 1
        elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
            v.Enabled = false
        end
    end
end

function Utils:StopAll()
    for _, c in pairs(self._connections) do c:Disconnect() end
    self._connections = {}
end

return Utils
