local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.AutoJJs
    Config.AutoJJs = Config.AutoJJs or {}
    local Cfg = Config.AutoJJs

    if not Mod then
        WindowTab:Section({ Title = "⚠️ Auto JJ's indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

    -- Status fica fora das categorias que minimizam, pra continuar visível
    -- mesmo com tudo fechado.
    local Status = WindowTab:Section({ Title = "Status", Desc = "Parado.", Opened = true })

    -- ============================
    -- ESSENCIAIS
    -- ============================
    local Essenciais = WindowTab:Section({ Title = "Essenciais", Desc = "Configuração geral e contagem.", Icon = "list-ordered", Opened = true })

    Essenciais:Toggle({
        Flag = "JJsEnabled", Title = "Auto JJ's", Icon = "play",
        Desc = "Ativa ou desativa a execução automática da contagem no chat.",
        Value = State.IsRunning == true,
        Callback = function(v)
            Mod:Toggle(Config, State, Hub, function(t) Status:SetDesc(t) end)
        end,
    })

    Essenciais:Dropdown({
        Flag = "JJsModo", Title = "Modo", Desc = "Formato e regra da contagem enviada.",
        Values = { "Padrão" }, Value = Cfg.Modo or "Padrão",
        Callback = function(v) Cfg.Modo = v end,
    })

    Essenciais:Input({ Flag = "JJsInicial", Title = "Inicial", Desc = "Número de início da contagem.", Value = tostring(Cfg.Inicial or 1), Callback = function(v) Cfg.Inicial = tonumber(v) or 1 end })
    Essenciais:Input({ Flag = "JJsFinal", Title = "Final", Desc = "Número de término da contagem.", Value = tostring(Cfg.Final or 100), Callback = function(v) Cfg.Final = tonumber(v) or 100 end })

    Essenciais:Toggle({ Flag = "JJsPular", Title = "Pular", Icon = "arrow-up", Desc = "Faz o avatar pular fisicamente a cada número enviado.", Value = Cfg.Pular == true, Callback = function(v) Cfg.Pular = v end })
    Essenciais:Toggle({ Flag = "JJsEspaco", Title = "Espaçamento", Desc = "Insere um espaço entre o número e o sufixo (\"1 !\" em vez de \"1!\").", Value = Cfg.Espacamento == true, Callback = function(v) Cfg.Espacamento = v end })

    -- ============================
    -- FORMATAÇÃO DE TEXTO
    -- ============================
    local Formatacao = WindowTab:Section({ Title = "Formatação de Texto", Desc = "O que aparece depois de cada número.", Icon = "type", Opened = false })

    Formatacao:Dropdown({
        Flag = "JJsSufixo", Title = "Sufixo", Desc = "Caractere padrão depois de cada número.",
        Values = { "!", ".", ",", "?", "Nenhum" }, Value = Cfg.Sufixo or "!",
        Callback = function(v) Cfg.Sufixo = v end,
    })
    Formatacao:Input({
        Flag = "JJsSufixoCustom", Title = "Sufixo customizado", PlaceholderText = "ex: @",
        Desc = "Digite qualquer símbolo pra usar no lugar do sufixo acima. Deixe vazio pra usar o de cima.",
        Value = Cfg.SufixoCustomizado or "",
        Callback = function(v) Cfg.SufixoCustomizado = v end,
    })

    -- ============================
    -- INTERVALO (só um modo fica ativo por vez)
    -- ============================
    local Intervalo = WindowTab:Section({ Title = "Intervalo", Desc = "Escolha só um: inteligente, fixo ou dinâmico.", Icon = "timer", Opened = false })

    local IntELToggle, IntFXToggle, IntDYToggle

    -- Guarda qual foi o último modo ligado — é ISSO que o AutoJJs.lua lê
    -- de verdade em tempo de execução, não os 3 toggles crus. Tenta
    -- também desmarcar os outros visualmente; se a versão da WindUI não
    -- tiver :SetValue, o pcall só falha em silêncio e a lógica continua
    -- correta mesmo assim.
    local function SetIntervalMode(mode)
        Cfg.IntervalMode = mode
        if mode ~= "Inteligente" and IntELToggle then pcall(function() IntELToggle:SetValue(false) end) end
        if mode ~= "Fixo" and IntFXToggle then pcall(function() IntFXToggle:SetValue(false) end) end
        if mode ~= "Dinamico" and IntDYToggle then pcall(function() IntDYToggle:SetValue(false) end) end
    end

    IntELToggle = Intervalo:Toggle({
        Flag = "JJsIntEl", Title = "Intervalo inteligente", Icon = "brain",
        Desc = "Calcula o delay pra contagem inteira terminar no tempo estipulado.",
        Value = Cfg.IntervalMode == "Inteligente",
        Callback = function(v)
            if v then SetIntervalMode("Inteligente")
            elseif Cfg.IntervalMode == "Inteligente" then Cfg.IntervalMode = nil end
        end,
    })
    Intervalo:Input({ Flag = "JJsIntElTempo", Title = "Tempo (segundos)", Desc = "Duração total da sequência inteira.", Value = tostring(Cfg.IntervaloInteligenteTempo or 60), Callback = function(v) Cfg.IntervaloInteligenteTempo = tonumber(v) or 60 end })

    IntFXToggle = Intervalo:Toggle({
        Flag = "JJsIntFx", Title = "Intervalo fixo", Icon = "equal",
        Desc = "Tempo de espera constante entre cada mensagem.",
        Value = Cfg.IntervalMode == "Fixo" or Cfg.IntervalMode == nil,
        Callback = function(v)
            if v then SetIntervalMode("Fixo")
            elseif Cfg.IntervalMode == "Fixo" then Cfg.IntervalMode = nil end
        end,
    })
    Intervalo:Slider({ Flag = "JJsIntFxVal", Title = "Intervalo fixo (segundos)", Desc = "Tempo exato entre mensagens.", Step = 0.1, Value = { Min = 0.2, Max = 10, Default = Cfg.IntervaloFixoValor or 1.4 }, Callback = function(v) Cfg.IntervaloFixoValor = v end })

    IntDYToggle = Intervalo:Toggle({
        Flag = "JJsIntDy", Title = "Intervalo dinâmico", Icon = "shuffle",
        Desc = "Delay aleatório entre repetições, pra simular digitação humana.",
        Value = Cfg.IntervalMode == "Dinamico",
        Callback = function(v)
            if v then SetIntervalMode("Dinamico")
            elseif Cfg.IntervalMode == "Dinamico" then Cfg.IntervalMode = nil end
        end,
    })
    Intervalo:Input({ Flag = "JJsIntDyMin", Title = "Valor mínimo (segundos)", Desc = "Menor tempo de espera possível.", Value = tostring(Cfg.IntervaloDinamicoMin or 1), Callback = function(v) Cfg.IntervaloDinamicoMin = tonumber(v) or 1 end })
    Intervalo:Input({ Flag = "JJsIntDyMax", Title = "Valor máximo (segundos)", Desc = "Maior tempo de espera possível.", Value = tostring(Cfg.IntervaloDinamicoMax or 3), Callback = function(v) Cfg.IntervaloDinamicoMax = tonumber(v) or 3 end })

    -- ============================
    -- EXTRAS
    -- ============================
    local Extras = WindowTab:Section({ Title = "Extras", Desc = "Ajustes adicionais.", Icon = "sparkles", Opened = false })
    Extras:Toggle({ Flag = "JJsReverso", Title = "Modo reverso", Icon = "rotate-ccw", Desc = "Inverte a contagem: começa no Final e desce até o Inicial.", Value = Cfg.ModoReverso == true, Callback = function(v) Cfg.ModoReverso = v end })
end

return Tab
