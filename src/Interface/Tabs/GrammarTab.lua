local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.Grammar
    Config.Gramatica = Config.Gramatica or {}
    local Cfg = Config.Gramatica
    local WindUI = Hub.UI.Library

    if not Mod then
        WindowTab:Section({ Title = "⚠️ Gramática indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

    -- ============================
    -- CONFIGURAÇÃO
    -- ============================
    local Configuracao = WindowTab:Section({ Title = "Configuração", Desc = "Sua API Key do Gemini (grátis em aistudio.google.com/apikey).", Icon = "key", Opened = false })

    Configuracao:Input({
        Flag = "GramApiKey", Title = "API Key do Gemini", PlaceholderText = "Cole sua key aqui",
        Desc = "Fica salva localmente no seu celular, em texto puro.",
        Value = Cfg.ApiKey or "",
        Callback = function(v) Cfg.ApiKey = v end,
    })

    Configuracao:Dropdown({
        Flag = "GramModel", Title = "Modelo", Desc = "Modelos leves e gratuitos do Gemini.",
        Values = { "gemini-3.1-flash-lite", "gemini-2.5-flash-lite" },
        Value = Cfg.Model or "gemini-3.1-flash-lite",
        Callback = function(v) Cfg.Model = v end,
    })

    Configuracao:Input({
        Flag = "GramModelCustom", Title = "Modelo customizado", PlaceholderText = "ex: gemini-3-flash",
        Desc = "O Google renomeia os modelos com frequência — se o de cima parar de funcionar, digite o ID atual aqui (tem prioridade sobre o dropdown).",
        Value = Cfg.ModeloCustomizado or "",
        Callback = function(v) Cfg.ModeloCustomizado = v end,
    })

    -- ============================
    -- RESULTADO (sempre visível)
    -- ============================
    local Status = WindowTab:Section({ Title = "Resultado", Desc = "Nada corrigido ainda.", Opened = true })

    -- ============================
    -- CORRETOR
    -- ============================
    local Corretor = WindowTab:Section({ Title = "Corretor", Desc = "Escreva o texto e corrija.", Icon = "spell-check", Opened = true })

    local currentText = ""
    local correctedText = nil

    Corretor:Input({
        Flag = "GramText", Title = "Texto",
        PlaceholderText = "Escreve aqui o que quer corrigir...",
        Desc = "Cole ou digite o texto. (O campo da WindUI é de uma linha só — texto longo funciona, só não quebra linha visualmente.)",
        Value = "",
        Callback = function(v) currentText = v; correctedText = nil end,
    })

    Corretor:Button({ Title = "CORRIGIR", Icon = "spell-check", Callback = function()
        if currentText == "" then
            WindUI:Notify({Title="Gramática", Content="Escreve algum texto primeiro.", Duration=3})
            return
        end
        Status:SetDesc("Corrigindo...")
        Mod:CorrectText(currentText, Cfg, function(ok, result)
            if ok then
                correctedText = result
                Status:SetDesc("✅ " .. result)
            else
                Status:SetDesc("❌ Erro ao corrigir — veja a notificação.")
                WindUI:Notify({Title="Erro ao corrigir", Content=tostring(result), Duration=6})
            end
        end)
    end })

    Corretor:Button({ Title = "COPIAR", Icon = "copy", Callback = function()
        local textToCopy = correctedText or currentText
        if textToCopy == "" then
            WindUI:Notify({Title="Gramática", Content="Nada pra copiar ainda.", Duration=3})
            return
        end
        local copier = setclipboard or toclipboard
        if type(copier) == "function" then
            pcall(copier, textToCopy)
            WindUI:Notify({Title="Copiado", Content="Texto copiado pra área de transferência.", Duration=3})
        else
            WindUI:Notify({Title="Gramática", Content="Seu executor não suporta copiar.", Duration=4})
        end
    end })

    Corretor:Button({ Title = "ENVIAR NO CHAT", Icon = "send", Callback = function()
        local textToSend = correctedText or currentText
        if textToSend == "" then
            WindUI:Notify({Title="Gramática", Content="Nada pra enviar ainda.", Duration=3})
            return
        end
        local ok = Mod:SendToChat(textToSend)
        if ok then
            WindUI:Notify({Title="Enviado", Content="Mandado no chat.", Duration=3})
        else
            WindUI:Notify({Title="Erro", Content="Falha ao enviar no chat.", Duration=4})
        end
    end })
end

return Tab
