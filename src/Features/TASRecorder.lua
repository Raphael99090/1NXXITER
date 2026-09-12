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

-- Animações de fallback, só usadas se o personagem não tiver o script
-- "Animate" padrão (a gente prefere sempre os IDs do PRÓPRIO jogo — ver
-- GetRigAnimIds). Esses são os IDs padrão de fábrica da Roblox.
local DEFAULT_ANIMS = {
    R15 = { idle = "rbxassetid://507766666", walk = "rbxassetid://913402848", jump = "rbxassetid://507765000", fall = "rbxassetid://507767968" },
    R6  = { idle = "rbxassetid://180435571", walk = "rbxassetid://180426354", jump = "rbxassetid://125750702", fall = "rbxassetid://180436148" },
}

local WALK_STATES = { Running = true, RunningNoPhysics = true }
local JUMP_STATES = { Jumping = true }
local FALL_STATES = { Freefall = true }

-- Gravação em andamento
local Recording = false
local RecordConn = nil
local RecordBuffer = nil

-- Fantasma ativo
local GhostModel = nil
local GhostData = nil -- { start={c=...}, waypoints={ {t,cf,cc,st}, ... }, cumDist={...} }
local GhostFilename = nil
local GhostTouchConns = {}
local GhostTracks = nil -- {idle=track, walk=track, jump=track, fall=track}
local GhostCurrentTrackName = nil
local GhostLabel = nil
local RouteFolder = nil

-- Reprodução em andamento
local Playing = false
local PlayConn = nil
local PlayToken = 0
local LockedControls = nil
local OriginalCameraType = nil
local OriginalCameraSubject = nil

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

-- Prefere os IDs de animação do PRÓPRIO jogo (lidos do script "Animate"
-- que já existe no personagem real, sem depender dele estar rodando) —
-- só cai pro fallback genérico se o jogo não tiver um Animate padrão.
local function GetRigAnimIds(character)
    local isR15 = character:FindFirstChild("UpperTorso") ~= nil
    local fallback = isR15 and DEFAULT_ANIMS.R15 or DEFAULT_ANIMS.R6
    local ids = { idle = fallback.idle, walk = fallback.walk, jump = fallback.jump, fall = fallback.fall }

    local animate = character:FindFirstChild("Animate")
    if animate then
        local function findId(stateName)
            local folder = animate:FindFirstChild(stateName)
            if not folder then return nil end
            for _, child in ipairs(folder:GetChildren()) do
                if child:IsA("Animation") and child.AnimationId ~= "" then
                    return child.AnimationId
                end
            end
            return nil
        end
        ids.idle = findId("idle") or ids.idle
        ids.walk = findId("walk") or ids.walk
        ids.jump = findId("jump") or ids.jump
        ids.fall = findId("fall") or ids.fall
    end

    return ids
end

local function LoadGhostTracks(ghostHumanoid, liveCharacter)
    local animator = ghostHumanoid:FindFirstChildOfClass("Animator")
    if not animator then
        animator = Instance.new("Animator")
        animator.Parent = ghostHumanoid
    end

    local ids = GetRigAnimIds(liveCharacter)
    local tracks = {}
    for name, id in pairs(ids) do
        local ok, track = pcall(function()
            local anim = Instance.new("Animation")
            anim.AnimationId = id
            return animator:LoadAnimation(anim)
        end)
        if ok and track then
            track.Looped = (name ~= "jump")
            tracks[name] = track
        end
    end
    return tracks
end

