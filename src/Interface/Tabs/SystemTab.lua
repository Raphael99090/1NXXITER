local Tab = {}

local function IsPlaceholderLink(link)
    if not link or link == "" then return true end
    if link:find("SEU%-") or link:find("YOUR%-") or link:find("PLACEHOLDER") then return true end
    return false
end

local function CopyToClipboard(text)
    local copier = setclipboard or toclipboard
    if type(copier) ~= "function" then
        return false
    end

    local ok = pcall(copier, text)
    return ok
end

function Tab:Render(WindowTab, Hub, Config, State)
    local Utils = Hub.Core.Utils
    local StateMod = Hub.Core.State
    local WindUI = Hub.UI.Library

    WindowTab:Section({
        Title = "Aparência",
        Icon = "palette"
    })

    WindowTab:Dropdown({
        Flag = "UITheme",
        Title = "Tema",
        Values = (function()
            local names = {}
            for name in pairs(WindUI:GetThemes()) do
                table.insert(names, name)
            end
            table.sort(names)
            return names
        end)(),
        Value = WindUI:GetCurrentTheme(),
        Callback = function(v)
            WindUI:SetTheme(v)
            Config.UITheme = v
        end
    })

    WindowTab:Section({
        Title = "Gerenciamento",
        Icon = "folder-cog"
    })

    WindowTab:Button({
        Title = "SALVAR CONFIGURAÇÕES",
        Icon = "save",
        IconAlign = "Left",
        Callback = function()
            StateMod:SaveConfig(Config)
            WindUI:Notify({
                Title = "Salvo",
                Content = "JSON atualizado!",
                Icon = "check",
                Duration = 3
            })
        end
    })

    WindowTab:Button({
        Title = "RESTAURAR PADRÕES",
        Icon = "rotate-ccw",
        IconAlign = "Left",
        Callback = function()
            StateMod:ResetConfig(Config)
            StateMod:SaveConfig(Config)
            WindUI:Notify({
                Title = "Configurações restauradas",
                Content = "Reabra o hub pra ver os controles atualizados.",
                Icon = "refresh-cw",
                Duration = 5
            })
        end
    })

    WindowTab:Toggle({
        Flag = "AutoRejoinE",
        Title = "Auto-Rejoin (ao cair do servidor)",
        Value = Config.AutoRejoin or false,
        Callback = function(v)
            Config.AutoRejoin = v
        end
    })

    WindowTab:Section({
        Title = "Utilitários",
        Icon = "wrench"
    })

    WindowTab:Button({
        Title = "FPS BOOST",
        Icon = "zap",
        IconAlign = "Left",
        Callback = function()
            Utils:AntiLag()
        end
    })

    WindowTab:Button({
        Title = "REJOIN",
        Icon = "refresh-cw",
        IconAlign = "Left",
        Callback = function()
            Utils:Rejoin()
        end
    })

    WindowTab:Button({
        Title = "SERVER HOP",
        Icon = "globe",
        IconAlign = "Left",
        Callback = function()
            Utils:ServerHop()
        end
    })

    -- =========================================================
    -- DISCORD
    -- =========================================================

    WindowTab:Section({
        Title = "Discord",
        Icon = "messages-square"
    })

    WindowTab:Paragraph({
        Title = "Servidor do Discord",
        Desc = 'Entre na comunidade 1NXITER. Toque em "Copiar link" para copiar o convite.',
        Image = "https://cdn.simpleicons.org/discord",
        ImageSize = 28,
        Color = "White",
        Buttons = {
            {
                Title = "Copiar link",
                Icon = "copy",
                Variant = "Tertiary",
                Callback = function()
                    local DiscordLink = Config.DiscordLink

                    if IsPlaceholderLink(DiscordLink) then
                        WindUI:Notify({
                            Title = "Discord",
                            Content = "Configure Config.DiscordLink com o convite do servidor.",
                            Icon = "triangle-alert",
                            Duration = 4
                        })
                        return
                    end

                    if CopyToClipboard(DiscordLink) then
                        WindUI:Notify({
                            Title = "Discord",
                            Content = "Link copiado!",
                            Icon = "check",
                            Duration = 3
                        })
                    else
                        WindUI:Notify({
                            Title = "Discord",
                            Content = DiscordLink,
                            Icon = "copy",
                            Duration = 5
                        })
                    end
                end
            }
        }
    })

    WindowTab:Section({
        Title = "Sistema",
        Icon = "power"
    })

    WindowTab:Button({
        Title = "FECHAR HUB",
        Icon = "power",
        IconAlign = "Left",
        Callback = function()
            Hub:Unload()
            getgenv().InxiterHubLoaded = false
            getgenv().InxiterHubInstance = nil
        end
    })
end

return Tab
