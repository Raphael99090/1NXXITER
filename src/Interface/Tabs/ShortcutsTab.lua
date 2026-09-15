local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Personalizaveis = WindowTab:Section({ Title = "Atalhos Personalizáveis", Desc = "Configure as teclas de acionamento do hub e funções essenciais.", Icon = "keyboard", Opened = true })

    local keys = {"LeftControl", "RightControl", "LeftShift", "RightShift", "LeftAlt", "RightAlt", "E", "Q", "F", "Z", "X", "C", "V", "B", "T", "G"}

    Personalizaveis:Dropdown({
        Flag = "UIToggleKey", Title = "Esconder / Mostrar Hub", Desc = "Tecla para abrir a interface. (Aplica após reinjetar o Hub).",
        Values = keys, Value = Config.UIToggleKey or "LeftControl", Callback = function(v) Config.UIToggleKey = v end
    })

    Personalizaveis:Dropdown({
        Flag = "AimKeyDropdown", Title = "Tecla do Aimbot", Desc = "A tecla para travar a mira (Apenas se o Combate 'Ativar por Tecla' estiver ativo).",
        Values = keys, Value = Config.AimKey or "E",
        Callback = function(v)
            Config.AimKey = v
            local enumKey = Enum.KeyCode[v]
            if enumKey and Hub.Features.Aimbot then Hub.Features.Aimbot.Settings.AimKey = enumKey end
        end
    })

    local initialEnumKey = Enum.KeyCode[Config.AimKey or "E"]
    if initialEnumKey and Hub.Features.Aimbot then Hub.Features.Aimbot.Settings.AimKey = initialEnumKey end
end

return Tab
