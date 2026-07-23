--[[
    1NXITER HUB | Versão 3.0 (Modular SRC)
    Desenvolvedor: Raphael99090
    Repositório: 1NXXITER
]]

-- [1] SEGURANÇA: Evita carregar o script duas vezes
if getgenv().InxiterHubLoaded then 
    return warn("⚠️ [1NXITER]: O Hub já está em execução!") 
end

-- [2] CONFIGURAÇÃO DE LINKS
local REPO = "Raphael99090/1NXXITER"
local BRANCH = "main"
local BASE_URL = "https://raw.githubusercontent.com/" .. REPO .. "/" .. BRANCH .. "/src/"

-- ======================================================
-- [1.5] SISTEMA DE KEY (fixa, só pra teste)
-- ======================================================
-- IMPORTANTE: isso é só um teste. Uma key fixa dentro do código é
-- trivialmente extraível (basta ler o script), então qualquer um
-- que pegue o arquivo consegue achar a KEY sem nem precisar dela.
-- Serve só pra validar o fluxo de UI antes de trocar por algo real
-- (endpoint próprio, verificação de membro do Discord, etc).
local KEY = "1NX-2026"

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

    local function TryKey()
        if Input.Text == KEY then
            KeyGui:Destroy()
            onSuccess()
        else
            ErrorLabel.Text = "Key inválida. Tenta de novo."
            Input.Text = ""
        end
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
    
    -- Marca o Hub como carregado
    getgenv().InxiterHubLoaded = true

    -- Carrega as configurações salvas no JSON do celular
    local Config = Hub.Core.State:LoadConfig()
    local RuntimeState = Hub.Core.State:GetRuntimeState()

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
