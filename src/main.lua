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
-- [1.5] SISTEMA DE KEY (Linkvertise + Keys Premium)
-- ======================================================
-- Dois modos de acesso:
--   1) KEY GRÁTIS (Linkvertise): muda todo dia, gerada por algoritmo
--      compartilhado entre a página getkey/ e este loader.
--   2) KEY PREMIUM: cadastrada pelo admin no painel (docs/admin/),
--      salva em keys.json no GitHub — suporta HWID e expiração.
--
-- keys.json guarda o HASH (SHA-256) da key, não a key crua — esse
-- arquivo é público (GitHub Pages/raw), então guardar a key em texto
-- puro deixaria qualquer um ler o JSON e roubar a lista inteira de
-- keys vendidas. O painel admin (docs/admin/) já faz esse hash antes
-- de salvar — se você tiver keys antigas salvas em texto puro de uma
-- versão anterior, precisa recriá-las pelo painel novo.
--
-- ⚠️ TROQUE essas URLs pelo domínio real quando subir no GitHub Pages:

-- URL do keys.json cru (raw) no repositório
local KEYS_URL = "https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/docs/keys.json"

-- URL do Linkvertise que leva à página getkey/
-- Crie em: linkvertise.com → New Link → cole a URL do GitHub Pages
-- (ex: https://raphael99090.github.io/1NXXITER/getkey/)
local LINKVERTISE_URL = "https://linkvertise.com/SEU_ID_AQUI"

-- ======================================================
-- SHA-256 (Lua puro, sem libs externas)
-- ======================================================
-- Usado só pra bater o hash das keys premium com o que o painel admin
-- salva no keys.json. Antes, keys.json guardava a KEY CRUA como índice
-- do JSON — como esse arquivo é público no GitHub, qualquer um que
-- abrisse a página conseguia ver a lista inteira de keys vendidas e
-- copiar. Agora só o HASH fica no JSON: dá pra confirmar que uma key
-- digitada bate com uma vendida, mas ninguém consegue ler o JSON e
-- descobrir uma key alheia (hash é via de mão única).
local SHA256
do
    local band, bor, bxor, bnot = bit32.band, bit32.bor, bit32.bxor, bit32.bnot
    local rrotate, rshift, lshift = bit32.rrotate, bit32.rshift, bit32.lshift

    local K = {
        0x428a2f98,0x71374491,0xb5c0fbcf,0xe9b5dba5,0x3956c25b,0x59f111f1,0x923f82a4,0xab1c5ed5,
        0xd807aa98,0x12835b01,0x243185be,0x550c7dc3,0x72be5d74,0x80deb1fe,0x9bdc06a7,0xc19bf174,
        0xe49b69c1,0xefbe4786,0x0fc19dc6,0x240ca1cc,0x2de92c6f,0x4a7484aa,0x5cb0a9dc,0x76f988da,
        0x983e5152,0xa831c66d,0xb00327c8,0xbf597fc7,0xc6e00bf3,0xd5a79147,0x06ca6351,0x14292967,
        0x27b70a85,0x2e1b2138,0x4d2c6dfc,0x53380d13,0x650a7354,0x766a0abb,0x81c2c92e,0x92722c85,
        0xa2bfe8a1,0xa81a664b,0xc24b8b70,0xc76c51a3,0xd192e819,0xd6990624,0xf40e3585,0x106aa070,
        0x19a4c116,0x1e376c08,0x2748774c,0x34b0bcb5,0x391c0cb3,0x4ed8aa4a,0x5b9cca4f,0x682e6ff3,
        0x748f82ee,0x78a5636f,0x84c87814,0x8cc70208,0x90befffa,0xa4506ceb,0xbef9a3f7,0xc67178f2
    }

    SHA256 = function(msg)
        local h0,h1,h2,h3,h4,h5,h6,h7 =
            0x6a09e667,0xbb67ae85,0x3c6ef372,0xa54ff53a,
            0x510e527f,0x9b05688c,0x1f83d9ab,0x5be0cd19

        local bitlen = #msg * 8
        msg = msg .. "\128"
        while (#msg % 64) ~= 56 do
            msg = msg .. "\0"
        end
        for i = 7, 0, -1 do
            msg = msg .. string.char(band(rshift(bitlen, i * 8), 0xFF))
        end

        for chunkStart = 1, #msg, 64 do
            local w = {}
            for i = 0, 15 do
                local o = chunkStart + i * 4
                local b1, b2, b3, b4 = string.byte(msg, o, o + 3)
                w[i] = bor(lshift(b1, 24), lshift(b2, 16), lshift(b3, 8), b4)
            end
            for i = 16, 63 do
                local s0 = bxor(rrotate(w[i-15], 7), rrotate(w[i-15], 18), rshift(w[i-15], 3))
                local s1 = bxor(rrotate(w[i-2], 17), rrotate(w[i-2], 19), rshift(w[i-2], 10))
                w[i] = band(w[i-16] + s0 + w[i-7] + s1, 0xFFFFFFFF)
            end

            local a, b, c, d, e, f, g, h = h0, h1, h2, h3, h4, h5, h6, h7

            for i = 0, 63 do
                local S1 = bxor(rrotate(e, 6), rrotate(e, 11), rrotate(e, 25))
                local ch = bxor(band(e, f), band(bnot(e), g))
                local temp1 = band(h + S1 + ch + K[i + 1] + w[i], 0xFFFFFFFF)
                local S0 = bxor(rrotate(a, 2), rrotate(a, 13), rrotate(a, 22))
                local maj = bxor(band(a, b), band(a, c), band(b, c))
                local temp2 = band(S0 + maj, 0xFFFFFFFF)

                h = g; g = f; f = e
                e = band(d + temp1, 0xFFFFFFFF)
                d = c; c = b; b = a
                a = band(temp1 + temp2, 0xFFFFFFFF)
            end

            h0 = band(h0 + a, 0xFFFFFFFF); h1 = band(h1 + b, 0xFFFFFFFF)
            h2 = band(h2 + c, 0xFFFFFFFF); h3 = band(h3 + d, 0xFFFFFFFF)
            h4 = band(h4 + e, 0xFFFFFFFF); h5 = band(h5 + f, 0xFFFFFFFF)
            h6 = band(h6 + g, 0xFFFFFFFF); h7 = band(h7 + h, 0xFFFFFFFF)
        end

        return string.format("%08x%08x%08x%08x%08x%08x%08x%08x", h0, h1, h2, h3, h4, h5, h6, h7)
    end
end

-- ======================================================
-- 🧪 MODO DE TESTE — REMOVA ANTES DE PUBLICAR
-- ======================================================
local TESTING_MODE = true
local TEST_KEY = "TESTE-1NX"

if TESTING_MODE then
    warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '" .. TEST_KEY .. "' libera sem checar o site. Desliga TESTING_MODE antes de publicar!")
    -- Auto-teste do SHA256: "abc" tem que dar exatamente esse hash
    -- (é um vetor de teste oficial do SHA-256). Se não bater, teve
    -- algum bug na implementação em Lua puro — não confia no sistema
    -- de key premium até isso aqui mostrar "OK".
    local expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
    local got = SHA256("abc")
    if got == expected then
        print("✅ [1NXITER]: Auto-teste do SHA256 passou.")
    else
        warn("❌ [1NXITER]: Auto-teste do SHA256 FALHOU! Esperado " .. expected .. ", recebido " .. tostring(got) .. " — a validação de key premium NÃO vai funcionar.")
    end
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
-- KEY DIÁRIA (algoritmo idêntico ao da página getkey/)
-- ======================================================
local function GetDailyKey()
    local secret = "1NXITER-DAILY-2026"
    local today = os.date("!%Y-%m-%d") -- UTC pra bater com o JS
    local combined = secret .. today
    local hash = 0
    for i = 1, #combined do
        hash = (hash * 31 + string.byte(combined, i)) % 2147483647
    end
    return "1NX-FREE-" .. string.format("%08X", hash)
end

-- ======================================================
-- VALIDAÇÃO DE KEY PREMIUM (keys.json do GitHub)
-- ======================================================
local function ValidatePremiumKey(key, hwid, callback)
    local ok, raw = pcall(function()
        return game:HttpGet(KEYS_URL .. "?cache=" .. math.random(1, 999999))
    end)
    if not ok or not raw then
        callback(false, "Erro ao conectar ao servidor de keys.")
        return
    end

    local decOk, data = pcall(function()
        return game:GetService("HttpService"):JSONDecode(raw)
    end)
    if not decOk or not data or not data.keys then
        callback(false, "Erro ao ler dados de keys.")
        return
    end

    local keyData = data.keys[SHA256(key)]
    if not keyData then
        callback(false, "Key inválida.")
        return
    end

    if not keyData.active then
        callback(false, "Essa key foi revogada.")
        return
    end

    -- Expiração
    if keyData.expires and keyData.expires ~= "" then
        local y, m, d = keyData.expires:match("(%d+)-(%d+)-(%d+)")
        if y then
            local expiryTime = os.time({
                year = tonumber(y), month = tonumber(m), day = tonumber(d),
                hour = 23, min = 59, sec = 59
            })
            if os.time() > expiryTime then
                callback(false, "Sua key expirou. Renove no Discord.")
                return
            end
        end
    end

    -- HWID
    if keyData.hwid and keyData.hwid ~= "" and keyData.hwid ~= hwid then
        callback(false, "Key vinculada a outro dispositivo.\nPeça reset de HWID ao admin.")
        return
    end

    callback(true)
end

-- ======================================================
-- CHECAGEM UNIFICADA (teste → diária → premium)
-- ======================================================
local function CheckKey(key, callback)
    -- 1) Modo de teste
    if TESTING_MODE then
        if key == TEST_KEY then
            callback(true)
            return
        end
    end

    -- 2) Key diária (Linkvertise)
    if key == GetDailyKey() then
        callback(true)
        return
    end

    -- 3) Key premium (keys.json no GitHub)
    ValidatePremiumKey(key, GetHWID(), callback)
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

    -- Botão Obter Key (abre Linkvertise)
    local GetKeyBtn = Instance.new("TextButton")
    GetKeyBtn.Size = UDim2.new(1, -30, 0, 30)
    GetKeyBtn.Position = UDim2.new(0, 15, 0, 124)
    GetKeyBtn.BackgroundColor3 = Color3.fromRGB(50, 35, 70)
    GetKeyBtn.Text = "🔗 OBTER KEY GRÁTIS"
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
    InfoLabel.Text = "Key grátis = 24h · Key premium = Discord"
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

    -- Obter Key: copia o link do Linkvertise
    GetKeyBtn.MouseButton1Click:Connect(function()
        local copier = setclipboard or toclipboard
        if type(copier) == "function" then
            pcall(copier, LINKVERTISE_URL)
            ErrorLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            ErrorLabel.Text = "Link copiado! Cole no navegador."
        else
            ErrorLabel.TextColor3 = Color3.fromRGB(180, 140, 255)
            ErrorLabel.Text = "Abra: " .. LINKVERTISE_URL
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
