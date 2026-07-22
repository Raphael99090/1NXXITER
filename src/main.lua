--[[
    1NXITER HUB | Versão 3.0 Modular
    Ponto de Entrada (Main Loader)
    Repositório: Raphael99090/1NXXITER
]]

if getgenv().InxiterHubLoaded then 
    return warn("⚠️ [1NXITER]: Hub já está em execução!") 
end

-- ======================================================
-- Configurações de Caminho
-- ======================================================
local REPO = "Raphael99090/1NXXITER"
local BRANCH = "main"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/src/"

-- Tabela global interna (não polui o getgenv desnecessariamente)
local Hub = {
    Core = {},
    Features = {},
    UI = {
        Tabs = {}
    }
}

-- ======================================================
-- Helper: Importador Modular
-- ======================================================
local function Import(path)
    local url = BASE_URL .. path .. ".lua"
    
    print("📥 [1NXITER]: Baixando módulo -> " .. path)
    
    local success, code = pcall(function()
        return game:HttpGet(url .. "?nocache=" .. tostring(math.random(1, 999999)))
    end)

    if success and code and not code:match("^404") then
        local func, err = loadstring(code)
        if func then
            local runSuccess, result = pcall(func)
            if runSuccess then
                return result
            else
                warn("❌ [1NXITER]: Erro ao executar módulo (" .. path .. "): " .. tostring(result))
            end
        else
            warn("❌ [1NXITER]: Erro de sintaxe no arquivo (" .. path .. "): " .. tostring(err))
        end
    else
        warn("❌ [1NXITER]: Falha ao baixar arquivo ou 404 (" .. path .. ")")
    end
    return nil
end

-- ======================================================
-- Carregamento Sequencial
-- ======================================================

-- 1. Carregar Core (Essencial)
Hub.Core.Utils = Import("01-Core/Utils")
Hub.Core.State = Import("01-Core/State")

-- 2. Carregar Features (Lógica)
local features = {
    "AutoTrain", "Aimbot", "ESP", "PlayerMods", "FreeCam", "SpyChat"
}
for _, feature in pairs(features) do
    Hub.Features[feature] = Import("02-Features/" .. feature)
end

-- 3. Carregar Tabs da Interface (Desenho das Abas)
local tabs = {
    "TrainTab", "CombatTab", "ESPTab", "MovementTab", "CameraTab", "SystemTab"
}
for _, tab in pairs(tabs) do
    Hub.UI.Tabs[tab] = Import("03-Interface/Tabs/" .. tab)
end

-- 4. Carregar Interface Main (Montador da Janela)
Hub.UI.Main = Import("03-Interface/Main")

-- ======================================================
-- Inicialização Final
-- ======================================================
local function Initialize()
    -- Verificação de integridade básica
    if not Hub.Core.State or not Hub.UI.Main then
        return warn("❌ [1NXITER]: Carregamento incompleto. Verifique o console (F9).")
    end

    print("✅ [1NXITER]: Módulos carregados. Iniciando UI...")
    
    getgenv().InxiterHubLoaded = true

    -- 1. Carrega Configurações do JSON
    local Config = Hub.Core.State:LoadConfig()
    local RuntimeState = Hub.Core.State:GetRuntimeState()

    -- 2. Inicia funções em segundo plano (Anti-AFK, etc)
    if Hub.Core.Utils and Hub.Core.Utils.AntiAFK then
        Hub.Core.Utils:AntiAFK(RuntimeState)
    end

    -- 3. Chama o montador da interface passando os módulos
    Hub.UI.Main:Load(Hub, Config, RuntimeState)
end

-- Rodar sistema
local success, err = pcall(Initialize)
if not success then
    getgenv().InxiterHubLoaded = false
    warn("❌ [1NXITER]: Falha crítica na inicialização -> " .. tostring(err))
end
