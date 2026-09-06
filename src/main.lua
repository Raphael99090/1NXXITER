--[[
    1NXITER HUB | Versão 3.0 (Modular SRC)
    Desenvolvedor: Raphael99090
    Repositório: 1NXXITER
]]

-- [1] SEGURANÇA: Evita duas instâncias rodando ao mesmo tempo.
-- Antes disso só abortava com um warn — mas em teste/hot-reload isso deixava
-- a instância antiga (aimbot, noclip, FOV esticado, etc.) rodando pra sempre
-- em paralelo com a nova. Agora ele desliga a antiga de verdade primeiro.
if getgenv().InxiterHubLoaded and getgenv().InxiterHubInstance then
    warn("♻️ [1NXITER]: Instância anterior detectada — desligando antes de recarregar...")
    local ok, err = pcall(function()
        getgenv().InxiterHubInstance:Unload()
    end)
    if not ok then
        warn("⚠️ [1NXITER]: Erro ao desligar instância anterior -> " .. tostring(err))
    end
    getgenv().InxiterHubLoaded = false
    getgenv().InxiterHubInstance = nil
end

-- [2] CONFIGURAÇÃO DE LINKS
local REPO = "Raphael99090/1NXXITER"
local BRANCH = "main"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/src/"

-- ======================================================
-- [1.5] SISTEMA DE KEY (via site — /api/validate)
-- ======================================================
-- Troca a key fixa por checagem real contra o site de vendas. O HWID vai
-- junto: o servidor vincula automaticamente no primeiro uso e recusa se
-- um HWID diferente tentar usar a mesma key depois (até resetar no painel).
--
-- ⚠️ TROQUE ESSA URL pelo domínio real onde o site (1nxiter-site) estiver
-- hospedado, com HTTPS — a maioria dos executores recusa HTTP puro.
local VALIDATE_URL = "https://SEU-DOMINIO-AQUI/api/validate"

-- ======================================================
-- 🧪 MODO DE TESTE — REMOVA ANTES DE PUBLICAR
-- ======================================================
-- Enquanto o site não tá no ar (VALIDATE_URL ainda é o placeholder), isso
-- deixa testar o resto do hub sem precisar bater no servidor de verdade.
-- Com TESTING_MODE = true, qualquer key igual a TEST_KEY passa direto,
-- sem gastar request nem precisar do site rodando.
--
-- MUDE PRA false (ou apague esse bloco inteiro) antes de mandar o script
-- pros seus compradores — com isso ligado, QUALQUER PESSOA que descobrir
-- o TEST_KEY entra de graça, sem pagar e sem key de verdade.
local TESTING_MODE = true
local TEST_KEY = "TESTE-1NX"

if TESTING_MODE then
    warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '" .. TEST_KEY .. "' libera sem checar o site. Desliga TESTING_MODE antes de publicar!")
end

local function GetHWID()
    local ok, id = pcall(function()
        if gethwid then return gethwid() end
        if get_hwid then return get_hwid() end
        if identifyexecutor then
            local name = identifyexecutor()
            return "id-" .. tostring(name) .. "-" .. tostring(game:GetService("RbxAnalyticsService"):GetClientId())
        end
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    return ok and tostring(id) or "unknown-hwid"
end

local function CheckKey(key, callback)
    if TESTING_MODE then
        if key == TEST_KEY then
            callback(true)
        else
            callback(false, "Key inválida. (Modo de teste: use \"" .. TEST_KEY .. "\")")
        end
        return
    end

    local httpRequest = (syn and syn.request) or http_request or request
    if not httpRequest then
        callback(false, "Seu executor não suporta requisições HTTP (precisa de http_request/syn.request).")
        return
    end
    local ok, response = pcall(function()
        return httpRequest({
            Url = VALIDATE_URL,
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = game:GetService("HttpService"):JSONEncode({ key = key, hwid = GetHWID() }),
        })
    end)
    if not ok or not response or not response.Body then
        callback(false, "Não deu pra falar com o servidor. Confere sua internet e tenta de novo.")
        return
    end
    local decodeOk, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(response.Body)
    end)
    if not decodeOk or type(data) ~= "table" then
        callback(false, "Resposta inválida do servidor.")
        return
    end
    if data.valid then
        callback(true)
    else
        -- Mensagens amigáveis por reason — o site nunca manda detalhe
        -- técnico demais de propósito (evita virar guia de bypass).
        local reasons = {
            key_invalid = "Key inválida.",
            expired = "Sua key expirou. Renove no site.",
            revoked = "Essa key foi revogada.",
            hwid_missing = "Não foi possível identificar seu dispositivo (HWID).",
            hwid_mismatch = "Essa key já está vinculada a outro dispositivo. Resete o HWID no seu painel do site.",
            rate_limited = "Muitas tentativas seguidas. Espera um minuto e tenta de novo.",
        }
        callback(false, reasons[data.reason] or "Key inválida.")
    end
