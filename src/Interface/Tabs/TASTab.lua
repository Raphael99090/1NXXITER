local Tab = {}

function Tab:Render(WindowTab, Hub, Config, State)
    local Mod = Hub.Features.TASRecorder
    Config.TAS = Config.TAS or {}
    local Cfg = Config.TAS
    local WindUI = Hub.UI.Library

    if not Mod then
        WindowTab:Section({ Title = "⚠️ TAS indisponível", Desc = "O módulo falhou ao carregar nessa sessão. Veja o Diagnóstico na aba Sistema ou o console (F9).", Icon = "alert-triangle" })
        return
    end

    -- ============================
    -- GRAVAÇÃO
    -- ============================
    WindowTab:Section({ Title = "Gravação", Desc = "Grava seu trajeto pra reproduzir depois.", Icon = "circle-dot" })

    local RecordName = "trajeto"
    WindowTab:Input({
        Title = "Nome da gravação",
        Value = RecordName,
        PlaceholderText = "ex: rota_treino",
        Callback = function(text) RecordName = text end,
    })

    local RecStatus = WindowTab:Section({ Title = "Status", Desc = "Parado." })

    task.spawn(function()
        while getgenv().InxiterHubLoaded do
            if Mod:IsRecording() then
                local info = Mod:GetRecordingInfo()
                RecStatus:SetDesc(string.format("🔴 Gravando... %.0fs (%d pontos)", info and info.seconds or 0, info and info.points or 0))
            elseif Mod:IsPlaying() then
                RecStatus:SetDesc("▶️ Reproduzindo o trajeto gravado...")
            else
                local hasGhost, ghostName = Mod:HasGhost()
                if hasGhost then
                    RecStatus:SetDesc((Cfg.ReproduzirArmed and "🟢 Fantasma pronto (\"%s\") — entra nele pra reproduzir." or "⚪ Fantasma pronto (\"%s\") — reproduzir desligado no toggle abaixo."):format(ghostName))
                else
                    RecStatus:SetDesc("Parado. Nenhum fantasma preparado.")
                end
            end
            task.wait(1)
        end
    end)

    WindowTab:Button({ Title = "INICIAR GRAVAÇÃO", Icon = "circle-dot", Callback = function()
        local ok, err = Mod:StartRecording()
        if ok then
            WindUI:Notify({Title="Gravação", Content="Começou! Anda pelo trajeto e depois clica em Parar e Salvar.", Duration=4})
        else
            WindUI:Notify({Title="Gravação", Content=err, Duration=4})
        end
    end })

    WindowTab:Button({ Title = "PARAR E SALVAR", Icon = "save", Callback = function()
        local ok, result = Mod:SaveRecording(RecordName)
        if ok then
            WindUI:Notify({Title="Gravação salva", Content="Salvo como \"" .. result .. "\".", Duration=4})
        else
            WindUI:Notify({Title="Erro ao salvar", Content=result, Duration=4})
        end
    end })

    WindowTab:Button({ Title = "Cancelar gravação", Icon = "x", Callback = function()
        if Mod:IsRecording() then
            Mod:StopRecording()
            WindUI:Notify({Title="Gravação", Content="Cancelada, nada foi salvo.", Duration=3})
        end
    end })

    -- ============================
    -- REPRODUÇÃO
    -- ============================
    WindowTab:Section({ Title = "Reprodução", Desc = "Escolhe um trajeto salvo e prepara o fantasma.", Icon = "footprints" })

    WindowTab:Toggle({
        Flag = "TASArmed", Title = "Ativar Reproduzir", Icon = "play",
        Desc = "Enquanto ligado, entrar dentro do fantasma dispara o replay sozinho.",
        Value = Cfg.ReproduzirArmed == true,
        Callback = function(v) Cfg.ReproduzirArmed = v; Mod.Settings.ReproduzirArmed = v end,
    })

    local SelectedRecording = nil
    local RecDropdown = WindowTab:Dropdown({
        Flag = "TASSelected", Title = "Gravações salvas",
        Values = Mod:ListRecordings(),
        SearchBarEnabled = true,
        Callback = function(v) SelectedRecording = v end,
    })

    WindowTab:Button({ Title = "Atualizar lista", Icon = "refresh-cw", Callback = function()
        RecDropdown:Refresh(Mod:ListRecordings())
    end })

    WindowTab:Button({ Title = "PREPARAR FANTASMA", Icon = "ghost", Callback = function()
        if not SelectedRecording then
            WindUI:Notify({Title="Reprodução", Content="Escolhe uma gravação na lista primeiro.", Duration=3})
            return
        end
        local ok, err = Mod:PrepareGhost(SelectedRecording)
        if ok then
            WindUI:Notify({Title="Fantasma pronto", Content="Apareceu no início do trajeto \"" .. SelectedRecording .. "\".", Duration=4})
        else
            WindUI:Notify({Title="Erro", Content=err, Duration=4})
        end
    end })

    WindowTab:Button({ Title = "Remover fantasma", Icon = "eraser", Callback = function()
        Mod:RemoveGhost()
        WindUI:Notify({Title="Reprodução", Content="Fantasma removido.", Duration=3})
    end })

    WindowTab:Button({ Title = "Parar reprodução", Icon = "square", Callback = function()
        if Mod:IsPlaying() then
            Mod:StopPlayback()
            WindUI:Notify({Title="Reprodução", Content="Interrompida — controle devolvido.", Duration=3})
        end
    end })

    WindowTab:Button({ Title = "Apagar gravação selecionada", Icon = "trash-2", Callback = function()
        if not SelectedRecording then
            WindUI:Notify({Title="Reprodução", Content="Escolhe uma gravação na lista primeiro.", Duration=3})
            return
        end
        local Window = Hub.UI.Window
        local nameToDelete = SelectedRecording
        local function DoDelete()
            Mod:DeleteRecording(nameToDelete)
            RecDropdown:Refresh(Mod:ListRecordings())
            WindUI:Notify({Title="Apagado", Content="\"" .. nameToDelete .. "\" foi apagado.", Duration=3})
        end
        if Window and Window.Dialog then
            Window:Dialog({
                Title = "Apagar gravação?",
                Content = "\"" .. nameToDelete .. "\" vai ser apagada pra sempre.",
                Buttons = {
                    { Title = "Cancelar", Variant = "Tertiary" },
                    { Title = "Apagar", Variant = "Primary", Callback = DoDelete },
                }
            })
        else
            DoDelete()
        end
    end })
end

return Tab
