local StateManager = {}
local HttpService = game:GetService("HttpService")

-- Configurações do Arquivo
local FOLDER_NAME = "1NXITER_HUB"
local FILE_NAME = FOLDER_NAME .. "/Config_v3.json"

-- [ FONTE DA VERDADE ]: Valores padrões do Hub
local DefaultConfig = {
    -- Treino
    Mode = "Canguru",
    Delay = 1.4,
    StartNum = 0,
    Quantity = 130,
    IsCountdown = false,
    AutoCrouch = false,
    AutoEquip = false,
    
    -- Sistema
    AutoRejoin = false,
    UITheme = "Darker",
    AutoSave = true
}

-- Estado em tempo de execução (não é salvo no disco)
local RuntimeState = { 
    IsRunning = false, 
    IsActive = true,
    LoadedAt = os.date("%X")
}

-- Helper: Verifica suporte do executor
local function HasFileSystem()
    return isfile and readfile and writefile and makefolder and isfolder
end

-- Helper: Mescla tabelas (Garante que novas funções apareçam na config antiga)
local function DeepMerge(target, source)
    for k, v in pairs(source) do
        if type(v) == "table" and type(target[k]) == "table" then
            DeepMerge(target[k], v)
        else
            target[k] = v
        end
    end
    return target
end

function StateManager:GetRuntimeState()
    return RuntimeState
end

function StateManager:LoadConfig()
    if not HasFileSystem() then return DefaultConfig end

    if isfile(FILE_NAME) then
        local ok, content = pcall(readfile, FILE_NAME)
        if ok then
            local decodeOk, decoded = pcall(HttpService.JSONDecode, HttpService, content)
            if decodeOk and type(decoded) == "table" then
                -- Mescla o que foi lido com o Default (previne erros de valores nulos)
                local finalConfig = {}
                for k,v in pairs(DefaultConfig) do finalConfig[k] = v end
                return DeepMerge(finalConfig, decoded)
            end
        end
    end
    return DefaultConfig
end

function StateManager:SaveConfig(currentConfig)
    if not HasFileSystem() then return false end

    local ok, err = pcall(function()
        if not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end
        local data = HttpService:JSONEncode(currentConfig)
        writefile(FILE_NAME, data)
    end)
    
    return ok
end

return StateManager
