local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    WindowTab:Section({ Title = "Atalhos Personalizáveis", Desc = "Configure as teclas de acionamento do hub e funções essenciais.", Icon = "keyboard" })

    local keys = {"LeftControl", "RightControl", "LeftShift", "RightShift", "LeftAlt", "RightAlt", "E", "Q", "F", "Z", "X", "C", "V", "B", "T", "G"}

    WindowTab:Dropdown({
        Flag = "UIToggleKey", Title = "Esconder / Mostrar Hub", Desc = "Tecla para abrir a interface. (Aplica após reinjetar o Hub).",
        Values = keys, Value = Config.UIToggleKey or "LeftControl", Callback = function(v) Config.UIToggleKey = v end
    })

    WindowTab:Dropdown({
        Flag = "AimKeyDropdown", Title = "Tecla do Aimbot", Desc = "A tecla para travar a mira (Apenas se o Combate 'Ativar por Tecla' estiver ativo).",
        Values = keys, Value = Config.AimKey or "E",
        Callback = function(v)
            Config.AimKey = v
            local enumKey = Enum.KeyCode[v]
            if enumKey then Hub.Features.Aimbot.Settings.AimKey = enumKey end
        end
    })
    
    local initialEnumKey = Enum.KeyCode[Config.AimKey or "E"]
    if initialEnumKey then Hub.Features.Aimbot.Settings.AimKey = initialEnumKey end

    WindowTab:Section({ Title = "Atalhos Fixos (Referência)", Desc = "Controles que não podem ser alterados no momento.", Icon = "info" })
    
    WindowTab:Paragraph({
        Title = "✈️ Fly (Voo)",
        Desc = "• W, A, S, D ou Joystick para mover.\n• Espaço para subir.\n• Ctrl (Control) para descer.\n• Botão de Pulo (Mobile) dá um empurrão para cima.",
        Color = "White"
    })
    
    WindowTab:Paragraph({
        Title = "🎥 Câmera Livre (FreeCam)",
        Desc = "• Arraste a tela ou mova o mouse para olhar.\n• W, A, S, D para mover.\n• E para subir, Q para descer.\n• Shift esquerdo para voar rápido.",
        Color = "White"
    })
end

return Tab