local function SetGhostTrack(name)
    if GhostCurrentTrackName == name then return end
    if GhostTracks then
        if GhostCurrentTrackName and GhostTracks[GhostCurrentTrackName] then
            pcall(function() GhostTracks[GhostCurrentTrackName]:Stop(0.15) end)
        end
        if GhostTracks[name] then
            pcall(function() GhostTracks[name]:Play(0.15) end)
        end
    end
    GhostCurrentTrackName = name
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

    for _, conn in ipairs(GhostTouchConns) do conn:Disconnect() end
    GhostTouchConns = {}

    if GhostTracks then
        for _, track in pairs(GhostTracks) do
            pcall(function() track:Stop(0); track:Destroy() end)
        end
        GhostTracks = nil
    end
    GhostCurrentTrackName = nil
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
            -- Remove só os scripts de controle (Animate, Health, etc.) —
            -- o Humanoid e o Animator continuam, porque tocamos a
            -- animação manualmente com base no que foi gravado.
            d:Destroy()
        elseif d:IsA("BasePart") then
            d.Anchored = true
            d.CanCollide = false
            d.CanQuery = false
            d.CanTouch = true
            d.Transparency = math.clamp(d.Transparency + 0.55, 0, 0.9)
            table.insert(GhostTouchConns, d.Touched:Connect(function(hit)
                if not TASRecorder.Settings.ReproduzirArmed then return end
                if Playing then return end
                local hitChar = LocalPlayer.Character
                if hitChar and hit:IsDescendantOf(hitChar) then
                    TASRecorder:PlayRecording(data)
                end
            end))
        elseif d:IsA("Decal") or d:IsA("Texture") then
            pcall(function() d.Transparency = math.clamp(d.Transparency + 0.55, 0, 0.9) end)
        end
    end

    if ghostHumanoid then
        ghostHumanoid.WalkSpeed = 0 -- o movimento é 100% via CFrame direto, não física
        GhostTracks = LoadGhostTracks(ghostHumanoid, char)
    end

    if not ghost.PrimaryPart then ghost.PrimaryPart = ghostRoot end
    ghost.Parent = workspace
    if ghost.PrimaryPart then ghost:PivotTo(startCFrame) end -- fantasma já nasce no 1º frame

    if ghostRoot then GhostLabel = CreateLabel(ghostRoot) end

    RouteFolder = CreateRoute(data.waypoints)
    RouteFolder.Parent = workspace

    GhostModel = ghost
    GhostData = data
    GhostFilename = name
    return true
end

function TASRecorder:HasGhost()
    return GhostModel ~= nil, GhostFilename
end

-- ======================================================
-- REPRODUÇÃO
-- ======================================================
function TASRecorder:IsPlaying()
    return Playing
end

local function ApplyFrame(waypoints, i, j, alpha)
    local a, b = waypoints[i], waypoints[j]
    local cfA, cfB = ComponentsToCFrame(a.cf), ComponentsToCFrame(b.cf)
    local ccA, ccB = ComponentsToCFrame(a.cc or a.cf), ComponentsToCFrame(b.cc or b.cf) -- fallback p/ gravações antigas sem câmera

    local cf = cfA:Lerp(cfB, alpha)
    local cam = ccA:Lerp(ccB, alpha)

    if GhostModel and GhostModel.PrimaryPart then
        GhostModel:PivotTo(cf)
    end
    local camera = GetCamera()
    if camera then camera.CFrame = cam end

    local st = a.st or "Running"
    if JUMP_STATES[st] then SetGhostTrack("jump")
    elseif FALL_STATES[st] then SetGhostTrack("fall")
    elseif WALK_STATES[st] then SetGhostTrack("walk")
    else SetGhostTrack("idle") end
end

local function UpdateLabel(data, i, alpha, elapsed)
    if not GhostLabel then return end
    local cum = data.cumDist
    local nextCum = cum[i + 1] or cum[i]
    local dist = cum[i] + (nextCum - cum[i]) * alpha
    GhostLabel.Text = string.format("%.1fs | %.1f studs", elapsed, dist)
end

