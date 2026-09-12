local TASRecorder = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

TASRecorder.Settings = {
    ReproduzirArmed = false, -- se true, entrar no fantasma dispara o replay sozinho
}

local FOLDER = "1NXITER_HUB/TAS"
local RECORD_INTERVAL = 0.15 -- segundos entre cada ponto gravado
local TRIGGER_RADIUS = 3.5 -- "dentro do fantasma" ~ tamanho de um personagem

local JUMP_STATES = { Jumping = true }

-- Gravação em andamento
local Recording = false
local RecordConn = nil
local RecordBuffer = nil

-- Fantasma ativo (só um marcador parado — não anda, não é tocável)
local GhostModel = nil
local GhostData = nil -- { start={c=...}, waypoints={ {t,cf,cc,st}, ... }, cumDist={...} }
local GhostFilename = nil
local GhostLabel = nil
local GhostProximityConn = nil
local RouteFolder = nil

-- Reprodução em andamento (agora é o PRÓPRIO jogador que anda o caminho)
local Playing = false
local PlayToken = 0
local LockedControls = nil
local PlayerProgressBillboard = nil

-- Referência opcional pro Hub inteiro — só usada pra suspender outras
-- Features que também disputam o controle da câmera (Aimbot Silent Aim,
-- FreeCam) enquanto o replay roda. Setada de fora via SetHub(); sem ela,
-- TAS continua funcionando normalmente sozinho (fica só sem suspender
-- ninguém, o que já era o comportamento antigo).
local HubRef = nil
local SuspendedAimbot = nil
local SuspendedFreeCam = nil

local function HasFileSystem()
    return isfile and readfile and writefile and makefolder and isfolder and listfiles
end

local function GetCharacter() return LocalPlayer.Character end
local function GetHumanoid()
    local char = GetCharacter()
    return char and char:FindFirstChildOfClass("Humanoid")
end
local function GetRoot()
    local char = GetCharacter()
    return char and char:FindFirstChild("HumanoidRootPart")
end
local function GetCamera()
    return workspace.CurrentCamera
end

-- Chamado uma vez pelo main.lua depois que todas as Features carregam.
function TASRecorder:SetHub(hub)
    HubRef = hub
end

-- Aimbot (Silent Aim) e FreeCam também fazem CameraType=Scriptable e
-- escrevem Camera.CFrame toda frame — sem suspender os dois durante o
-- replay, eles brigam pelo controle da câmera com o TAS (tremedeira, e
-- pior: podem sequestrar a câmera de volta bem depois do TAS já ter
-- devolvido o controle). Guarda o estado anterior pra restaurar depois.
local function SuspendCompetingCamera()
    if not HubRef or not HubRef.Features then return end

    local aim = HubRef.Features.Aimbot
    if aim and aim.Settings and aim.Settings.Enabled then
        SuspendedAimbot = true
        aim.Settings.Enabled = false
    end

    local freecam = HubRef.Features.FreeCam
    if freecam and freecam.Settings and freecam.Settings.Enabled and freecam.Toggle then
        SuspendedFreeCam = true
        pcall(function() freecam:Toggle(false) end)
    end
end

local function RestoreCompetingCamera()
    if not HubRef or not HubRef.Features then
        SuspendedAimbot, SuspendedFreeCam = nil, nil
        return
    end

    if SuspendedAimbot then
        local aim = HubRef.Features.Aimbot
        if aim and aim.Settings then aim.Settings.Enabled = true end
        SuspendedAimbot = nil
    end

    if SuspendedFreeCam then
        local freecam = HubRef.Features.FreeCam
        if freecam and freecam.Toggle then pcall(function() freecam:Toggle(true) end) end
        SuspendedFreeCam = nil
    end
end

