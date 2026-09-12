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
-- [1.5] PANDA KEY SYSTEM — agora via KeySystem nativo da WindUI
-- ======================================================
-- Até aqui o Hub tinha ~220 linhas próprias pra isso: HWID manual, fetch
-- da lib PUSL V4 do Panda, e uma janela de key inteira montada na mão.
-- A WindUI já suporta "pandadevelopment" como provedor nativo do
-- KeySystem (viram até changelog corrigindo a URL da API do Panda lá).
-- Isso passou a ser só configuração — ver Hub.KeyConfig abaixo, lido
-- pelo Interface/Window.lua na hora de montar a janela principal.
--
-- ⚠️ NÃO TESTADO AINDA NO EXECUTOR: a troca ficou bem menor e mais fácil
-- de manter, mas o comportamento exato do KeySystem nativo (se ele
-- realmente bloqueia a janela até validar, callback de sucesso, etc.)
-- não foi confirmado na prática — testa antes de considerar isso pronto
-- pra valer. Se não travar a janela como esperado, a gente volta pro
-- RequestKey() manual (estava funcionando, só era maior).
--
-- ⚠️ TROQUE o PANDA_SERVICE_ID pelo identificador do seu serviço
--    que você criou no painel do Panda (pandadevelopment.net/dashboard)
local PANDA_SERVICE_ID = "1nxxiter"

-- 🧪 MODO DE TESTE — REMOVA ANTES DE PUBLICAR. Com TESTING_MODE = true,
-- a key TEST_KEY também libera (via lista estática do próprio KeySystem),
-- sem precisar checar o Panda de verdade.
local TESTING_MODE = false
local TEST_KEY = "TESTE-1NX"

if TESTING_MODE then
    warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '" .. TEST_KEY .. "' libera sem checar o Panda. Desliga TESTING_MODE antes de publicar!")
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