end

local function RequestKey(onSuccess)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "InxiterKeyGate"
    KeyGui.ResetOnSpawn = false
    KeyGui.IgnoreGuiInset = true
    KeyGui.Parent = PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 300, 0, 160)
    Frame.Position = UDim2.new(0.5, -150, 0.5, -80)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = KeyGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 10)
    Corner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundTransparency = 1
    Title.Text = "1NXITER HUB — Digite a Key"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Parent = Frame

    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -30, 0, 36)
    Input.Position = UDim2.new(0, 15, 0, 50)
    Input.BackgroundColor3 = Color3.fromRGB(40, 25, 55)
    Input.TextColor3 = Color3.new(1, 1, 1)
    Input.PlaceholderText = "Cole sua key aqui..."
    Input.Text = ""
    Input.ClearTextOnFocus = false
    Input.Font = Enum.Font.Gotham
    Input.TextSize = 14
    Input.Parent = Frame

    local InputCorner = Instance.new("UICorner")
    InputCorner.CornerRadius = UDim.new(0, 6)
    InputCorner.Parent = Input

    local Confirm = Instance.new("TextButton")
    Confirm.Size = UDim2.new(1, -30, 0, 36)
    Confirm.Position = UDim2.new(0, 15, 0, 96)
    Confirm.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
    Confirm.Text = "Confirmar"
    Confirm.Font = Enum.Font.GothamBold
    Confirm.TextSize = 14
    Confirm.TextColor3 = Color3.new(1, 1, 1)
    Confirm.Parent = Frame

    local ConfirmCorner = Instance.new("UICorner")
    ConfirmCorner.CornerRadius = UDim.new(0, 6)
    ConfirmCorner.Parent = Confirm

    local ErrorLabel = Instance.new("TextLabel")
    ErrorLabel.Size = UDim2.new(1, -30, 0, 18)
    ErrorLabel.Position = UDim2.new(0, 15, 1, -22)
    ErrorLabel.BackgroundTransparency = 1
    ErrorLabel.Text = ""
    ErrorLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
    ErrorLabel.Font = Enum.Font.Gotham
    ErrorLabel.TextSize = 12
    ErrorLabel.Parent = Frame

    -- Trava o botão + input durante a checagem, pra não disparar duas
    -- requisições em paralelo se o jogador clicar/apertar Enter rápido.
    local checking = false

    local function TryKey()
        if checking then return end
        local keyText = Input.Text
        if keyText == "" then
            ErrorLabel.Text = "Cola sua key aí antes de confirmar."
            return
        end

        checking = true
        Confirm.Text = "Verificando..."
        ErrorLabel.Text = ""

        CheckKey(keyText, function(valid, errorMsg)
            checking = false
            if valid then
                KeyGui:Destroy()
                onSuccess()
            else
                Confirm.Text = "Confirmar"
                ErrorLabel.Text = errorMsg or "Key inválida. Tenta de novo."
                Input.Text = ""
            end
        end)
    end

    Confirm.MouseButton1Click:Connect(TryKey)
    Input.FocusLost:Connect(function(enterPressed)
        if enterPressed then TryKey() end
    end)
end

-- [3] ESTRUTURA CENTRAL (Tabela Hub)
-- Todos os módulos serão injetados aqui dentro
local Hub = {
    Core = {},
    Features = {},
    UI = {
        Tabs = {}
    }
}

-- Desliga tudo: todas as features com Unload() e a UI (janela).
-- Usado no hot-reload acima e no botão "FECHAR HUB" do SystemTab.
-- A WindUI:Destroy() já cuida da janela E do botão flutuante (OpenButton)
-- juntos — não existe mais um MinimizeGui separado pra destruir à parte
-- como existia com o hack de bolinha customizada da Fluent.
function Hub:Unload()
    for name, feature in pairs(self.Features) do
        if type(feature) == "table" and feature.Unload then
            local ok, err = pcall(function() feature:Unload() end)
            if not ok then
                warn("⚠️ [1NXITER]: Erro ao descarregar Features/" .. name .. " -> " .. tostring(err))
            end
        end
    end

    if self.UI.Window and self.UI.Window.Destroy then
        pcall(function() self.UI.Window:Destroy() end)
    end
