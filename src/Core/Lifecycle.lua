--[[
    Lifecycle Manager — não é um loader novo, é uma casca fina em cima do
    Import()/Unload() que já existiam. Objetivo único: dar nome e estado
    consultável pro que o Hub já fazia implicitamente (módulo virou nil =
    falhou; Settings.Enabled = ligado/desligado), pra existir um lugar só
    (Hub Doctor) que responde "o que tá quebrado e por quê" sem caçar
    warn() espalhado no console.

    Não força nenhuma Feature a mudar de formato — cada módulo continua
    exatamente como é (eager-connect, toggle-connect, o que for).
]]

local Lifecycle = {}

Lifecycle.State = {
    DISCOVERED = "DISCOVERED",
    LOADED     = "LOADED",
    VALIDATED  = "VALIDATED",
    RUNNING    = "RUNNING",
    DISABLED   = "DISABLED",
    FAILED     = "FAILED",
    UNLOADED   = "UNLOADED",
}

Lifecycle._modules = {} -- [name] = { Category, State, Stage, Error, CleanupOk, ActiveGetter }
Lifecycle._order = {}   -- preserva a ordem de descoberta pro relatório/print

local function ensure(self, name)
    if not self._modules[name] then
        table.insert(self._order, name)
        self._modules[name] = { State = self.State.DISCOVERED }
    end
    return self._modules[name]
end

function Lifecycle:Discover(name, category)
    local entry = ensure(self, name)
    entry.Category = category
    entry.State = self.State.DISCOVERED
    return entry
end

-- Roda importFn(path) (normalmente o Import() do main.lua) e já classifica
-- o resultado: nil -> FAILED(stage=LOAD); não-tabela -> FAILED(stage=VALIDATE);
-- ok -> VALIDATED. Devolve o módulo igual o Import() sempre devolveu, então
-- quem chama não precisa mudar como usa o retorno.
function Lifecycle:LoadAndValidate(name, path, importFn)
    local entry = ensure(self, name)

    local mod, err = importFn(path)

    if mod == nil then
        entry.State = self.State.FAILED
        entry.Stage = "LOAD"
        entry.Error = err or "Import retornou nil (ver console/F9)"
        return nil
    end

    entry.State = self.State.LOADED

    if type(mod) ~= "table" then
        entry.State = self.State.FAILED
        entry.Stage = "VALIDATE"
        entry.Error = "Módulo não retornou uma tabela (retornou " .. type(mod) .. ")"
        return nil
    end

    entry.State = self.State.VALIDATED
    return mod
end

-- Fecha VALIDATE -> RUNNING. A "inicialização" de verdade, pra maioria dos
-- módulos eager-connect, já rolou como efeito colateral de rodar o chunk
-- dentro do Import — isso aqui só confirma que o módulo virou parte do Hub.
function Lifecycle:MarkRunning(name)
    local entry = self._modules[name]
    if entry and entry.State == self.State.VALIDATED then
        entry.State = self.State.RUNNING
    end
end

-- Registra uma função opcional que devolve true/false = "esse módulo tá
-- ativo agora?" (ex: Aimbot.Settings.Enabled). Sem isso, o módulo só
-- aparece como RUNNING (carregado e ok) sem distinguir ligado/desligado —
-- de propósito, porque nem todo módulo tem um único conceito de "ligado"
-- (PlayerMods tem 6 toggles independentes, por exemplo).
function Lifecycle:SetActiveGetter(name, getterFn)
    local entry = self._modules[name]
    if entry then entry.ActiveGetter = getterFn end
end

-- Chamado pelo Hub:Unload() depois do pcall(feature.Unload). ok=false
-- guarda o estado como FAILED(stage=UNLOAD, CleanupOk=false) em vez de
-- fingir que descarregou limpo.
function Lifecycle:MarkUnloaded(name, ok, err)
    local entry = self._modules[name]
    if not entry then return end
    if ok then
        entry.CleanupOk = true
        entry.State = self.State.UNLOADED
    else
        entry.State = self.State.FAILED
        entry.Stage = "UNLOAD"
        entry.CleanupOk = false
        entry.Error = err or entry.Error
    end
end

-- Estado "ao vivo": só chama o ActiveGetter na hora de reportar, nunca
-- guarda — assim não existe estado desatualizado. Um erro dentro do
-- getter nunca derruba o relatório inteiro (pcall).
local function LiveState(entry)
    if entry.State ~= Lifecycle.State.RUNNING then return entry.State end
    if entry.ActiveGetter then
        local ok, active = pcall(entry.ActiveGetter)
        if ok then
            return active and Lifecycle.State.RUNNING or Lifecycle.State.DISABLED
        end
    end
    return entry.State
end

-- Lista ordenada pronta pra UI ou print: [{Name, Category, State, Stage, Error, CleanupOk}]
function Lifecycle:Report()
    local report = {}
    for _, name in ipairs(self._order) do
        local entry = self._modules[name]
        table.insert(report, {
            Name = name,
            Category = entry.Category,
            State = LiveState(entry),
            Stage = entry.Stage,
            Error = entry.Error,
            CleanupOk = entry.CleanupOk,
        })
    end
    return report
end

local ICONS = {
    RUNNING = "✓", DISABLED = "•", FAILED = "✗",
    UNLOADED = "–", LOADED = "…", VALIDATED = "…", DISCOVERED = "…",
}

-- [ HUB DOCTOR ] Caixa de diagnóstico no console (F9).
function Lifecycle:Print()
    local report = self:Report()
    local okCount = 0
    for _, r in ipairs(report) do
        if r.State == self.State.RUNNING or r.State == self.State.DISABLED then
            okCount = okCount + 1
        end
    end

    local width = 34
    local function line(text)
        text = " " .. text
        local pad = width - #text
        if pad < 0 then pad = 0 end
        return "║" .. text .. string.rep(" ", pad) .. "║"
    end

    print("╔" .. string.rep("═", width) .. "╗")
    print(line("1NXITER DIAGNOSTIC"))
    print("╠" .. string.rep("═", width) .. "╣")
    for _, r in ipairs(report) do
        local icon = ICONS[r.State] or "?"
        print(line(string.format("%-16s%s", r.Name, icon)))
        if r.State == self.State.FAILED then
            print(line("  Stage: " .. tostring(r.Stage)))
            print(line("  Error: " .. tostring(r.Error)))
            print(line("  Cleanup: " .. (r.CleanupOk and "OK" or (r.CleanupOk == false and "FALHOU" or "N/A"))))
        end
    end
    print("╠" .. string.rep("═", width) .. "╣")
    print(line(string.format("%d/%d MODULES READY", okCount, #report)))
    print("╚" .. string.rep("═", width) .. "╝")
end

return Lifecycle
