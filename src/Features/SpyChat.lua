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
-- Antes conectava direto em UserInputService.InputChanged sem guardar a conexão:
-- toda vez que Toggle(true) recriava a UI, uma nova conexão global era empilhada
-- por cima das antigas, que nunca eram desconectadas (vazamento a cada toggle).
-- Agora devolve as conexões pra quem chamou registrar em self.Connections.
local function MakeDraggable(frame, handle)
    local dragging, dragStart, startPos
    local conns = {}

    table.insert(conns, handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = frame.Position
            local changedConn
            changedConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if changedConn then changedConn:Disconnect() end
                end
            end)
            table.insert(conns, changedConn)
        end
    end))

    table.insert(conns, UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))

    return conns
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
        -- [ CRIAÇÃO DA UI ESTILO MODERNO ]
        local sg = Instance.new("ScreenGui", CoreGui); sg.Name = "InxiterSpyHUD"
        self.Gui = sg

        local main = Instance.new("Frame", sg)
        main.Name = "Main"
        main.Size = UDim2.new(0, 420, 0, 280)
        main.Position = UDim2.new(0.5, -210, 0.5, -140)
        main.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        main.BackgroundTransparency = 0.15
        main.BorderSizePixel = 0
        main.ClipsDescendants = true
        
        local mainCorner = Instance.new("UICorner", main)
        mainCorner.CornerRadius = UDim.new(0, 8)
        
        local mainStroke = Instance.new("UIStroke", main)
        mainStroke.Color = Color3.fromRGB(60, 60, 60)
        mainStroke.Thickness = 1

        local top = Instance.new("Frame", main)
        top.Name = "Top"
        top.Size = UDim2.new(1, 0, 0, 35)
        top.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        top.BorderSizePixel = 0
        for _, c in pairs(MakeDraggable(main, top)) do
            if c then table.insert(self.Connections, c) end
        end
        
        local topSeparator = Instance.new("Frame", top)
        topSeparator.Size = UDim2.new(1, 0, 0, 1)
        topSeparator.Position = UDim2.new(0, 0, 1, 0)
        topSeparator.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        topSeparator.BorderSizePixel = 0

        local title = Instance.new("TextLabel", top)
        title.Text = "  SPY CHAT LOGS"
        title.Size = UDim2.new(1, -50, 1, 0)
        title.BackgroundTransparency = 1
        title.TextColor3 = Color3.fromRGB(220, 220, 220)
        title.Font = Enum.Font.GothamBold
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        -- Apenas Botão Minimizar (Para fechar de verdade, use o Toggle no Hub para não dessincronizar)
        local mini = Instance.new("TextButton", top)
        mini.Text = "-"
        mini.Size = UDim2.new(0, 30, 0, 30)
        mini.Position = UDim2.new(1, -35, 0.5, -15)
        mini.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
        mini.TextColor3 = Color3.new(1,1,1)
        mini.Font = Enum.Font.GothamBold
        mini.TextSize = 14
        
        local miniCorner = Instance.new("UICorner", mini)
        miniCorner.CornerRadius = UDim.new(0, 6)
        
        mini.MouseButton1Click:Connect(function()
            self.Minimized = not self.Minimized
            main.Content.Visible = not self.Minimized
            main.Size = self.Minimized and UDim2.new(0, 420, 0, 35) or UDim2.new(0, 420, 0, 280)
        end)

        local content = Instance.new("Frame", main)
        content.Name = "Content"
        content.Size = UDim2.new(1, 0, 1, -35)
        content.Position = UDim2.new(0, 0, 0, 35)
        content.BackgroundTransparency = 1

        local search = Instance.new("TextBox", content)
        search.PlaceholderText = "Pesquisar usuário..."
        search.Size = UDim2.new(1, -20, 0, 30)
        search.Position = UDim2.new(0, 10, 0, 10)
        search.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        search.TextColor3 = Color3.fromRGB(220, 220, 220)
        search.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
        search.Font = Enum.Font.Gotham
        search.TextSize = 13
        search.BorderSizePixel = 0
        search:GetPropertyChangedSignal("Text"):Connect(function() self:Filter(search.Text) end)
        
        local searchCorner = Instance.new("UICorner", search)
        searchCorner.CornerRadius = UDim.new(0, 6)
        
        local searchPadding = Instance.new("UIPadding", search)
        searchPadding.PaddingLeft = UDim.new(0, 10)

        local scroll = Instance.new("ScrollingFrame", content)
        scroll.Name = "Scroll"
        scroll.Size = UDim2.new(1, -20, 1, -60)
        scroll.Position = UDim2.new(0, 10, 0, 50)
        scroll.BackgroundTransparency = 1
        scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        scroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
        scroll.ScrollBarThickness = 4
        scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        
        local layout = Instance.new("UIListLayout", scroll)
        layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 5)

        -- [ CAPTURA DE CHAT ]
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
                if res.TextSource then 
                    local sender = Players:GetPlayerByUserId(res.TextSource.UserId)
                    local pName = sender and sender.Name or "Desconhecido"
                    self:LogMessage(pName, res.Text) 
                end
            end)
            table.insert(self.Connections, c)
        end
    else
        if self.Gui then self.Gui:Destroy(); self.Gui = nil end
        for _, c in pairs(self.Connections) do c:Disconnect() end
        self.Connections = {}
    end
end

function SpyChat:Unload()
    self:Toggle(false)
end

return SpyChat
