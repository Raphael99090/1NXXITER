import sys

with open("src/main.lua", "r") as f:
    content = f.read()

start_marker = "local function RequestKey(onSuccess)"
end_marker = "-- [3] ESTRUTURA CENTRAL (Tabela Hub)"

start_idx = content.find(start_marker)
end_idx = content.find(end_marker)

if start_idx == -1 or end_idx == -1:
    print("Markers not found")
    sys.exit(1)

new_code = """local function RequestKey(onSuccess)
    local hwid = GetHWID()
    
    local success, WindUI = pcall(function()
        return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
    end)

    if not success or not WindUI then
        warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI para o Key System.")
        return
    end

    local Window = WindUI:CreateWindow({
        Title = "1NXITER HUB",
        Author = "Panda Key System",
        Icon = "key",
        Folder = "InxiterHub",
        Size = UDim2.fromOffset(450, 320),
        OpenButton = false,
        Transparent = true,
        Theme = "Dark"
    })

    local Tab = Window:Tab({ Title = "Autenticação", Icon = "lock" })
    
    local KeyInput = ""

    Tab:Input({
        Title = "Insira sua Key",
        Desc = "Cole a key gerada pelo Panda Auth abaixo.",
        PlaceholderText = "Cole aqui...",
        Callback = function(text)
            KeyInput = text
        end
    })

    Tab:Button({
        Title = "Obter Key (Copiar Link)",
        Desc = "Copia o link para o seu navegador.",
        Icon = "link",
        Callback = function()
            local pandaUrl = PANDA_GETKEY_BASE .. "?hwid=" .. hwid
            local copier = setclipboard or toclipboard
            if type(copier) == "function" then
                pcall(copier, pandaUrl)
                WindUI:Notify({Title = "Key System", Content = "Link copiado para a área de transferência!", Duration = 3})
            else
                WindUI:Notify({Title = "Key System", Content = "Abra: " .. pandaUrl, Duration = 5})
            end
        end
    })
    
    Tab:Button({
        Title = "Copiar HWID",
        Desc = hwid,
        Icon = "copy",
        Callback = function()
            local copier = setclipboard or toclipboard
            if type(copier) == "function" then
                pcall(copier, hwid)
                WindUI:Notify({Title = "Key System", Content = "HWID copiado!", Duration = 3})
            end
        end
    })

    local checking = false
    Tab:Button({
        Title = "Validar e Entrar",
        Icon = "check",
        Callback = function()
            if checking then return end
            if KeyInput == "" then
                WindUI:Notify({Title = "Aviso", Content = "Insira sua key antes de confirmar.", Duration = 3})
                return
            end

            checking = true
            WindUI:Notify({Title = "Key System", Content = "Verificando key...", Duration = 2})

            CheckKey(KeyInput, function(valid, errorMsg)
                checking = false
                if valid then
                    WindUI:Notify({Title = "Sucesso", Content = "Key validada! Carregando Hub...", Duration = 2})
                    task.wait(1.5)
                    pcall(function() Window:Destroy() end)
                    onSuccess()
                else
                    WindUI:Notify({Title = "Erro", Content = errorMsg or "Key inválida. Tente novamente.", Duration = 4})
                end
            end)
        end
    })
    
    Tab:Select()
end

"""

new_content = content[:start_idx] + new_code + content[end_idx:]

with open("src/main.lua", "w") as f:
    f.write(new_content)

print("Replacement successful")
