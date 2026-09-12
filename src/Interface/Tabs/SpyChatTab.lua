local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Spy = Hub.Features.SpyChat
    Config.SpyChat = Config.SpyChat or {}
    local Cfg = Config.SpyChat

    if not Spy then
        WindowTab:Section({ Title = "⚠️ Spy Chat indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

    WindowTab:Section({ Title = "Spy Chat", Desc = "Lê chat privado e comandos do servidor em uma UI arrastável.", Icon = "message-square-more" })
    WindowTab:Toggle({
        Flag = "SpyE", Title = "Ativar Spy Chat", Icon = "message-square-more",
        Desc = "Mostra mensagens que normalmente só quem está por perto veria.",
        Value = Cfg.Enabled == true,
        Callback = function(v) Cfg.Enabled = v; Spy:Toggle(v) end,
    })
end

return Tab
