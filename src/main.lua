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
local BRANCH = "opera"
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
-- VALIDAÇÃO VIA PANDA API (NOVA PUSL-V4 HTTP)
-- ======================================================
local PUSL_INIT = false
local PUSL_LIB = nil

task.spawn(function()
    local ok, lib = pcall(function()
        return loadstring(game:HttpGet("https://secure.pandauth.com/pv4/lib"))()
    end)
    if ok and lib and type(lib.configure) == "function" then
        lib.configure({
            serviceId = PANDA_SERVICE_ID,
        })
        PUSL_LIB = lib
        PUSL_INIT = true
        print("✅ [1NXITER]: Biblioteca do Panda Auth (PUSL V4) carregada com sucesso!")
    else
        warn("⚠️ [1NXITER]: Falha ao carregar a biblioteca do Panda Auth.")
    end
end)

local function ValidatePandaKey(key, hwid, callback)
    print("🔑 [1NXITER]: Validando key no Panda...")

    if not PUSL_INIT or not PUSL_LIB then
        callback(false, "A biblioteca do Panda ainda está carregando ou falhou.\nTente novamente em alguns segundos.")
        return
    end

    local ok, result = pcall(function()
        return PUSL_LIB.validate(key)
    end)

    if not ok or type(result) ~= "table" then
        callback(false, "Erro interno de conexão com o Panda.")
        return
    end

    if result.success then
        print("✅ [1NXITER]: Key validada pelo Panda! Premium: " .. tostring(result.isPremium))
        callback(true)
    else
        -- O result do novo Panda Auth não costuma especificar se foi HWID, Expired, etc. de forma fácil
        -- Então retornamos uma mensagem padrão informando que a key falhou.
        callback(false, "Key inválida ou recusada pelo servidor.\nPegue uma nova no GetKey.")
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
    local hwid = GetHWID()
    
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)

    if not success or not WindUI then
        warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI para o Key System.")
        return
    end

    local Window = WindUI:CreateWindow({
        Title = "1NXITER HUB",
        Author = "Panda Key System",
        Icon = "key",
        Folder = "InxiterHub",
        Size = UDim2.fromOffset(400, 240),
        OpenButton = false,
        Transparent = true,
        Theme = "Dark"
    })

    local Tab = Window:Tab({ Title = "Autenticação", Icon = "lock" })
    
    local KeyInput = ""

    Tab:Input({
        Title = "Insira sua Key",
        Desc = "Cole a key gerada pelo Panda Auth abaixo.",
        PlaceholderText = "Cole aqui...",
        Callback = function(text)
            KeyInput = text
        end
    })

    Tab:Button({
        Title = "Obter Key (Copiar Link)",
        Desc = "Copia o link para o seu navegador.",
        Icon = "link",
        Callback = function()
            local pandaUrl = PANDA_GETKEY_BASE .. "?hwid=" .. hwid
            local copier = setclipboard or toclipboard
            if type(copier) == "function" then
                pcall(copier, pandaUrl)
                WindUI:Notify({Title = "Key System", Content = "Link copiado para a área de transferência!", Duration = 3})
            else
                WindUI:Notify({Title = "Key System", Content = "Abra: " .. pandaUrl, Duration = 5})
            end
        end
    })

    local checking = false
    Tab:Button({
        Title = "Validar e Entrar",
        Icon = "check",
        Callback = function()
            if checking then return end
            if KeyInput == "" then
                WindUI:Notify({Title = "Aviso", Content = "Insira sua key antes de confirmar.", Duration = 3})
                return
            end

            checking = true
            WindUI:Notify({Title = "Key System", Content = "Verificando key...", Duration = 2})

            CheckKey(KeyInput, function(valid, errorMsg)
                checking = false
                if valid then
                    WindUI:Notify({Title = "Sucesso", Content = "Key validada! Carregando Hub...", Duration = 2})
                    task.wait(1.5)
                    pcall(function() Window:Destroy() end)
                    onSuccess()
                else
                    WindUI:Notify({Title = "Erro", Content = errorMsg or "Key inválida. Tente novamente.", Duration = 4})
                end
            end)
        end
    })
    
    Tab:Select()
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