-- Config do Key System nativo — lido pelo Interface/Window.lua na hora de
-- montar o CreateWindow principal (ver comentário em [1.5] acima).
Hub.KeyConfig = {
    ServiceId = PANDA_SERVICE_ID,
    TestKey = TESTING_MODE and TEST_KEY or nil,
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
            if self.Core.Lifecycle then
                self.Core.Lifecycle:MarkUnloaded(name, ok, err)
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
-- Esta função baixa o código do GitHub, compila e retorna o módulo.
-- Segundo retorno (errMsg) é novo: quem já chamava Import() ignorando um
-- 2º valor continua funcionando igual — só o Lifecycle Manager usa isso.
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
                local msg = "Erro ao executar módulo: " .. tostring(result)
                warn("❌ [1NXITER]: " .. msg .. " (" .. path .. ")")
                return nil, msg
            end
        else
            local msg = "Erro de sintaxe: " .. tostring(err)
            warn("❌ [1NXITER]: " .. msg .. " (" .. path .. ")")
            return nil, msg
        end
    else
        local msg = "Arquivo não encontrado ou erro de rede (404)"
        warn("❌ [1NXITER]: " .. msg .. " -> " .. url)
        return nil, msg
    end
end

-- ======================================================
-- [5] ORDEM DE CARREGAMENTO (ETAPAS)
-- ======================================================
local function LoadHub()

-- Lifecycle Manager carrega primeiro. Se falhar (rede, etc.), o resto do
-- Hub continua funcionando exatamente como antes — só sem Hub Doctor.
Hub.Core.Lifecycle = Import("Core/Lifecycle")

-- Envolve o Import() de sempre com Discover -> Load -> Validate -> Running.
-- Sem Lifecycle disponível, cai pro Import() puro (comportamento antigo).
local function LoadModule(category, name, path)
    if Hub.Core.Lifecycle then
        Hub.Core.Lifecycle:Discover(name, category)
        local mod = Hub.Core.Lifecycle:LoadAndValidate(name, path, Import)
        if mod then Hub.Core.Lifecycle:MarkRunning(name) end
        return mod
    end
    return Import(path)
end

-- ETAPA 1: Carregar Core (Essencial para o Hub existir)
Hub.Core.Utils = LoadModule("Core", "Utils", "Core/Utils")
Hub.Core.State = LoadModule("Core", "State", "Core/State")

-- ETAPA 2: Carregar Features (As funções de hack)
local featuresList = {
    "AutoTrain", "Aimbot", "ESP", "PlayerMods", "FreeCam", "SpyChat", "Visuals", "TASRecorder"
}
for _, f in pairs(featuresList) do
    Hub.Features[f] = LoadModule("Feature", f, "Features/" .. f)
end

-- TAS precisa suspender Aimbot/FreeCam durante o replay (os três disputam
-- o controle da câmera) — é a única dependência real entre Features do
-- projeto, e é opcional por natureza: sem essa chamada o TAS continua
-- funcionando sozinho, só sem suspender ninguém.
if Hub.Features.TASRecorder and Hub.Features.TASRecorder.SetHub then
    Hub.Features.TASRecorder:SetHub(Hub)
end

-- Getters de "tá ativo agora?" pro Hub Doctor — só pra quem tem um
-- conceito simples de ligado/desligado. Lidos ao vivo, nunca guardados.
if Hub.Core.Lifecycle then
    local L = Hub.Core.Lifecycle
    if Hub.Features.Aimbot then L:SetActiveGetter("Aimbot", function() return Hub.Features.Aimbot.Settings.Enabled end) end
    if Hub.Features.ESP then L:SetActiveGetter("ESP", function() return Hub.Features.ESP.Settings.Enabled end) end
    if Hub.Features.FreeCam then L:SetActiveGetter("FreeCam", function() return Hub.Features.FreeCam.Settings.Enabled end) end
    if Hub.Features.SpyChat then L:SetActiveGetter("SpyChat", function() return Hub.Features.SpyChat.Enabled end) end
    if Hub.Features.Visuals then L:SetActiveGetter("Visuals", function() return Hub.Features.Visuals.Settings.StretchedEnabled end) end
    if Hub.Features.TASRecorder then
        L:SetActiveGetter("TASRecorder", function()
            local t = Hub.Features.TASRecorder
            return t:IsRecording() or t:IsPlaying() or t.Settings.ReproduzirArmed
        end)
    end
    if Hub.Features.PlayerMods then
        L:SetActiveGetter("PlayerMods", function()
            local s = Hub.Features.PlayerMods.Settings
            return s.SpeedEnabled or s.JumpEnabled or s.Noclip or s.InfJump or s.Fly or s.AntiVoid
        end)
    end
    -- AutoTrain não tem Settings.Enabled (o estado vive no RuntimeState) —
    -- o getter dele é preso lá em Start(), quando o RuntimeState existe.
end

-- ETAPA 3: Carregar Tabs (O conteúdo de cada aba da UI)
local tabsList = {
    "OverviewTab", "CombatTab", "ESPTab", "MovementTab", "CameraTab", "SpyChatTab", "TrainTab", "ShortcutsTab", "SystemTab", "TASTab"
}
for _, t in pairs(tabsList) do
    Hub.UI.Tabs[t] = LoadModule("Tab", t, "Interface/Tabs/" .. t)
end

-- ETAPA 4: Carregar Interface Main (O montador da janela)
Hub.UI.Interface = LoadModule("Core", "InterfaceWindow", "Interface/Window")

-- ======================================================
-- APLICAÇÃO DA CONFIGURAÇÃO SALVA
-- Sincroniza o JSON com as Settings internas das Features.
-- ======================================================
function Hub:ApplyConfig()
    local c = self._Config
    if type(c) ~= "table" then return end

    local aim = self.Features.Aimbot
    if aim then
        local a = c.Aimbot or {}
        aim.Settings.Enabled = a.Enabled == true
        aim.Settings.TeamCheck = a.TeamCheck == true
        aim.Settings.WallCheck = a.WallCheck ~= false
        aim.Settings.ShowFOV = a.ShowFOV == true
        aim.Settings.FOVRadius = a.FOVRadius or 150
        aim.Settings.Smoothness = a.Smoothness or 0.5
        aim.Settings.SilentAim = a.SilentAim == true
        aim.Settings.Priority = a.Priority or "Closest"
        aim.Settings.AimKeyOnly = a.AimKeyOnly == true
        aim.Settings.IgnoredTeams = a.IgnoredTeams or {}
        aim.Settings.TargetPlayers = a.TargetPlayers or {}
        aim.Settings.HitboxExpander = a.HitboxExpander == true
        aim.Settings.HitboxSize = a.HitboxSize or 10
        aim.Settings.TargetPart = a.TargetPart or "HumanoidRootPart"
        aim.Settings.AimKey = Enum.KeyCode[a.AimKey or c.AimKey or "E"] or Enum.KeyCode.E
    end

    local esp = self.Features.ESP
    if esp then
        local e = c.ESP or {}
        esp.Settings.TeamCheck = e.TeamCheck == true
        esp.Settings.FillTransparency = e.FillTransparency or 0.6
        esp.Settings.Tracers = e.Tracers == true
        esp.Settings.Distance = e.Distance == true
        esp:Toggle(e.Enabled == true)
    end

    local move = self.Features.PlayerMods
    if move then
        local m = c.Movement or {}
        move.Settings.SpeedValue = m.SpeedValue or 50
        move.Settings.JumpValue = m.JumpValue or 100
        move.Settings.FlySpeed = m.FlySpeed or 50
        move:ToggleSpeed(m.SpeedEnabled == true)
        move:ToggleJumpPower(m.JumpEnabled == true)
        move:ToggleNoclip(m.Noclip == true)
        move:ToggleInfJump(m.InfJump == true)
        move:ToggleFly(m.Fly == true)
        move:ToggleAntiVoid(m.AntiVoid == true)
    end

    local visuals = self.Features.Visuals
    if visuals then
        local cam = c.Camera or {}
        visuals.Settings.FOVValue = cam.FOVValue or 70
        visuals:ToggleStretched(cam.StretchedEnabled == true)
    end

    local freecam = self.Features.FreeCam
    if freecam then
        local cam = c.Camera or {}
        freecam.Settings.Speed = cam.FreeCamSpeed or 1
        freecam.Settings.Sensitivity = cam.FreeCamSensitivity or 0.5
        freecam:Toggle(cam.FreeCamEnabled == true)
    end

    local tas = self.Features.TASRecorder
    if tas then
        local t = c.TAS or {}
        tas.Settings.ReproduzirArmed = t.ReproduzirArmed == true
    end

    local spy = self.Features.SpyChat
    if spy then
        local spyCfg = c.SpyChat
        if not spyCfg and c.Camera and c.Camera.SpyChatEnabled ~= nil then
            -- Migração: até a v3.6, o toggle do Spy Chat morava em
            -- Config.Camera (a aba "Câmera" que ele nunca deveria ter
            -- ficado). Preserva o valor salvo em vez de resetar pra
            -- desligado só porque mudou de lugar.
            c.SpyChat = { Enabled = c.Camera.SpyChatEnabled }
            spyCfg = c.SpyChat
        end
        spy:Toggle((spyCfg and spyCfg.Enabled) == true)
    end
end

-- ======================================================
-- [6] INICIALIZAÇÃO FINAL
-- ======================================================
local function Start()
    -- Verificação de Integridade: Se State ou Main falharem, o script para.
    if not Hub.Core.State or not Hub.UI.Interface then
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
    Hub._Config = Config
    Hub:ApplyConfig()

    -- AutoTrain não tem Settings.Enabled (o estado vive no RuntimeState),
    -- então o getter dele só dá pra prender aqui, depois que RuntimeState existe.
    if Hub.Core.Lifecycle and Hub.Features.AutoTrain then
        Hub.Core.Lifecycle:SetActiveGetter("AutoTrain", function() return RuntimeState.IsRunning end)
    end

    -- Salva sozinho em segundo plano (respeita Config.AutoSave)
    Hub.Core.State:StartAutoSave(Config, 8)

    -- Inicia funções de fundo (Anti-AFK, Auto-Rejoin, etc)
    if Hub.Core.Utils then
        Hub.Core.Utils:ToggleAntiAFK(Config.AntiAFK ~= false)
        Hub.Core.Utils:AutoRejoin(Config)
    end

    -- Liga a Interface e desenha as abas
    Hub.UI.Interface:Load(Hub, Config, RuntimeState)

    -- [ HUB DOCTOR ] Diagnóstico completo no console (F9), depois de tudo
    -- carregado e configurado — mostra o estado real de cada módulo.
    if Hub.Core.Lifecycle then
        Hub.Core.Lifecycle:Print()
    end
end

-- Executa a inicialização de forma protegida
local finalSuccess, finalErr = pcall(Start)

if not finalSuccess then
    getgenv().InxiterHubLoaded = false
    warn("❌ [1NXITER]: Erro fatal durante a inicialização -> " .. tostring(finalErr))
end

end

-- O KeySystem agora vive dentro da janela principal (Interface/Window.lua),
-- então o carregamento dos módulos já roda direto — a diferença prática
-- é que os módulos são baixados do GitHub antes da key ser validada
-- (antes só baixava depois). Pra um hub pessoal isso não pesa; se algum
-- dia importar economizar essas requests, dá pra voltar a gatear aqui.
LoadHub()
