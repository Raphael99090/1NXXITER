local Grammar = {}
local HttpService = game:GetService("HttpService")
local TextChatService = game:GetService("TextChatService")

-- Diferentes executores expõem funções de request HTTP genérico com nomes
-- diferentes (game:HttpGet só faz GET, não serve pra chamar uma API
-- externa com POST/headers/body). Tenta achar qualquer uma disponível.
local function GetRequestFn()
    if http_request then return http_request end
    if request then return request end
    if syn and syn.request then return syn.request end
    if fluxus and fluxus.request then return fluxus.request end
    if http and http.request then return http.request end
    return nil
end

-- Modelo customizado (texto livre) sempre tem prioridade sobre o dropdown
-- — o Google renomeia/aposenta modelos do Gemini com frequência, então
-- isso evita depender só das opções fixas ficarem certas pra sempre.
local function ResolveModel(Config)
    if Config.ModeloCustomizado and Config.ModeloCustomizado ~= "" then
        return Config.ModeloCustomizado
    end
    return Config.Model or "gemini-3.1-flash-lite"
end

function Grammar:CorrectText(text, Config, callback)
    if not text or text:gsub("%s", "") == "" then
        callback(false, "Escreva algum texto antes de corrigir.")
        return
    end

    local apiKey = Config.ApiKey
    if not apiKey or apiKey == "" then
        callback(false, "Configure sua API Key do Gemini primeiro (seção Configuração).")
        return
    end

    local reqFn = GetRequestFn()
    if not reqFn then
        callback(false, "Seu executor não suporta requisições HTTP externas (precisa de http_request/request/syn.request).")
        return
    end

    local model = ResolveModel(Config)

    task.spawn(function()
        local url = "https://generativelanguage.googleapis.com/v1beta/models/" .. model .. ":generateContent?key=" .. apiKey

        local body = HttpService:JSONEncode({
            contents = {
                {
                    parts = {
                        { text = "Corrija a gramática, ortografia e pontuação do texto a seguir, mantendo o idioma e o sentido original. Responda APENAS com o texto corrigido — sem aspas, sem explicações, sem comentários extras:\n\n" .. text }
                    }
                }
            }
        })

        local ok, response = pcall(function()
            return reqFn({
                Url = url,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = body,
            })
        end)

        if not ok or not response then
            callback(false, "Falha na requisição: " .. tostring(response))
            return
        end

        local status = response.StatusCode or response.Status or response.statusCode or response.status
        local respBody = response.Body or response.body

        local decOk, data = pcall(function() return HttpService:JSONDecode(respBody) end)

        if status and status ~= 200 then
            local errMsg = (decOk and data and data.error and data.error.message) or tostring(respBody)
            callback(false, "Erro da API (" .. tostring(status) .. "): " .. tostring(errMsg))
            return
        end

        if not decOk or type(data) ~= "table" then
            callback(false, "Resposta inválida da API.")
            return
        end

        local resultText = nil
        pcall(function()
            resultText = data.candidates[1].content.parts[1].text
        end)

        if not resultText then
            local errMsg = (data.error and data.error.message)
                or "O modelo não retornou texto (pode ter sido bloqueado por segurança, ou o nome do modelo mudou — confira em ai.google.dev/gemini-api/docs/models)."
            callback(false, errMsg)
            return
        end

        callback(true, (resultText:gsub("^%s+", ""):gsub("%s+$", "")))
    end)
end

-- Mesmo método de detecção/envio de chat que já existia no Auto JJ's.
local usingTextChatService = false
pcall(function()
    usingTextChatService = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService
end)

function Grammar:SendToChat(message)
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

    return pcall(function()
        game:GetService("ReplicatedStorage")
            .DefaultChatSystemChatEvents
            .SayMessageRequest:FireServer(message, "All")
    end)
end

-- Sem conexões persistentes — cada correção é uma requisição pontual via
-- task.spawn que termina sozinha. Existe só por consistência com o
-- Lifecycle Manager (toda Feature tem Unload).
function Grammar:Unload()
end

return Grammar