-- ======================================================
-- PROTEÇÃO CONTRA SOFTLOCK (morte / respawn durante o replay)
-- ======================================================
-- Se o jogador morrer ou der reset com a reprodução ativa, a câmera
-- fica travada em Scriptable e o controle desabilitado apontando pra um
-- Humanoid/PlayerModule que já era — sem isso o jogador ficaria preso
-- pra sempre. CharacterRemoving cobre morte, reset e respawn (o
-- personagem antigo é sempre removido nesses casos), e continua válido
-- pra sempre porque é um evento do Player, não do Character.
local CharacterRemovingConn = LocalPlayer.CharacterRemoving:Connect(function()
    if Playing then
        TASRecorder:StopPlayback()
    end
end)

-- ======================================================
-- GRAVAÇÃO
-- ======================================================
function TASRecorder:StartRecording()
    if Recording then return false, "Já tem uma gravação em andamento." end
    if Playing then return false, "Termina ou para a reprodução atual antes de gravar de novo." end
    local root = GetRoot()
    if not root then return false, "Seu personagem não existe ainda." end

    RecordBuffer = {}
    local startTick = os.clock()
    local lastSample = -RECORD_INTERVAL

    RecordConn = RunService.Heartbeat:Connect(function()
        local r = GetRoot()
        local cam = GetCamera()
        if not r or not cam then return end
        local elapsed = os.clock() - startTick
        if elapsed - lastSample < RECORD_INTERVAL then return end
        lastSample = elapsed

        local hum = GetHumanoid()
        local stateName = "Running"
        if hum then
            local ok, state = pcall(function() return hum:GetState() end)
            if ok and state then stateName = state.Name end
        end

        table.insert(RecordBuffer, {
            t = elapsed,
            cf = { r.CFrame:GetComponents() },  -- CFrame do personagem (posição + rotação)
            cc = { cam.CFrame:GetComponents() }, -- CFrame da câmera (obrigatório, sempre gravado)
            st = stateName,                      -- estado do Humanoid (anda/pula/cai)
        })
    end)

    Recording = true
    return true
end

-- Para a gravação sem salvar (descarta o buffer).
function TASRecorder:StopRecording()
    if RecordConn then RecordConn:Disconnect(); RecordConn = nil end
    Recording = false
    RecordBuffer = nil
end

function TASRecorder:IsRecording()
    return Recording
end

