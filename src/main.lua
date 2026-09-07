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
-- [1.5] PANDA KEY SYSTEM (PUSL-V4 HTTP)
-- ======================================================
-- Validação de key 100% server-side usando a API do Panda Auth
-- (pandadevelopment.net). Funciona assim:
--   1) Usuário vai na GetKey page e completa os checkpoints
--   2) Recebe uma key travada no HWID dele
--   3) Cola a key no Hub → o loader valida na API do Panda
--   4) Panda retorna "Valid" ou erro → Hub carrega ou não
--
-- ⚠️ TROQUE o PANDA_SERVICE_ID pelo identificador do seu serviço
--    que você criou no painel do Panda (pandadevelopment.net/dashboard)
--
-- Vantagens sobre o sistema antigo (keys.json no GitHub):
--   - Validação server-side (ninguém pode ler keys do JSON)
--   - HWID travado automaticamente pelo Panda
--   - Monetização integrada (Linkvertise, LootLabs, etc.)
--   - Dashboard com analytics de execuções
--   - Sem precisar manter SHA-256 em Lua puro

-- ══════════════════════════════════════════════════════
-- CONFIGURAÇÃO DO PANDA KEY SYSTEM
-- ══════════════════════════════════════════════════════

-- 🔑 Identificador do seu serviço no Panda
-- Pegue esse ID em: pandadevelopment.net/dashboard → seu serviço → Settings
local PANDA_SERVICE_ID = "1nxxiter"

-- 🔗 URL da página GetKey do Panda (onde o usuário pega a key)
-- O HWID é adicionado automaticamente pelo loader
local PANDA_GETKEY_BASE = "https://ads.pandauth.com/getkey/" .. PANDA_SERVICE_ID

-- 🌐 URL base da API do Panda (PUSL-V4)
local PANDA_API_BASE = "https://api.pandadevelopment.net"

-- ======================================================
-- 🧪 MODO DE TESTE — REMOVA ANTES DE PUBLICAR
-- ======================================================
local TESTING_MODE = false
local TEST_KEY = "TESTE-1NX"

if TESTING_MODE then
    warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '" .. TEST_KEY .. "' libera sem checar o Panda. Desliga TESTING_MODE antes de publicar!")
end

-- ======================================================
-- HWID
-- ======================================================
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

-- ======================================================
-- VALIDAÇÃO VIA PANDA API (PUSL-V4 HTTP)
-- ======================================================
-- Chama a API do Panda pra validar a key server-side.
-- O Panda checa: key existe? está ativa? HWID bate?
-- Tudo feito no servidor deles — nada de JSON público.
local function ValidatePandaKey(key, hwid, callback)
    local HttpService = game:GetService("HttpService")

    -- Monta a URL de validação (PUSL-V4)
    -- Endpoint: GET /validate?identifier=<id>&key=<key>&hwid=<hwid>
    local validateUrl = PANDA_API_BASE .. "/validate"
        .. "?identifier=" .. HttpService:UrlEncode(PANDA_SERVICE_ID)
        .. "&key=" .. HttpService:UrlEncode(key)
        .. "&hwid=" .. HttpService:UrlEncode(hwid)

    print("🔑 [1NXITER]: Validando key no Panda...")

    local ok, response = pcall(function()
        return game:HttpGet(validateUrl)
    end)

    if not ok or not response then
        callback(false, "Erro de conexão com o Panda.\nVerifique sua internet.")
        return
    end

    -- Tenta decodificar a resposta JSON do Panda
    local decOk, data = pcall(function()
        return HttpService:JSONDecode(response)
    end)

    if not decOk or not data then
        -- Algumas respostas do Panda podem vir como texto puro
        if response:lower():find("valid") then
            callback(true)
        else
            callback(false, "Resposta inesperada do servidor.\nTente novamente.")
        end
        return
    end

    -- Checa o status retornado pela API do Panda
    -- Respostas possíveis:
    --   { "status": "Valid" }           → Key válida
    --   { "status": "Invalid" }         → Key não existe
    --   { "status": "Expired" }         → Key expirada
    --   { "status": "HWID_Mismatch" }   → Key vinculada a outro dispositivo
    --   { "status": "Revoked" }         → Key revogada pelo admin
    local status = data.status or data.Status or ""

    if status:lower() == "valid" or status:lower() == "validated" then
        print("✅ [1NXITER]: Key validada pelo Panda!")
        callback(true)
    elseif status:lower() == "invalid" then
        callback(false, "Key inválida. Pegue uma nova no GetKey.")
    elseif status:lower() == "expired" then
        callback(false, "Sua key expirou.\nPegue uma nova no GetKey.")
    elseif status:lower() == "hwid_mismatch" or status:lower() == "hwid mismatch" then
        callback(false, "Key vinculada a outro dispositivo.\nPeça reset de HWID ao admin.")
    elseif status:lower() == "revoked" then
        callback(false, "Essa key foi revogada pelo admin.")
    else
        -- Erro genérico ou mensagem personalizada do Panda
        local msg = data.message or data.error or data.msg or "Key recusada pelo servidor."
        callback(false, tostring(msg))
    end