end

-- [4] FUNÇÃO IMPORT (O coração do Loader)
-- Esta função baixa o código do GitHub, compila e retorna o módulo
local function Import(path)
    local url = BASE_URL .. path .. ".lua"
    
    -- Print no console para você acompanhar o carregamento (F9)
    print("📥 [1NXITER]: Carregando -> " .. path)
    
    local success, code = pcall(function()
        -- O math.random evita que o Roblox use uma versão "cacheada" (antiga) do arquivo
        return game:HttpGet(url .. "?cache=" .. math.random(1, 999999))
    end)

    if success and code and not code:match("^404") then
        local func, err = loadstring(code)
        if func then
            local runSuccess, result = pcall(func)
            if runSuccess then
                return result -- Retorna o conteúdo do módulo (return ESP, etc)
            else
                warn("❌ [1NXITER]: Erro ao executar módulo (" .. path .. "): " .. tostring(result))
            end
        else
            warn("❌ [1NXITER]: Erro de sintaxe em (" .. path .. "): " .. tostring(err))
        end
    else
        warn("❌ [1NXITER]: Arquivo não encontrado ou erro de rede (404) -> " .. url)
    end
    return nil
end

-- ======================================================
-- [5] ORDEM DE CARREGAMENTO (ETAPAS)
-- ======================================================
local function LoadHub()

-- ETAPA 1: Carregar Core (Essencial para o Hub existir)
Hub.Core.Utils = Import("Core/Utils")
Hub.Core.State = Import("Core/State")

-- ETAPA 2: Carregar Features (As funções de hack)
local featuresList = {
    "AutoTrain", "Aimbot", "ESP", "PlayerMods", "FreeCam", "SpyChat", "Visuals"
}
for _, f in pairs(featuresList) do
    Hub.Features[f] = Import("Features/" .. f)
end

-- ETAPA 3: Carregar Tabs (O conteúdo de cada aba da UI)
local tabsList = {
    "TrainTab", "CombatTab", "ESPTab", "MovementTab", "CameraTab", "SystemTab"
}
for _, t in pairs(tabsList) do
    Hub.UI.Tabs[t] = Import("Interface/Tabs/" .. t)
end

-- ETAPA 4: Carregar Interface Main (O montador da janela)
Hub.UI.Main = Import("Interface/Main")

-- ======================================================
-- [6] INICIALIZAÇÃO FINAL
-- ======================================================
local function Start()
    -- Verificação de Integridade: Se State ou Main falharem, o script para.
    if not Hub.Core.State or not Hub.UI.Main then
        return warn("❌ [1NXITER]: Falha crítica. Verifique se as pastas e nomes no GitHub estão corretos.")
    end

    print("✅ [1NXITER]: Todos os módulos carregados. Iniciando sistema...")
    
    -- Marca o Hub como carregado e guarda a instância pra um futuro
    -- reload conseguir chamar Hub:Unload() nela antes de subir a nova.
    getgenv().InxiterHubLoaded = true
    getgenv().InxiterHubInstance = Hub

    -- Carrega as configurações salvas no JSON do celular
    local Config = Hub.Core.State:LoadConfig()
    local RuntimeState = Hub.Core.State:GetRuntimeState()

    -- Salva sozinho em segundo plano (respeita Config.AutoSave)
    Hub.Core.State:StartAutoSave(Config, 8)

    -- Inicia funções de fundo (Anti-AFK, Auto-Rejoin, etc)
    if Hub.Core.Utils then
        Hub.Core.Utils:AntiAFK(RuntimeState)
        Hub.Core.Utils:AutoRejoin(Config)
    end

    -- Liga a Interface e desenha as abas
    Hub.UI.Main:Load(Hub, Config, RuntimeState)
end

-- Executa a inicialização de forma protegida
local finalSuccess, finalErr = pcall(Start)

if not finalSuccess then
    getgenv().InxiterHubLoaded = false
    warn("❌ [1NXITER]: Erro fatal durante a inicialização -> " .. tostring(finalErr))
end

end

-- Só carrega o hub inteiro depois da key certa (evita gastar
-- requests no GitHub se a key estiver errada)
RequestKey(LoadHub)