function TASRecorder:GetRecordingInfo()
    if not Recording or not RecordBuffer then return nil end
    return { points = #RecordBuffer, seconds = #RecordBuffer * RECORD_INTERVAL }
end

local function SanitizeName(name)
    name = tostring(name or ""):gsub("[^%w%-_ ]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    if name == "" then name = "trajeto_" .. os.date("%H%M%S") end
    return name
end

function TASRecorder:SaveRecording(name)
    if not Recording or not RecordBuffer then return false, "Nenhuma gravação em andamento." end
    if #RecordBuffer < 2 then
        self:StopRecording()
        return false, "Gravação curta demais (anda um pouco antes de parar)."
    end
    if not HasFileSystem() then
        self:StopRecording()
        return false, "Seu executor não suporta arquivos."
    end

    local root = GetRoot()
    local startCFrame = root and root.CFrame or CFrame.new()
    local buffer = RecordBuffer
    self:StopRecording()

    local data = {
        start = { c = { startCFrame:GetComponents() } },
        waypoints = buffer,
    }

    local fileName = SanitizeName(name)
    local ok, err = pcall(function()
        if not isfolder(FOLDER) then makefolder(FOLDER) end
        writefile(FOLDER .. "/" .. fileName .. ".tas", HttpService:JSONEncode(data))
    end)

    if not ok then return false, "Erro ao salvar: " .. tostring(err) end
    return true, fileName
end

-- ======================================================
-- LISTAGEM / EXCLUSÃO
-- ======================================================
function TASRecorder:ListRecordings()
    if not HasFileSystem() or not isfolder(FOLDER) then return {} end

    local ok, files = pcall(listfiles, FOLDER)
    if not ok or type(files) ~= "table" then return {} end

    local names = {}
    for _, path in ipairs(files) do
        local fname = path:match("([^/\\]+)$")
        if fname and fname:match("%.tas$") then
            table.insert(names, (fname:gsub("%.tas$", "")))
        end
    end
    table.sort(names)
    return names
end

function TASRecorder:DeleteRecording(name)
    if not HasFileSystem() then return false end
    local path = FOLDER .. "/" .. SanitizeName(name) .. ".tas"
    local ok = pcall(function()
        if isfile(path) and delfile then delfile(path) end
    end)
    if GhostFilename == name then self:RemoveGhost() end
    return ok
end

-- ======================================================
-- HELPERS DE CFRAME / DISTÂNCIA / ANIMAÇÃO
-- ======================================================
local function ComponentsToCFrame(c)
    return CFrame.new(table.unpack(c))
end

local function ComponentsToPosition(c)
    return Vector3.new(c[1], c[2], c[3])
end

-- Soma real dos deslocamentos entre frames consecutivos (não linha reta
-- início->fim). Pré-calculado uma vez, lido depois em O(1) durante o replay.
local function BuildCumulativeDistance(waypoints)
    local cum = { [1] = 0 }
    for i = 2, #waypoints do
        local a = ComponentsToPosition(waypoints[i - 1].cf)
        local b = ComponentsToPosition(waypoints[i].cf)
        cum[i] = cum[i - 1] + (b - a).Magnitude
    end
    return cum
end

-- Linha da rota: conecta os pontos GRAVADOS na ordem em que foram
-- gravados (funciona igual pra qualquer sentido do percurso). Pula
-- pontos muito próximos (jogador parado) só pra não criar segmentos de
-- comprimento ~0 — não é uma rota "recalculada", continua passando
-- exatamente pelos pontos reais.
local function CreateRoute(waypoints)
    local folder = Instance.new("Folder")
    folder.Name = "InxiterTASRoute"

    local MIN_GAP = 0.6
    local lastPos = ComponentsToPosition(waypoints[1].cf)

    for i = 2, #waypoints do
        local pos = ComponentsToPosition(waypoints[i].cf)
        local dist = (pos - lastPos).Magnitude
        if dist >= MIN_GAP or i == #waypoints then
            local mid = (lastPos + pos) / 2
            local seg = Instance.new("Part")
            seg.Name = "Seg"
            seg.Anchored = true
            seg.CanCollide = false
            seg.CanQuery = false
            seg.CanTouch = false
            seg.Material = Enum.Material.Neon
            seg.Color = Color3.fromRGB(0, 200, 255)
            seg.Size = Vector3.new(0.15, 0.15, math.max(dist, 0.05))
            seg.CFrame = CFrame.new(mid, pos)
            seg.Parent = folder
            lastPos = pos
        end
    end

    return folder
end

local function CreateLabel(rootPart)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "InxiterTASInfo"
    billboard.Size = UDim2.fromOffset(220, 40)
    billboard.StudsOffset = Vector3.new(0, 3.2, 0)
    billboard.AlwaysOnTop = true

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0
    label.Font = Enum.Font.GothamBold
    label.TextSize = 16
    label.Text = "0.0s | 0.0 studs"
    label.Parent = billboard

    billboard.Parent = rootPart
    return label
end

-- ======================================================
-- FANTASMA
-- ======================================================
function TASRecorder:RemoveGhost()
    self:StopPlayback() -- nunca deixa conexão/câmera/controle presos num fantasma que tá sumindo

    if GhostProximityConn then GhostProximityConn:Disconnect(); GhostProximityConn = nil end
    GhostLabel = nil

    if RouteFolder then RouteFolder:Destroy(); RouteFolder = nil end
    if GhostModel then GhostModel:Destroy(); GhostModel = nil end
    GhostData = nil
    GhostFilename = nil
end

function TASRecorder:PrepareGhost(name)
    if not HasFileSystem() then return false, "Seu executor não suporta arquivos." end
    local path = FOLDER .. "/" .. SanitizeName(name) .. ".tas"
    if not isfile(path) then return false, "Gravação não encontrada." end

    local readOk, content = pcall(readfile, path)
    if not readOk then return false, "Erro ao ler o arquivo." end

    local decOk, data = pcall(function() return HttpService:JSONDecode(content) end)
    if not decOk or type(data) ~= "table" or type(data.waypoints) ~= "table" or #data.waypoints < 2 then
        return false, "Arquivo corrompido ou vazio."
    end

    self:RemoveGhost() -- garante um fantasma só por vez, nunca sobrepõe

    data.cumDist = BuildCumulativeDistance(data.waypoints)
    local startCFrame = ComponentsToCFrame(data.waypoints[1].cf)

    local char = LocalPlayer.Character
    if not char then return false, "Seu personagem não existe agora — tenta de novo depois de spawnar." end

    -- Archivable vem desligado por padrão em muitos personagens/jogos —
    -- com ele false, Clone() falha silenciosamente e devolve nil (sem
    -- erro nenhum no pcall). Liga só pra clonar e restaura o valor
    -- original logo em seguida, aconteça o que acontecer no clone.
    local previousArchivable = char.Archivable
    char.Archivable = true

    local cloneOk, ghost = pcall(function() return char:Clone() end)

    char.Archivable = previousArchivable

    if not cloneOk or not ghost then
        return false, "Não foi possível clonar seu personagem (falha na clonagem/Archivable)."
    end

    ghost.Name = "InxiterTASGhost_" .. SanitizeName(name)

    local ghostHumanoid = ghost:FindFirstChildOfClass("Humanoid")
    local ghostRoot = ghost:FindFirstChild("HumanoidRootPart")

    for _, d in ipairs(ghost:GetDescendants()) do
        if d:IsA("Script") or d:IsA("LocalScript") then
            d:Destroy() -- não precisa de Animate/Health rodando, o fantasma não se move
        elseif d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = false -- não é mais "tocável" — o gatilho é por proximidade, ver abaixo
            d.Transparency = math.clamp(d.Transparency + 0.55, 0, 0.9)
        elseif d:IsA("Decal") or d:IsA("Texture") then
            pcall(function() d.Transparency = math.clamp(d.Transparency + 0.55, 0, 0.9) end)
        end
    end

    if ghostHumanoid then ghostHumanoid.WalkSpeed = 0 end -- marcador parado, não anda sozinho

    if not ghost.PrimaryPart then ghost.PrimaryPart = ghostRoot end
    ghost.Parent = workspace
    if ghost.PrimaryPart then ghost:PivotTo(startCFrame) end

    if ghostRoot then
        local total = data.waypoints[#data.waypoints]
        local totalDist = data.cumDist[#data.cumDist] or 0
        local label = CreateLabel(ghostRoot)
        label.Text = string.format("%.1fs | %.1f studs", total.t, totalDist)
        GhostLabel = label
    end

    RouteFolder = CreateRoute(data.waypoints)
    RouteFolder.Parent = workspace

    GhostModel = ghost
    GhostData = data
    GhostFilename = name

    -- Gatilho por proximidade — "estar dentro" do fantasma, checado todo
    -- frame, em vez de depender do evento Touched (que com CanCollide
    -- false nem sempre dispara igual em todo executor).
    GhostProximityConn = RunService.Heartbeat:Connect(function()
        if not TASRecorder.Settings.ReproduzirArmed then return end
        if Playing or not GhostModel or not GhostModel.PrimaryPart then return end
        local root = GetRoot()
        if not root then return end
        if (root.Position - GhostModel.PrimaryPart.Position).Magnitude <= TRIGGER_RADIUS then
            TASRecorder:PlayRecording(GhostData)
        end
    end)

    return true
end

function TASRecorder:HasGhost()
    return GhostModel ~= nil, GhostFilename
end

-- ======================================================
-- REPRODUÇÃO — o PRÓPRIO jogador anda o caminho (o fantasma é só o
-- marcador parado de onde o trajeto começa). Câmera continua normal,
-- seguindo o jogador como sempre.
-- ======================================================
function TASRecorder:IsPlaying()
    return Playing
end

-- Devolve controle (PlayerModule) pro jogador e limpa a barra de
-- progresso. Único lugar que faz isso — usado tanto por StopPlayback()
-- (interrupção manual) quanto pelo fim natural do replay, pra nunca
-- deixar o jogador travado, nem manualmente nem sozinho.
local function ReleaseControl()
    if PlayerProgressBillboard then
        PlayerProgressBillboard:Destroy()
        PlayerProgressBillboard = nil
    end

    if LockedControls then
        pcall(function() LockedControls:Enable() end)
        LockedControls = nil
    end

    RestoreCompetingCamera()
end

-- Cancela/encerra a reprodução atual (se tiver) e devolve o controle pro
-- jogador. Chamar isso sem nada rodando é seguro (idempotente).
function TASRecorder:StopPlayback()
    PlayToken = PlayToken + 1
    Playing = false

    local hum, root = GetHumanoid(), GetRoot()
    if hum and root then
        pcall(function() hum:MoveTo(root.Position) end) -- cancela o MoveTo em andamento
    end

    ReleaseControl()
end

function TASRecorder:PlayRecording(data)
    if Playing then return false, "Já tem uma reprodução em andamento." end
    if Recording then return false, "Termina a gravação atual antes de reproduzir." end
    if not data or type(data.waypoints) ~= "table" or #data.waypoints < 2 then
        return false, "Gravação inválida."
    end

    local hum, root = GetHumanoid(), GetRoot()
    if not hum or not root then return false, "Seu personagem não existe." end

    local waypoints = data.waypoints
    if not data.cumDist then data.cumDist = BuildCumulativeDistance(waypoints) end
    local totalDist = data.cumDist[#data.cumDist] or 0

    Playing = true
    PlayToken = PlayToken + 1
    local myToken = PlayToken

    SuspendCompetingCamera() -- desliga Aimbot/FreeCam se estiverem disputando a câmera

    -- Trava WASD enquanto o script guia o personagem pelos waypoints —
    -- sem isso o input do jogador brigaria com o Humanoid:MoveTo. A
    -- câmera continua 100% normal (segue o próprio jogador como sempre).
    pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
        LockedControls = PlayerModule:GetControls()
        LockedControls:Disable()
    end)

    -- Assume a posição gravada do início (a mesma do fantasma) antes de
    -- começar a andar o trajeto de verdade.
    pcall(function() root.CFrame = ComponentsToCFrame(waypoints[1].cf) end)

    local progressLabel = CreateLabel(root)
    PlayerProgressBillboard = progressLabel.Parent

    task.spawn(function()
        for i, wp in ipairs(waypoints) do
            if PlayToken ~= myToken then return end -- outra sessão assumiu (Stop/novo Play)

            local h, r = GetHumanoid(), GetRoot()
            if not h or not r then break end

            local target = ComponentsToPosition(wp.cf)
            h:MoveTo(target)
            if wp.st and JUMP_STATES[wp.st] then h.Jump = true end

            if progressLabel and progressLabel.Parent then
                progressLabel.Text = string.format("%.1fs | %.1f studs", wp.t, data.cumDist[i] or 0)
            end

            local reached = false
            local moveConn = h.MoveToFinished:Connect(function() reached = true end)
            local waited = 0
            while not reached and waited < 2 and PlayToken == myToken do
                task.wait(0.05)
                waited = waited + 0.05
                local rr = GetRoot()
                if rr and (rr.Position - target).Magnitude < 2 then break end
            end
            moveConn:Disconnect()
        end

        -- Chegou no último waypoint (ou saiu do loop porque o personagem
        -- sumiu) — PARA de vez. Sem reiniciar, sem voltar ao primeiro
        -- ponto. Só limpa se ninguém mais assumiu a sessão nesse meio
        -- tempo (StopPlayback já teria trocado o token).
        if PlayToken == myToken then
            if progressLabel and progressLabel.Parent then
                progressLabel.Text = string.format("%.1fs | %.1f studs (fim)", waypoints[#waypoints].t, totalDist)
            end
            Playing = false
            ReleaseControl()
        end
    end)

    return true
end

function TASRecorder:Unload()
    self:StopRecording()
    self:RemoveGhost() -- já chama StopPlayback() por dentro
    if CharacterRemovingConn then CharacterRemovingConn:Disconnect(); CharacterRemovingConn = nil end
end

return TASRecorder