-- Devolve câmera (Custom) e controle (PlayerModule) pro jogador. Único
-- lugar que faz isso — usado tanto por StopPlayback() (interrupção
-- manual) quanto pelo fim natural do replay dentro de PlayRecording, pra
-- nunca deixar o jogador travado, nem manualmente nem sozinho.
local function ReleaseControl()
    if GhostTracks and GhostCurrentTrackName then
        pcall(function() GhostTracks[GhostCurrentTrackName]:Stop(0.1) end)
        GhostCurrentTrackName = nil
    end

    local camera = GetCamera()
    if camera then
        camera.CameraType = OriginalCameraType or Enum.CameraType.Custom
        local hum = GetHumanoid()
        camera.CameraSubject = OriginalCameraSubject or hum or camera.CameraSubject
    end
    OriginalCameraType, OriginalCameraSubject = nil, nil

    if LockedControls then
        pcall(function() LockedControls:Enable() end)
        LockedControls = nil
    end

    RestoreCompetingCamera()
end

-- Cancela/encerra a reprodução atual (se tiver) e devolve câmera + controle
-- pro jogador. Chamar isso sem nada rodando é seguro (idempotente).
function TASRecorder:StopPlayback()
    PlayToken = PlayToken + 1
    Playing = false
    if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
    ReleaseControl()
end

function TASRecorder:PlayRecording(data)
    if Playing then return false, "Já tem uma reprodução em andamento." end
    if Recording then return false, "Termina a gravação atual antes de reproduzir." end
    if not GhostModel or not data or type(data.waypoints) ~= "table" or #data.waypoints < 2 then
        return false, "Fantasma não está pronto."
    end

    local waypoints = data.waypoints
    if not data.cumDist then data.cumDist = BuildCumulativeDistance(waypoints) end

    Playing = true
    PlayToken = PlayToken + 1
    local myToken = PlayToken

    SuspendCompetingCamera() -- desliga Aimbot/FreeCam se estiverem disputando a câmera

    -- Trava WASD — a câmera vai estar presa reproduzindo a gravação, não
    -- faz sentido deixar o jogador andar "às cegas" nesse meio tempo.
    pcall(function()
        local PlayerModule = require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
        LockedControls = PlayerModule:GetControls()
        LockedControls:Disable()
    end)

    -- Câmera gravada é obrigatória — sem toggle pra desativar.
    local camera = GetCamera()
    if camera then
        OriginalCameraType = camera.CameraType
        OriginalCameraSubject = camera.CameraSubject
        camera.CameraType = Enum.CameraType.Scriptable
    end

    local startClock = os.clock()
    local totalTime = waypoints[#waypoints].t
    local segIndex = 1 -- só avança pra frente, nunca reseta nem dá wrap-around

    PlayConn = RunService.Heartbeat:Connect(function()
        if PlayToken ~= myToken then return end -- sessão velha, será desconectada
        local elapsed = os.clock() - startClock

        if elapsed >= totalTime then
            -- Último frame: aplica exatamente ele e PARA. Não reinicia
            -- nunca — sem "% totalTime", sem resetar segIndex, sem
            -- reconectar. O FANTASMA fica parado no último frame (ele
            -- não é destruído nem se move mais), mas o jogador recupera
            -- câmera e controle na hora — não fica travado esperando
            -- clicar em "Parar reprodução" manualmente.
            local last = #waypoints
            ApplyFrame(waypoints, last, last, 0)
            UpdateLabel(data, math.max(last - 1, 1), 1, totalTime)
            if PlayConn then PlayConn:Disconnect(); PlayConn = nil end
            PlayToken = PlayToken + 1
            Playing = false
            ReleaseControl()
            return
        end

        while segIndex < #waypoints - 1 and waypoints[segIndex + 1].t <= elapsed do
            segIndex = segIndex + 1
        end

        local a, b = waypoints[segIndex], waypoints[segIndex + 1]
        local span = math.max(b.t - a.t, 1e-4)
        local alpha = math.clamp((elapsed - a.t) / span, 0, 1)

        ApplyFrame(waypoints, segIndex, segIndex + 1, alpha)
        UpdateLabel(data, segIndex, alpha, elapsed)
    end)

    return true
end

function TASRecorder:Unload()
    self:StopRecording()
    self:RemoveGhost() -- já chama StopPlayback() por dentro
    if CharacterRemovingConn then CharacterRemovingConn:Disconnect(); CharacterRemovingConn = nil end
end

return TASRecorder