end

-- ======================================================
-- CHECAGEM UNIFICADA (teste → Panda)
-- ======================================================
local function CheckKey(key, callback)
    -- 1) Modo de teste (só funciona com TESTING_MODE = true)
    if TESTING_MODE then
        if key == TEST_KEY then
            callback(true)
            return
        end
    end

    -- 2) Validação via Panda Key System (server-side)
    ValidatePandaKey(key, GetHWID(), callback)
end

-- ======================================================
-- INTERFACE DA KEY GATE
-- ======================================================
local function RequestKey(onSuccess)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
    local hwid = GetHWID()

    local KeyGui = Instance.new("ScreenGui")
    KeyGui.Name = "InxiterKeyGate"
    KeyGui.ResetOnSpawn = false
    KeyGui.IgnoreGuiInset = true
    KeyGui.Parent = PlayerGui

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 320, 0, 280)
    Frame.Position = UDim2.new(0.5, -160, 0.5, -140)
    Frame.BackgroundColor3 = Color3.fromRGB(25, 15, 35)
    Frame.BorderSizePixel = 0
    Frame.Parent = KeyGui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = UDim.new(0, 12)
    Corner.Parent = Frame

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 36)
    Title.BackgroundTransparency = 1
    Title.Text = "🔑 1NXITER HUB"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextColor3 = Color3.new(1, 1, 1)
    Title.Parent = Frame

    -- Input da key
    local Input = Instance.new("TextBox")
    Input.Size = UDim2.new(1, -30, 0, 34)
    Input.Position = UDim2.new(0, 15, 0, 42)
    Input.BackgroundColor3 = Color3.fromRGB(40, 25, 55)
    Input.TextColor3 = Color3.new(1, 1, 1)
    Input.PlaceholderText = "Cole sua key aqui..."
    Input.Text = ""
    Input.ClearTextOnFocus = false
    Input.Font = Enum.Font.Gotham
    Input.TextSize = 14
    Input.Parent = Frame
    Instance.new("UICorner", Input).CornerRadius = UDim.new(0, 6)

    -- Botão Confirmar
    local Confirm = Instance.new("TextButton")
    Confirm.Size = UDim2.new(1, -30, 0, 34)
    Confirm.Position = UDim2.new(0, 15, 0, 84)
    Confirm.BackgroundColor3 = Color3.fromRGB(120, 60, 200)
    Confirm.Text = "Confirmar"
    Confirm.Font = Enum.Font.GothamBold
    Confirm.TextSize = 14
    Confirm.TextColor3 = Color3.new(1, 1, 1)
    Confirm.Parent = Frame
    Instance.new("UICorner", Confirm).CornerRadius = UDim.new(0, 6)

    -- Botão Obter Key (abre Panda GetKey)
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(1, -30, 0, 30)
    GetKeyBtn.Position = UDim2.new(0, 15, 0, 124)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
    GetKeyBtn.Text = "🔗 OBTER KEY (Panda)"
    GetKeyBtn.Font = Enum.Font.GothamBold
    GetKeyBtn.TextSize = 12
    GetKeyBtn.TextColor3 = Color3.fromRGB(180, 140, 255)
    GetKeyBtn.Parent = Frame
    Instance.new("UICorner", GetKeyBtn).CornerRadius = UDim.new(0, 6)

    -- HWID display
    local HwidLabel = Instance.new("TextLabel")
    HwidLabel.Size = UDim2.new(1, -80, 0, 24)
    HwidLabel.Position = UDim2.new(0, 15, 0, 164)
    HwidLabel.BackgroundTransparency = 1
    HwidLabel.Text = "HWID: " .. string.sub(hwid, 1, 22) .. (string.len(hwid) > 22 and "..." or "")
    HwidLabel.Font = Enum.Font.Code
    HwidLabel.TextSize = 10
    HwidLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
    HwidLabel.TextXAlignment = Enum.TextXAlignment.Left
    HwidLabel.Parent = Frame

    -- Botão Copiar HWID
    local CopyHwid = Instance.new("TextButton")
    CopyHwid.Size = UDim2.new(0, 55, 0, 20)
    CopyHwid.Position = UDim2.new(1, -70, 0, 166)
    CopyHwid.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
    CopyHwid.Text = "Copiar"
    CopyHwid.Font = Enum.Font.Gotham
    CopyHwid.TextSize = 10
    CopyHwid.TextColor3 = Color3.fromRGB(180, 140, 255)
    CopyHwid.Parent = Frame
    Instance.new("UICorner", CopyHwid).CornerRadius = UDim.new(0, 4)

    -- Label de erro
    local ErrorLabel = Instance.new("TextLabel")
    ErrorLabel.Size = UDim2.new(1, -30, 0, 40)
    ErrorLabel.Position = UDim2.new(0, 15, 0, 192)
    ErrorLabel.BackgroundTransparency = 1
    ErrorLabel.Text = ""
    ErrorLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
    ErrorLabel.Font = Enum.Font.Gotham
    ErrorLabel.TextSize = 11
    ErrorLabel.TextWrapped = true
    ErrorLabel.TextYAlignment = Enum.TextYAlignment.Top
    ErrorLabel.Parent = Frame

    -- Info extra
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -30, 0, 20)
    InfoLabel.Position = UDim2.new(0, 15, 1, -26)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "Panda Key System · pandadevelopment.net"
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 10
    InfoLabel.TextColor3 = Color3.fromRGB(80, 80, 80)
    InfoLabel.Parent = Frame

    -- ══════════════════════════════════════════
    -- EVENTOS
    -- ══════════════════════════════════════════
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

    -- Obter Key: copia o link do Panda GetKey (com HWID pra travar a key)
    GetKeyBtn.MouseButton1Click:Connect(function()
        local pandaUrl = PANDA_GETKEY_BASE .. "?hwid=" .. hwid
        local copier = setclipboard or toclipboard
        if type(copier) == "function" then
            pcall(copier, pandaUrl)
            ErrorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            ErrorLabel.Text = "Link copiado! Cole no navegador."
        else
            ErrorLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
            ErrorLabel.Text = "Abra: " .. pandaUrl
        end
        task.delay(4, function()
            ErrorLabel.TextColor3 = Color3.fromRGB(255, 90, 90)
            ErrorLabel.Text = ""
        end)
    end)

    -- Copiar HWID
    CopyHwid.MouseButton1Click:Connect(function()
        local copier = setclipboard or toclipboard
        if type(copier) == "function" then
            pcall(copier, hwid)
            CopyHwid.Text = "✅"
            task.delay(2, function() CopyHwid.Text = "Copiar" end)
        end
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

    -- Desconecta Utils (Anti-AFK, Auto-Rejoin, etc.) — antes essas
    -- conexões sobreviviam ao "FECHAR HUB" e ficavam rodando em segundo plano.
    if self.Core.Utils and self.Core.Utils.StopAll then
        pcall(function() self.Core.Utils:StopAll() end)
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
