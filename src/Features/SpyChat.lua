local SpyChat = {}
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local TextChatService = game:GetService("TextChatService")

SpyChat.Enabled = false
SpyChat.Gui = nil
SpyChat.Minimized = false
SpyChat.Connections = {}

-- [ AUXILIAR: ARRASTE ]
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- [ FUNÇÃO: ADICIONAR MENSAGEM ]
local function EscapeRichText(s)
    -- Sem isso, uma mensagem com < ou > quebra a formatação RichText do
    -- próprio painel de log (só afeta sua tela, mas ainda é um bug visual).
    s = tostring(s)
    s = s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub("\"", "&quot;")
    return s
end

function SpyChat:LogMessage(pName, msg)
    if not self.Gui or not self.Enabled then return end
    local scroll = self.Gui.Main.Content.Scroll
    
    local label = Instance.new("TextLabel")
    label.Name = pName -- Usado para o filtro de busca
    label.Parent = scroll
    label.Size = UDim2.new(1, -10, 0, 20)
    label.BackgroundTransparency = 1
    label.RichText = true
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Font = Enum.Font.Code
    label.TextSize = 14
    label.TextColor3 = Color3.new(1,1,1)
    label.Text = string.format(
        "<font color='#AAAAAA'>[%s]</font> <font color='#00E5FF'><b>%s:</b></font> %s",
        os.date("%X"), EscapeRichText(pName), EscapeRichText(msg)
    )
    label.AutomaticSize = Enum.AutomaticSize.Y
    label.TextWrapped = true
end

-- [ FUNÇÃO: FILTRAR USUÁRIO ]
function SpyChat:Filter(text)
    local scroll = self.Gui.Main.Content.Scroll
    local query = text:lower()
    for _, child in pairs(scroll:GetChildren()) do
        if child:IsA("TextLabel") then
            child.Visible = child.Name:lower():find(query) and true or false
        end
    end
end

function SpyChat:Toggle(state)
    self.Enabled = state
    if state then
        -- [ CRIAÇÃO DA UI ESTILO HD ADMIN ]
        local sg = Instance.new("ScreenGui", CoreGui); sg.Name = "InxiterSpyHUD"
        self.Gui = sg

        local main = Instance.new("Frame", sg)
        main.Name = "Main"
        main.Size = UDim2.new(0, 400, 0, 250)
        main.Position = UDim2.new(0.5, -200, 0.5, -125)
        main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        main.BackgroundTransparency = 0.1
        main.BorderSizePixel = 0

        local top = Instance.new("Frame", main)
        top.Name = "Top"
        top.Size = UDim2.new(1, 0, 0, 30)
        top.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
        top.BorderSizePixel = 0
        MakeDraggable(main, top)

        local title = Instance.new("TextLabel", top)
        title.Text = "  CHAT LOGS (HD ADMIN STYLE)"
        title.Size = UDim2.new(1, -80, 1, 0)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.new(1,1,1)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 12
        title.TextXAlignment = Enum.TextXAlignment.Left

        -- Botões Fechar/Minimizar
        local close = Instance.new("TextButton", top)
        close.Text = "X"; close.Size = UDim2.new(0, 30, 1, 0); close.Position = UDim2.new(1, -30, 0, 0)
        close.BackgroundColor3 = Color3.fromRGB(150, 0, 0); close.TextColor3 = Color3.new(1,1,1)
        close.MouseButton1Click:Connect(function() self:Toggle(false) end)

        local mini = Instance.new("TextButton", top)
        mini.Text = "-"; mini.Size = UDim2.new(0, 30, 1, 0); mini.Position = UDim2.new(1, -60, 0, 0)
        mini.BackgroundColor3 = Color3.fromRGB(40, 40, 40); mini.TextColor3 = Color3.new(1,1,1)
        mini.MouseButton1Click:Connect(function()
            self.Minimized = not self.Minimized
            main.Content.Visible = not self.Minimized
            main.Size = self.Minimized and UDim2.new(0, 400, 0, 30) or UDim2.new(0, 400, 0, 250)
        end)

        local content = Instance.new("Frame", main)
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -30)
        content.Position = UDim2.new(0, 0, 0, 30)
        content.BackgroundTransparency = 1

        local search = Instance.new("TextBox", content)
        search.PlaceholderText = "Pesquisar usuário..."
        search.Size = UDim2.new(1, -20, 0, 25)
        search.Position = UDim2.new(0, 10, 0, 5)
        search.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
        search.TextColor3 = Color3.new(1,1,1)
        search.BorderSizePixel = 0
        search:GetPropertyChangedSignal("Text"):Connect(function() self:Filter(search.Text) end)

        local scroll = Instance.new("ScrollingFrame", content)
        scroll.Name = "Scroll"
        scroll.Size = UDim2.new(1, -20, 1, -45)
        scroll.Position = UDim2.new(0, 10, 0, 35)
        scroll.BackgroundTransparency = 1
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.ScrollBarThickness = 2
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local layout = Instance.new("UIListLayout", scroll)
        layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 5)

        -- [ CAPTURA DE CHAT ]
        -- Em jogos que já usam TextChatService, Player.Chatted normalmente
        -- ainda dispara por compatibilidade — hookar os dois duplicava
        -- cada mensagem no log. Agora é um ou outro, nunca os dois.
        local usingTextChatService = TextChatService.ChatVersion == Enum.ChatVersion.TextChatService

        if not usingTextChatService then
            local function hook(p)
                local c = p.Chatted:Connect(function(m) self:LogMessage(p.Name, m) end)
                table.insert(self.Connections, c)
            end
            for _, p in pairs(Players:GetPlayers()) do hook(p) end
            table.insert(self.Connections, Players.PlayerAdded:Connect(hook))
        else
            local c = TextChatService.MessageReceived:Connect(function(res)
                if res.TextSource then self:LogMessage(res.TextSource.DisplayName, res.Text) end
            end)
            table.insert(self.Connections, c)
        end
    else
        if self.Gui then self.Gui:Destroy(); self.Gui = nil end
        for _, c in pairs(self.Connections) do c:Disconnect() end
        self.Connections = {}
    end
end

return SpyChat
