local AutoJJs = {}
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Player = Players.LocalPlayer

-- Detecta qual sistema de chat o jogo usa (mesmo método do SpyChat).
-- TextChatService é o novo padrão — jogos que migraram não têm mais
-- DefaultChatSystemChatEvents no ReplicatedStorage, então o FireServer
-- antigo simplesmente não faz nada (sem erro, mas sem mensagem).
local usingTextChatService = false
pcall(function()
    usingTextChatService = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
end)

-- Tenta enviar pelo sistema certo, com fallback pro outro.
local function SendChat(message)
    if usingTextChatService then
        local sent = false
        pcall(function()
            local channel = TextChatService.TextChannels:FindFirstChild("RBXGeneral")
            if channel then
                channel:SendAsync(message)
                sent = true
            end
        end)
        if sent then return true end
    end

    local ok = pcall(function()
        game:GetService("ReplicatedStorage")
            .DefaultChatSystemChatEvents
            .SayMessageRequest:FireServer(message, "All")
    end)
    return ok
end

-- Monta a mensagem final: texto do número + espaçamento opcional + sufixo
-- (customizado tem prioridade sobre o predefinido; "Nenhum" vira vazio).
local function BuildMessage(Config, numberText)
    local suffix = Config.Sufixo or "!"
    if Config.SufixoCustomizado and Config.SufixoCustomizado ~= "" then
        suffix = Config.SufixoCustomizado
    elseif suffix == "Nenhum" then
        suffix = ""
    end
    local spacing = Config.Espacamento and " " or ""
    return numberText .. spacing .. suffix
end

-- Só um modo de intervalo fica realmente ativo por vez (Config.IntervalMode
-- guarda qual foi o último ligado pela aba) — evita ambiguidade se mais de
-- um toggle ficar marcado visualmente ao mesmo tempo.
local function ComputeDelay(Config, totalSteps)
    local mode = Config.IntervalMode

    if mode == "Inteligente" then
        local total = tonumber(Config.IntervaloInteligenteTempo) or 60
        return math.max(total / math.max(totalSteps, 1), 0.05)
    elseif mode == "Dinamico" then
        local minV = tonumber(Config.IntervaloDinamicoMin) or 1
        local maxV = tonumber(Config.IntervaloDinamicoMax) or 3
        if maxV < minV then minV, maxV = maxV, minV end
        return minV + math.random() * (maxV - minV)
    else -- "Fixo" ou nada escolhido ainda -- cai pro fixo
        return tonumber(Config.IntervaloFixoValor) or 1.4
    end
end

function AutoJJs:Toggle(Config, State, Hub, updateUI)
    -- Guarda a referência do State: sem isso, Unload() não tinha como
    -- parar o loop que já estava rodando em segundo plano (task.spawn).
    self._state = State

    if State.IsRunning then
        State.IsRunning = false
        self._currentRunId = nil
        if updateUI then updateUI("STATUS: PAUSADO") end
        return
    end

    State.IsRunning = true
    local runId = {}
    self._currentRunId = runId

    task.spawn(function()
        local ok, err = pcall(function()
            local inicial = tonumber(Config.Inicial) or 1
            local final = tonumber(Config.Final) or 100

            local from = Config.ModoReverso and final or inicial
            local to = Config.ModoReverso and inicial or final
            local step = (to >= from) and 1 or -1
            local totalSteps = math.floor(math.abs(to - from)) + 1

            for i = from, to, step do
                if not State.IsRunning or not State.IsActive or self._currentRunId ~= runId then break end

                if updateUI then updateUI("Auto JJ's — Contagem: " .. tostring(i)) end

                -- Converte número pra texto PT-BR (Utils) quando disponível
                local numberText = (Hub.Core.Utils and Hub.Core.Utils:NumberToText(i)) or tostring(i)
                local msg = BuildMessage(Config, numberText)

                local sent = SendChat(msg)
                if not sent then
                    warn("⚠️ [1NXITER] Auto JJ's: falha ao enviar no chat — verifique se o chat está disponível")
                end

                if Config.Pular and Player.Character then
                    local hum = Player.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
                end

                task.wait(ComputeDelay(Config, totalSteps))
            end
        end)

        if not ok then
            warn("❌ [1NXITER] Auto JJ's: erro na rotina -> " .. tostring(err))
            if updateUI then updateUI("STATUS: ERRO (veja o console F9)") end
        else
            if updateUI then updateUI("STATUS: CONCLUÍDO ✅") end
        end

        State.IsRunning = false
    end)
end

-- Sem Unload, um treino em andamento sobreviveria ao "FECHAR HUB" e
-- continuaria mandando mensagem no chat pra sempre, sem UI pra pausar.
function AutoJJs:Unload()
    self._currentRunId = nil
    if self._state then
        self._state.IsRunning = false
        self._state.IsActive = false
    end
end

return AutoJJs
