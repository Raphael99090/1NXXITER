-- [main.lua]
if getgenv().InxiterHubLoaded and getgenv().InxiterHubInstance then
warn("♻️ [1NXITER]: Instância anterior detectada — desligando antes de recarregar...")
local ok,err =pcall(function()
getgenv().InxiterHubInstance:Unload()
end)
if not ok then
warn("⚠️ [1NXITER]: Erro ao desligar instância anterior -> "..tostring(err))
end
getgenv().InxiterHubLoaded =false
getgenv().InxiterHubInstance =nil
end
local REPO ="Raphael99090/1NXXITER"
local BRANCH ="main"
local BASE_URL ="https://raw.githubusercontent.com/"..REPO .."/"..BRANCH .."/src/"
local KEYS_URL ="https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/docs/keys.json"
local LINKVERTISE_URL ="https://linkvertise.com/SEU_ID_AQUI"
local TESTING_MODE =true
local TEST_KEY ="TESTE-1NX"
if TESTING_MODE then
warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '"..TEST_KEY .."' libera sem checar o site. Desliga TESTING_MODE antes de publicar!")
end
local function GetHWID()
local ok,id =pcall(function()
if gethwid then return gethwid()end
if get_hwid then return get_hwid()end
if identifyexecutor then
local name =identifyexecutor()
return "id-"..tostring(name).."-"..tostring(game:GetService("RbxAnalyticsService"):GetClientId())
end
return game:GetService("RbxAnalyticsService"):GetClientId()
end)
return ok and tostring(id)or "unknown-hwid"
end
local function GetDailyKey()
local secret ="1NXITER-DAILY-2026"
local today =os.date("!%Y-%m-%d")
local combined =secret ..today
local hash =0
for i =1,#combined do
hash =(hash *31 +string.byte(combined,i))%2147483647
end
return "1NX-FREE-"..string.format("%08X",hash)
end
local function ValidatePremiumKey(key,hwid,callback)
local ok,raw =pcall(function()
return game:HttpGet(KEYS_URL .."?cache="..math.random(1,999999))
end)
if not ok or not raw then
callback(false,"Erro ao conectar ao servidor de keys.")
return
end
local decOk,data =pcall(function()
return game:GetService("HttpService"):JSONDecode(raw)
end)
if not decOk or not data or not data.keys then
callback(false,"Erro ao ler dados de keys.")
return
end
local keyData =data.keys[key]
if not keyData then
callback(false,"Key inválida.")
return
end
if not keyData.active then
callback(false,"Essa key foi revogada.")
return
end
if keyData.expires and keyData.expires ~=""then
local y,m,d =keyData.expires:match("(%d+)-(%d+)-(%d+)")
if y then
local expiryTime =os.time({
year =tonumber(y),month =tonumber(m),day =tonumber(d),
hour =23,min =59,sec =59
})
if os.time()>expiryTime then
callback(false,"Sua key expirou. Renove no Discord.")
return
end
end
end
if keyData.hwid and keyData.hwid ~=""and keyData.hwid ~=hwid then
callback(false,"Key vinculada a outro dispositivo.\nPeça reset de HWID ao admin.")
return
end
callback(true)
end
local function CheckKey(key,callback)
if TESTING_MODE then
if key ==TEST_KEY then
callback(true)
return
end
end
if key ==GetDailyKey()then
callback(true)
return
end
ValidatePremiumKey(key,GetHWID(),callback)
end
local function RequestKey(onSuccess)
local Players =game:GetService("Players")
local LocalPlayer =Players.LocalPlayer
local PlayerGui =LocalPlayer:WaitForChild("PlayerGui")
local hwid =GetHWID()
local KeyGui =Instance.new("ScreenGui")
KeyGui.Name ="InxiterKeyGate"
KeyGui.ResetOnSpawn =false
KeyGui.IgnoreGuiInset =true
KeyGui.Parent =PlayerGui
local Frame =Instance.new("Frame")
Frame.Size =UDim2.new(0,320,0,280)
Frame.Position =UDim2.new(0.5,-160,0.5,-140)
Frame.BackgroundColor3 =Color3.fromRGB(25,15,35)
Frame.BorderSizePixel =0
Frame.Parent =KeyGui
local Corner =Instance.new("UICorner")
Corner.CornerRadius =UDim.new(0,12)
Corner.Parent =Frame
local Title =Instance.new("TextLabel")
Title.Size =UDim2.new(1,0,0,36)
Title.BackgroundTransparency =1
Title.Text ="🔑 1NXITER HUB"
Title.Font =Enum.Font.GothamBold
Title.TextSize =16
Title.TextColor3 =Color3.new(1,1,1)
Title.Parent =Frame
local Input =Instance.new("TextBox")
Input.Size =UDim2.new(1,-30,0,34)
Input.Position =UDim2.new(0,15,0,42)
Input.BackgroundColor3 =Color3.fromRGB(40,25,55)
Input.TextColor3 =Color3.new(1,1,1)
Input.PlaceholderText ="Cole sua key aqui..."
Input.Text =""
Input.ClearTextOnFocus =false
Input.Font =Enum.Font.Gotham
Input.TextSize =14
Input.Parent =Frame
Instance.new("UICorner",Input).CornerRadius =UDim.new(0,6)
local Confirm =Instance.new("TextButton")
Confirm.Size =UDim2.new(1,-30,0,34)
Confirm.Position =UDim2.new(0,15,0,84)
Confirm.BackgroundColor3 =Color3.fromRGB(120,60,200)
Confirm.Text ="Confirmar"
Confirm.Font =Enum.Font.GothamBold
Confirm.TextSize =14
Confirm.TextColor3 =Color3.new(1,1,1)
Confirm.Parent =Frame
Instance.new("UICorner",Confirm).CornerRadius =UDim.new(0,6)
local GetKeyBtn =Instance.new("TextButton")
GetKeyBtn.Size =UDim2.new(1,-30,0,30)
GetKeyBtn.Position =UDim2.new(0,15,0,124)
GetKeyBtn.BackgroundColor3 =Color3.fromRGB(50,35,70)
GetKeyBtn.Text ="🔗 OBTER KEY GRÁTIS"
GetKeyBtn.Font =Enum.Font.GothamBold
GetKeyBtn.TextSize =12
GetKeyBtn.TextColor3 =Color3.fromRGB(180,140,255)
GetKeyBtn.Parent =Frame
Instance.new("UICorner",GetKeyBtn).CornerRadius =UDim.new(0,6)
local HwidLabel =Instance.new("TextLabel")
HwidLabel.Size =UDim2.new(1,-80,0,24)
HwidLabel.Position =UDim2.new(0,15,0,164)
HwidLabel.BackgroundTransparency =1
HwidLabel.Text ="HWID: "..string.sub(hwid,1,22)..(string.len(hwid)>22 and "..."or "")
HwidLabel.Font =Enum.Font.Code
HwidLabel.TextSize =10
HwidLabel.TextColor3 =Color3.fromRGB(120,120,120)
HwidLabel.TextXAlignment =Enum.TextXAlignment.Left
HwidLabel.Parent =Frame
local CopyHwid =Instance.new("TextButton")
CopyHwid.Size =UDim2.new(0,55,0,20)
CopyHwid.Position =UDim2.new(1,-70,0,166)
CopyHwid.BackgroundColor3 =Color3.fromRGB(50,35,70)
CopyHwid.Text ="Copiar"
CopyHwid.Font =Enum.Font.Gotham
CopyHwid.TextSize =10
CopyHwid.TextColor3 =Color3.fromRGB(180,140,255)
CopyHwid.Parent =Frame
Instance.new("UICorner",CopyHwid).CornerRadius =UDim.new(0,4)
local ErrorLabel =Instance.new("TextLabel")
ErrorLabel.Size =UDim2.new(1,-30,0,40)
ErrorLabel.Position =UDim2.new(0,15,0,192)
ErrorLabel.BackgroundTransparency =1
ErrorLabel.Text =""
ErrorLabel.TextColor3 =Color3.fromRGB(255,90,90)
ErrorLabel.Font =Enum.Font.Gotham
ErrorLabel.TextSize =11
ErrorLabel.TextWrapped =true
ErrorLabel.TextYAlignment =Enum.TextYAlignment.Top
ErrorLabel.Parent =Frame
local InfoLabel =Instance.new("TextLabel")
InfoLabel.Size =UDim2.new(1,-30,0,20)
InfoLabel.Position =UDim2.new(0,15,1,-26)
InfoLabel.BackgroundTransparency =1
InfoLabel.Text ="Key grátis = 24h · Key premium = Discord"
InfoLabel.Font =Enum.Font.Gotham
InfoLabel.TextSize =10
InfoLabel.TextColor3 =Color3.fromRGB(80,80,80)
InfoLabel.Parent =Frame
local checking =false
local function TryKey()
if checking then return end
local keyText =Input.Text
if keyText ==""then
ErrorLabel.Text ="Cola sua key aí antes de confirmar."
return
end
checking =true
Confirm.Text ="Verificando..."
ErrorLabel.Text =""
CheckKey(keyText,function(valid,errorMsg)
checking =false
if valid then
KeyGui:Destroy()
onSuccess()
else
Confirm.Text ="Confirmar"
ErrorLabel.Text =errorMsg or "Key inválida. Tenta de novo."
Input.Text =""
end
end)
end
Confirm.MouseButton1Click:Connect(TryKey)
Input.FocusLost:Connect(function(enterPressed)
if enterPressed then TryKey()end
end)
GetKeyBtn.MouseButton1Click:Connect(function()
local copier =setclipboard or toclipboard
if type(copier)=="function"then
pcall(copier,LINKVERTISE_URL)
ErrorLabel.TextColor3 =Color3.fromRGB(100,255,100)
ErrorLabel.Text ="Link copiado! Cole no navegador."
else
ErrorLabel.TextColor3 =Color3.fromRGB(180,140,255)
ErrorLabel.Text ="Abra: "..LINKVERTISE_URL
end
task.delay(4,function()
ErrorLabel.TextColor3 =Color3.fromRGB(255,90,90)
ErrorLabel.Text =""
end)
end)
CopyHwid.MouseButton1Click:Connect(function()
local copier =setclipboard or toclipboard
if type(copier)=="function"then
pcall(copier,hwid)
CopyHwid.Text ="✅"
task.delay(2,function()CopyHwid.Text ="Copiar"end)
end
end)
end
local Hub ={
Core ={},
Features ={},
UI ={
Tabs ={}
}
}
function Hub:Unload()
for name,feature in pairs(self.Features)do
if type(feature)=="table"and feature.Unload then
local ok,err =pcall(function()feature:Unload()end)
if not ok then
warn("⚠️ [1NXITER]: Erro ao descarregar Features/"..name .." -> "..tostring(err))
end
end
end
if self.Core.Utils and self.Core.Utils.StopAll then
pcall(function()self.Core.Utils:StopAll()end)
end
if self.UI.Window and self.UI.Window.Destroy then
pcall(function()self.UI.Window:Destroy()end)
end
end
local function Import(path)
local url =BASE_URL ..path ..".lua"
print("📥 [1NXITER]: Carregando -> "..path)
local success,code =pcall(function()
return game:HttpGet(url .."?cache="..math.random(1,999999))
end)
if success and code and not code:match("^404")then
local func,err =loadstring(code)
if func then
local runSuccess,result =pcall(func)
if runSuccess then
return result 
else
warn("❌ [1NXITER]: Erro ao executar módulo ("..path .."): "..tostring(result))
end
else
warn("❌ [1NXITER]: Erro de sintaxe em ("..path .."): "..tostring(err))
end
else
warn("❌ [1NXITER]: Arquivo não encontrado ou erro de rede (404) -> "..url)
end
return nil
end
local function LoadHub()
Hub.Core.Utils =Import("Core/Utils")
Hub.Core.State =Import("Core/State")
local featuresList ={
"AutoTrain","Aimbot","ESP","PlayerMods","FreeCam","SpyChat","Visuals"
}
for _,f in pairs(featuresList)do
Hub.Features[f]=Import("Features/"..f)
end
local tabsList ={
"TrainTab","CombatTab","ESPTab","MovementTab","CameraTab","SystemTab"
}
for _,t in pairs(tabsList)do
Hub.UI.Tabs[t]=Import("Interface/Tabs/"..t)
end
Hub.UI.Main =Import("Interface/Main")
local function Start()
if not Hub.Core.State or not Hub.UI.Main then
return warn("❌ [1NXITER]: Falha crítica. Verifique se as pastas e nomes no GitHub estão corretos.")
end
print("✅ [1NXITER]: Todos os módulos carregados. Iniciando sistema...")
getgenv().InxiterHubLoaded =true
getgenv().InxiterHubInstance =Hub
local Config =Hub.Core.State:LoadConfig()
local RuntimeState =Hub.Core.State:GetRuntimeState()
Hub.Core.State:StartAutoSave(Config,8)
if Hub.Core.Utils then
Hub.Core.Utils:AntiAFK(RuntimeState)
Hub.Core.Utils:AutoRejoin(Config)
end
Hub.UI.Main:Load(Hub,Config,RuntimeState)
end
local finalSuccess,finalErr =pcall(Start)
if not finalSuccess then
getgenv().InxiterHubLoaded =false
warn("❌ [1NXITER]: Erro fatal durante a inicialização -> "..tostring(finalErr))
end
end
RequestKey(LoadHub)
-- [Core/State.lua]
local StateManager ={}
local HttpService =game:GetService("HttpService")
local FOLDER_NAME ="1NXITER_HUB"
local FILE_NAME =FOLDER_NAME .."/Config_v3.json"
local DefaultConfig ={
Mode ="Canguru",
Delay =1.4,
StartNum =0,
Quantity =130,
IsCountdown =false,
AutoCrouch =false,
AutoEquip =false,
AutoRejoin =false,
UITheme ="Dark",
DiscordLink ="https://discord.gg/CGRZRDJqN",
AutoSave =true
}
local RuntimeState ={
IsRunning =false,
IsActive =true,
LoadedAt =os.date("%X")
}
local function HasFileSystem()
return isfile and readfile and writefile and makefolder and isfolder
end
local function DeepMerge(target,source)
for k,v in pairs(source)do
if type(v)=="table"and type(target[k])=="table"then
DeepMerge(target[k],v)
else
target[k]=v
end
end
return target
end
local function DeepCopy(t)
local copy ={}
for k,v in pairs(t)do
copy[k]=(type(v)=="table")and DeepCopy(v)or v
end
return copy
end
function StateManager:GetRuntimeState()
return RuntimeState
end
function StateManager:LoadConfig()
if not HasFileSystem()then return DefaultConfig end
if isfile(FILE_NAME)then
local ok,content =pcall(readfile,FILE_NAME)
if ok then
local decodeOk,decoded =pcall(HttpService.JSONDecode,HttpService,content)
if decodeOk and type(decoded)=="table"then
local finalConfig ={}
for k,v in pairs(DefaultConfig)do finalConfig[k]=v end
return DeepMerge(finalConfig,decoded)
end
end
end
return DefaultConfig
end
function StateManager:SaveConfig(currentConfig)
if not HasFileSystem()then return false end
local ok,err =pcall(function()
if not isfolder(FOLDER_NAME)then makefolder(FOLDER_NAME)end
local data =HttpService:JSONEncode(currentConfig)
writefile(FILE_NAME,data)
end)
return ok
end
function StateManager:GetDefaults()
return DeepCopy(DefaultConfig)
end
function StateManager:ResetConfig(config)
for k,v in pairs(DefaultConfig)do
config[k]=v
end
return config
end
function StateManager:StartAutoSave(config,intervalSeconds)
if not HasFileSystem()then return end
intervalSeconds =intervalSeconds or 8
task.spawn(function()
local lastSnapshot =nil
while getgenv().InxiterHubLoaded do
task.wait(intervalSeconds)
if not getgenv().InxiterHubLoaded then break end
if config.AutoSave then
local encodeOk,snapshot =pcall(HttpService.JSONEncode,HttpService,config)
if encodeOk and snapshot ~=lastSnapshot then
if self:SaveConfig(config)then
lastSnapshot =snapshot
end
end
end
end
end)
end
return StateManager
-- [Core/Utils.lua]
local Utils ={}
Utils._connections ={}
local Players =game:GetService("Players")
local TeleportService =game:GetService("TeleportService")
local VirtualUser =game:GetService("VirtualUser")
local GuiService =game:GetService("GuiService")
local Lighting =game:GetService("Lighting")
local Player =Players.LocalPlayer
local UNIDADES ={"ZERO","UM","DOIS","TRÊS","QUATRO","CINCO","SEIS","SETE","OITO","NOVE"}
local ESPECIAIS ={"DEZ","ONZE","DOZE","TREZE","QUATORZE","QUINZE","DEZESSEIS","DEZESSETE","DEZOITO","DEZENOVE"}
local DEZENAS ={"","","VINTE","TRINTA","QUARENTA","CINQUENTA","SESSENTA","SETENTA","OITENTA","NOVENTA"}
local CENTENAS ={"","CENTO","DUZENTOS","TREZENTOS","QUATROCENTOS","QUINHENTOS","SEISCENTOS","SETECENTOS","OITOCENTOS","NOVECENTOS"}
function Utils:NumberToText(n)
n =math.floor(tonumber(n)or 0)
if n ==0 then return UNIDADES[1]end
if n >9999 then return tostring(n)end
local function parse(num)
if num ==0 then return ""end
if num ==100 then return "CEM"end
local partes ={}
local c =math.floor(num /100)
local resto =num %100
if c >0 then table.insert(partes,CENTENAS[c +1])end
if resto >0 then
if resto >=10 and resto <=19 then
table.insert(partes,ESPECIAIS[resto -9])
else
local d =math.floor(resto /10)
local u =resto %10
if d >=2 then table.insert(partes,DEZENAS[d +1])end
if u >0 then table.insert(partes,UNIDADES[u +1])end
end
end
return table.concat(partes," E ")
end
if n >=1000 then
local milhar =math.floor(n /1000)
local resto =n %1000
local txtMilhar =(milhar ==1)and "MIL"or (parse(milhar).." MIL")
if resto >0 then
local sep =(resto <100 or resto %100 ==0)and " E "or " "
return txtMilhar ..sep ..parse(resto)
end
return txtMilhar
end
return parse(n)
end
function Utils:AntiAFK()
if self._connections["AntiAFK"]then return end
self._connections["AntiAFK"]=Player.Idled:Connect(function()
VirtualUser:CaptureController()
VirtualUser:ClickButton2(Vector2.new())
end)
end
function Utils:AutoRejoin(Config)
if self._connections["AutoRejoin"]then self._connections["AutoRejoin"]:Disconnect()end
self._connections["AutoRejoin"]=GuiService.ErrorMessageChanged:Connect(function()
if Config.AutoRejoin then
task.wait(5)
self:Rejoin()
end
end)
end
function Utils:Rejoin()
if #Players:GetPlayers()<=1 then
TeleportService:Teleport(game.PlaceId,Player)
else
TeleportService:TeleportToPlaceInstance(game.PlaceId,game.JobId,Player)
end
end
function Utils:ServerHop()
local Api ="https://games.roblox.com/v1/games/"..game.PlaceId .."/servers/Public?sortOrder=Desc&limit=100"
local success,result =pcall(function()
local raw =game:HttpGet(Api)
local data =game:GetService("HttpService"):JSONDecode(raw)
for _,s in pairs(data.data)do
if s.playing <s.maxPlayers and s.id ~=game.JobId then
TeleportService:TeleportToPlaceInstance(game.PlaceId,s.id,Player)
return
end
end
end)
if not success then TeleportService:Teleport(game.PlaceId,Player)end
end
function Utils:AntiLag()
settings().Rendering.QualityLevel =1
Lighting.GlobalShadows =false
for _,v in pairs(workspace:GetDescendants())do
if v:IsA("BasePart")then
v.Material =Enum.Material.SmoothPlastic
v.Reflectance =0
elseif v:IsA("Decal")or v:IsA("Texture")then
v.Transparency =1
elseif v:IsA("ParticleEmitter")or v:IsA("Trail")then
v.Enabled =false
end
end
end
function Utils:StopAll()
for _,c in pairs(self._connections)do c:Disconnect()end
self._connections ={}
end
return Utils
-- [Features/Aimbot.lua]
local Aimbot ={}
local Players =game:GetService("Players")
local RunService =game:GetService("RunService")
local UserInputService =game:GetService("UserInputService")
local Workspace =game:GetService("Workspace")
local LocalPlayer =Players.LocalPlayer
local originalHitboxes ={}
local function KeepTouchControlsEnabled()
local ok =pcall(function()
local PlayerModule =require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
PlayerModule:GetControls():Enable()
end)
return ok
end
Aimbot.Settings ={
Enabled =false,
TeamCheck =false,
WallCheck =true,
ShowFOV =false,
FOVRadius =150,
Smoothness =0.5,
TargetPart ="HumanoidRootPart",
HitboxExpander =false,
HitboxSize =10,
SilentAim =false,
Priority ="Closest",
AimKeyOnly =false,
AimKey =Enum.KeyCode.E
}
local LockMarker =nil
do
local ok,circle =pcall(function()
local c =Drawing.new("Circle")
c.Color =Color3.fromRGB(255,60,60)
c.Thickness =2
c.Radius =10
c.Filled =false
c.NumSides =3
c.Visible =false
return c
end)
if ok then LockMarker =circle end
end
local FOVCircle =nil
do
local ok,circle =pcall(function()
local c =Drawing.new("Circle")
c.Color =Color3.new(1,1,1)
c.Thickness =1
c.Filled =false
return c
end)
if ok then FOVCircle =circle end
end
local function IsVisible(part,camera)
local params =RaycastParams.new()
params.FilterDescendantsInstances ={LocalPlayer.Character,camera}
params.FilterType =Enum.RaycastFilterType.Exclude
local result =Workspace:Raycast(camera.CFrame.Position,part.Position -camera.CFrame.Position,params)
return result ==nil
end
local function GetTarget(camera)
local target =nil
local bestScore =nil
local center =Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
for _,p in pairs(Players:GetPlayers())do
if p ~=LocalPlayer and p.Character and p.Character:FindFirstChild(Aimbot.Settings.TargetPart)then
if Aimbot.Settings.TeamCheck and p.Team ==LocalPlayer.Team then continue end
local part =p.Character[Aimbot.Settings.TargetPart]
local pos,onScreen =camera:WorldToViewportPoint(part.Position)
if onScreen then
local dist =(Vector2.new(pos.X,pos.Y)-center).Magnitude
if dist <Aimbot.Settings.FOVRadius then
if Aimbot.Settings.WallCheck and not IsVisible(part,camera)then continue end
local score =dist
if Aimbot.Settings.Priority =="LowHealth"then
local hum =p.Character:FindFirstChildOfClass("Humanoid")
score =hum and hum.Health or math.huge
end
if not bestScore or score <bestScore then
bestScore =score
target =part
end
end
end
end
end
return target
end
local wasAiming =false
Aimbot.IsAiming =false 
Aimbot.LockedTarget =nil 
Aimbot._conn =RunService.RenderStepped:Connect(function(dt)
local Camera =Workspace.CurrentCamera
if not Camera then return end
if FOVCircle then
FOVCircle.Visible =Aimbot.Settings.ShowFOV
FOVCircle.Radius =Aimbot.Settings.FOVRadius
FOVCircle.Position =Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)
end
if Aimbot.Settings.HitboxExpander then
for _,p in pairs(Players:GetPlayers())do
if p ~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local root =p.Character.HumanoidRootPart
if not originalHitboxes[p]then
originalHitboxes[p]=root.Size
end
root.Size =Vector3.new(Aimbot.Settings.HitboxSize,Aimbot.Settings.HitboxSize,Aimbot.Settings.HitboxSize)
root.Transparency =0.7
root.CanCollide =false
end
end
elseif next(originalHitboxes)then
for p,origSize in pairs(originalHitboxes)do
pcall(function()
if p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local root =p.Character.HumanoidRootPart
root.Size =origSize
root.Transparency =0
root.CanCollide =true
end
end)
end
originalHitboxes ={}
end
if Aimbot.Settings.Enabled then
local keyOk =not Aimbot.Settings.AimKeyOnly or UserInputService:IsKeyDown(Aimbot.Settings.AimKey)
local target =keyOk and GetTarget(Camera)or nil
Aimbot.LockedTarget =target
if target and Aimbot.Settings.SilentAim then
if Camera.CameraType ~=Enum.CameraType.Custom then
Camera.CameraType =Enum.CameraType.Custom
end
wasAiming =false
Aimbot.IsAiming =true
if LockMarker then
local pos,onScreen =Camera:WorldToViewportPoint(target.Position)
LockMarker.Visible =onScreen
LockMarker.Position =Vector2.new(pos.X,pos.Y)
end
elseif target then
if LockMarker then LockMarker.Visible =false end
if Camera.CameraType ~=Enum.CameraType.Scriptable then
Camera.CameraType =Enum.CameraType.Scriptable
KeepTouchControlsEnabled()
end
wasAiming =true
Aimbot.IsAiming =true
local targetPos =CFrame.new(Camera.CFrame.Position,target.Position)
Camera.CFrame =Camera.CFrame:Lerp(targetPos,Aimbot.Settings.Smoothness *(dt *60))
else
if LockMarker then LockMarker.Visible =false end
if wasAiming then
Camera.CameraType =Enum.CameraType.Custom
wasAiming =false
end
Aimbot.IsAiming =false
end
else
if LockMarker then LockMarker.Visible =false end
Aimbot.LockedTarget =nil
if wasAiming then
Camera.CameraType =Enum.CameraType.Custom
wasAiming =false
end
Aimbot.IsAiming =false
end
end)
function Aimbot:Unload()
self.Settings.Enabled =false
self.Settings.HitboxExpander =false
self.IsAiming =false
self.LockedTarget =nil
for p,origSize in pairs(originalHitboxes)do
pcall(function()
if p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local root =p.Character.HumanoidRootPart
root.Size =origSize
root.Transparency =0
root.CanCollide =true
end
end)
end
originalHitboxes ={}
if self._conn then self._conn:Disconnect()self._conn =nil end
local Camera =Workspace.CurrentCamera
if Camera then Camera.CameraType =Enum.CameraType.Custom end
if FOVCircle then FOVCircle:Remove()end
if LockMarker then LockMarker:Remove()end
end
return Aimbot
-- [Features/AutoTrain.lua]
local AutoTrain ={}
local Players =game:GetService("Players")
local TextChatService =game:GetService("TextChatService")
local Player =Players.LocalPlayer
local usingTextChatService =false
pcall(function()
usingTextChatService =TextChatService.ChatVersion ==Enum.ChatVersion.TextChatService
end)
local function SendChat(message)
if usingTextChatService then
local ok =pcall(function()
local channel =TextChatService.TextChannels:FindFirstChild("RBXGeneral")
if channel then
channel:SendAsync(message)
end
end)
if ok then return true end
end
local ok =pcall(function()
game:GetService("ReplicatedStorage")
.DefaultChatSystemChatEvents
.SayMessageRequest:FireServer(message,"All")
end)
return ok
end
function AutoTrain:Toggle(Config,State,Hub,updateUI)
self._state =State
if State.IsRunning then 
State.IsRunning =false 
if updateUI then updateUI("STATUS: PAUSADO")end
return 
end
State.IsRunning =true
task.spawn(function()
local ok,err =pcall(function()
local step =Config.IsCountdown and -1 or 1
local finish =Config.IsCountdown 
and (Config.StartNum -Config.Quantity)
or (Config.StartNum +Config.Quantity)
for i =Config.StartNum,finish,step do
if not State.IsRunning or not State.IsActive then break end
local mode =Config.Mode or "Canguru"
if updateUI then updateUI(mode .." — Contagem: "..tostring(i))end
local msg =(Hub.Core.Utils and Hub.Core.Utils:NumberToText(i))or tostring(i)
local sent =SendChat(msg .." !")
if not sent then
warn("⚠️ [1NXITER] AutoTrain: falha ao enviar no chat — verifique se o chat está disponível")
end
if Player.Character and Player.Character:FindFirstChild("Humanoid")then
local hum =Player.Character.Humanoid
if mode =="Canguru"then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
elseif mode =="Flexão"then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
elseif mode =="Polichinelo"then
hum:ChangeState(Enum.HumanoidStateType.Jumping)
end
end
task.wait(Config.Delay or 1.4)
end
end)
if not ok then
warn("❌ [1NXITER] AutoTrain: erro na rotina -> "..tostring(err))
if updateUI then updateUI("STATUS: ERRO (veja o console F9)")end
else
if updateUI then updateUI("STATUS: CONCLUÍDO ✅")end
end
State.IsRunning =false
end)
end
function AutoTrain:Unload()
if self._state then
self._state.IsRunning =false
self._state.IsActive =false
end
end
return AutoTrain
-- [Features/ESP.lua]
local ESP ={}
local Players =game:GetService("Players")
local RunService =game:GetService("RunService")
local Workspace =game:GetService("Workspace")
local LocalPlayer =Players.LocalPlayer
ESP.Settings ={
Enabled =false,
TeamCheck =false,
Color =Color3.fromRGB(255,40,40),
FillTransparency =0.6,
Tracers =false,
Distance =false
}
ESP._connections ={}
local function UpdateChams(player,char)
if not char then return end
local highlight =char:FindFirstChild("InxiterChams")
local shouldShow =ESP.Settings.Enabled
and player ~=LocalPlayer
and not (ESP.Settings.TeamCheck and player.Team ==LocalPlayer.Team)
if not shouldShow then
if highlight then highlight:Destroy()end
return
end
if not highlight then
highlight =Instance.new("Highlight")
highlight.Name ="InxiterChams"
highlight.DepthMode =Enum.HighlightDepthMode.AlwaysOnTop
highlight.Parent =char
end
highlight.FillColor =ESP.Settings.Color
highlight.OutlineColor =ESP.Settings.Color
highlight.FillTransparency =ESP.Settings.FillTransparency
highlight.OutlineTransparency =0
end
local function UpdateAll()
for _,player in pairs(Players:GetPlayers())do
UpdateChams(player,player.Character)
end
end
local drawCache ={}
local function ClearDrawing(player)
local data =drawCache[player]
if not data then return end
if data.Line then pcall(function()data.Line:Remove()end)end
if data.Text then pcall(function()data.Text:Remove()end)end
drawCache[player]=nil
end
local function EnsureDrawing(player)
local data =drawCache[player]
if data then return data end
local okLine,line =pcall(function()
local l =Drawing.new("Line")
l.Thickness =1
l.Visible =false
return l
end)
local okText,text =pcall(function()
local t =Drawing.new("Text")
t.Size =13
t.Center =true
t.Outline =true
t.Color =Color3.new(1,1,1)
t.Visible =false
return t
end)
data ={Line =okLine and line or nil,Text =okText and text or nil }
drawCache[player]=data
return data
end
local function UpdateDrawings()
if not (ESP.Settings.Tracers or ESP.Settings.Distance)then return end
local camera =Workspace.CurrentCamera
if not camera then return end
local screenBottom =Vector2.new(camera.ViewportSize.X /2,camera.ViewportSize.Y)
for _,player in pairs(Players:GetPlayers())do
if player ~=LocalPlayer then
local char =player.Character
local root =char and char:FindFirstChild("HumanoidRootPart")
local shouldShow =ESP.Settings.Enabled and root
and not (ESP.Settings.TeamCheck and player.Team ==LocalPlayer.Team)
if shouldShow then
local pos,onScreen =camera:WorldToViewportPoint(root.Position)
local data =EnsureDrawing(player)
if onScreen then
if data.Line then
data.Line.Visible =ESP.Settings.Tracers
data.Line.From =screenBottom
data.Line.To =Vector2.new(pos.X,pos.Y)
data.Line.Color =ESP.Settings.Color
end
if data.Text then
local dist =(camera.CFrame.Position -root.Position).Magnitude
data.Text.Visible =ESP.Settings.Distance
data.Text.Position =Vector2.new(pos.X,pos.Y -16)
data.Text.Text =math.floor(dist).."m"
end
else
if data.Line then data.Line.Visible =false end
if data.Text then data.Text.Visible =false end
end
elseif drawCache[player]then
ClearDrawing(player)
end
end
end
end
local function HookPlayer(player)
table.insert(ESP._connections,player.CharacterAdded:Connect(function(char)
task.wait()
UpdateChams(player,char)
end))
UpdateChams(player,player.Character)
end
function ESP:Toggle(state)
ESP.Settings.Enabled =state
if state then
if #ESP._connections >0 then
for _,c in pairs(ESP._connections)do c:Disconnect()end
ESP._connections ={}
end
for _,player in pairs(Players:GetPlayers())do HookPlayer(player)end
table.insert(ESP._connections,Players.PlayerAdded:Connect(HookPlayer))
table.insert(ESP._connections,RunService.RenderStepped:Connect(UpdateDrawings))
table.insert(ESP._connections,Players.PlayerRemoving:Connect(ClearDrawing))
else
for _,c in pairs(ESP._connections)do c:Disconnect()end
ESP._connections ={}
for _,player in pairs(Players:GetPlayers())do
local char =player.Character
if char then
local hl =char:FindFirstChild("InxiterChams")
if hl then hl:Destroy()end
end
ClearDrawing(player)
end
end
end
function ESP:Refresh()
if ESP.Settings.Enabled then UpdateAll()end
end
function ESP:Unload()
self:Toggle(false)
end
return ESP
-- [Features/FreeCam.lua]
local FreeCam ={}
local RunService =game:GetService("RunService")
local UserInputService =game:GetService("UserInputService")
local Players =game:GetService("Players")
local LocalPlayer =Players.LocalPlayer
FreeCam.Settings ={Enabled =false,Speed =1,Sensitivity =0.5 }
local Conn =nil
local LookConn =nil
local TouchEndConn =nil 
local Rot =Vector2.new(0,0)
local MAX_PITCH =math.rad(89)
local function KeepTouchControlsEnabled()
pcall(function()
local PlayerModule =require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
PlayerModule:GetControls():Enable()
end)
end
local touchDelta =Vector2.new(0,0)
local lastTouchPos =nil
function FreeCam:Toggle(state)
self.Settings.Enabled =state
local Camera =workspace.CurrentCamera
if not Camera then return end
if state then
Camera.CameraType =Enum.CameraType.Scriptable
KeepTouchControlsEnabled()
Rot =Vector2.new(0,0)
touchDelta =Vector2.new(0,0)
lastTouchPos =nil
LookConn =UserInputService.InputChanged:Connect(function(input)
if input.UserInputType ==Enum.UserInputType.Touch then
if lastTouchPos then
touchDelta =Vector2.new(input.Position.X,input.Position.Y)-lastTouchPos
end
lastTouchPos =Vector2.new(input.Position.X,input.Position.Y)
end
end)
TouchEndConn =UserInputService.TouchEnded:Connect(function()
lastTouchPos =nil
end)
Conn =RunService.RenderStepped:Connect(function(dt)
local cam =workspace.CurrentCamera 
if not cam then return end
local delta =UserInputService:GetMouseDelta()
if delta.Magnitude ==0 then
delta =touchDelta
touchDelta =Vector2.new(0,0)
end
Rot =Rot +(delta *-0.005 *self.Settings.Sensitivity)
Rot =Vector2.new(Rot.X,math.clamp(Rot.Y,-MAX_PITCH,MAX_PITCH))
cam.CFrame =CFrame.new(cam.CFrame.Position)*CFrame.Angles(0,Rot.X,0)*CFrame.Angles(Rot.Y,0,0)
local move =Vector3.new()
if UserInputService:IsKeyDown(Enum.KeyCode.W)then move =move +Vector3.new(0,0,-1)end
if UserInputService:IsKeyDown(Enum.KeyCode.S)then move =move +Vector3.new(0,0,1)end
if UserInputService:IsKeyDown(Enum.KeyCode.A)then move =move +Vector3.new(-1,0,0)end
if UserInputService:IsKeyDown(Enum.KeyCode.D)then move =move +Vector3.new(1,0,0)end
local mult =UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)and 4 or 1
if move.Magnitude >0 then
cam.CFrame =cam.CFrame +cam.CFrame:VectorToWorldSpace(move.Unit *self.Settings.Speed *mult)
end
end)
else
if Conn then Conn:Disconnect()Conn =nil end
if LookConn then LookConn:Disconnect()LookConn =nil end
if TouchEndConn then TouchEndConn:Disconnect()TouchEndConn =nil end
Camera.CameraType =Enum.CameraType.Custom
end
end
function FreeCam:Unload()
self:Toggle(false)
end
return FreeCam
-- [Features/PlayerMods.lua]
local PlayerMods ={}
local RunService =game:GetService("RunService")
local UserInputService =game:GetService("UserInputService")
local Players =game:GetService("Players")
local LocalPlayer =Players.LocalPlayer
PlayerMods.Settings ={
SpeedEnabled =false,SpeedValue =50,
JumpEnabled =false,JumpValue =100,
Noclip =false,InfJump =false,
Fly =false,FlySpeed =50,
AntiVoid =false
}
local VOID_Y =-500 
local FlyBV =nil
local flyUpPulseUntil =0 
local lastSafeCFrame =nil
local function GetHumanoid()
return LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
end
local cachedParts ={}
local function RefreshCharacterPartsCache(char)
cachedParts ={}
if not char then return end
for _,part in pairs(char:GetDescendants())do
if part:IsA("BasePart")then table.insert(cachedParts,part)end
end
end
local function RestoreCollisions()
for _,part in pairs(cachedParts)do
if part and part.Parent then part.CanCollide =true end
end
end
local Connections ={}
if LocalPlayer.Character then RefreshCharacterPartsCache(LocalPlayer.Character)end
local descendantConn =nil
table.insert(Connections,LocalPlayer.CharacterAdded:Connect(function(char)
RefreshCharacterPartsCache(char)
if descendantConn then descendantConn:Disconnect()end
descendantConn =char.DescendantAdded:Connect(function(desc)
if desc:IsA("BasePart")then
table.insert(cachedParts,desc)
if PlayerMods.Settings.Noclip then desc.CanCollide =false end
end
end)
end))
table.insert(Connections,RunService.RenderStepped:Connect(function()
local char =LocalPlayer.Character
local hum =GetHumanoid()
local root =char and char:FindFirstChild("HumanoidRootPart")
if hum then
if PlayerMods.Settings.SpeedEnabled then hum.WalkSpeed =PlayerMods.Settings.SpeedValue end
if PlayerMods.Settings.JumpEnabled then 
hum.UseJumpPower =true
hum.JumpPower =PlayerMods.Settings.JumpValue 
end
end
if PlayerMods.Settings.Fly and root and FlyBV then
local moveDir =hum and hum.MoveDirection or Vector3.new()
local vertical =0
if UserInputService:IsKeyDown(Enum.KeyCode.Space)then
vertical =1
elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftControl)then
vertical =-1
elseif tick()<flyUpPulseUntil then
vertical =1
end
FlyBV.Velocity =(moveDir *PlayerMods.Settings.FlySpeed)+Vector3.new(0,vertical *PlayerMods.Settings.FlySpeed,0)
end
if PlayerMods.Settings.AntiVoid and root then
if hum and hum.FloorMaterial ~=Enum.Material.Air and root.Position.Y >VOID_Y then
lastSafeCFrame =root.CFrame
elseif root.Position.Y <VOID_Y and lastSafeCFrame then
root.CFrame =lastSafeCFrame
end
end
end))
table.insert(Connections,RunService.Stepped:Connect(function()
if PlayerMods.Settings.Noclip then
for _,part in pairs(cachedParts)do
if part and part.Parent then part.CanCollide =false end
end
end
end))
table.insert(Connections,UserInputService.JumpRequest:Connect(function()
if PlayerMods.Settings.InfJump then
local hum =GetHumanoid()
if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping)end
end
if PlayerMods.Settings.Fly then
flyUpPulseUntil =tick()+0.35
end
end))
function PlayerMods:ToggleSpeed(v)self.Settings.SpeedEnabled =v end
function PlayerMods:ToggleJumpPower(v)self.Settings.JumpEnabled =v end
function PlayerMods:ToggleNoclip(v)
self.Settings.Noclip =v
if not v then RestoreCollisions()end
end
function PlayerMods:ToggleInfJump(v)self.Settings.InfJump =v end
function PlayerMods:ToggleFly(v)
self.Settings.Fly =v
local char =LocalPlayer.Character
local hum =char and char:FindFirstChildOfClass("Humanoid")
local root =char and char:FindFirstChild("HumanoidRootPart")
if v then
if not root then self.Settings.Fly =false return end
if not FlyBV then
FlyBV =Instance.new("BodyVelocity")
FlyBV.Name ="InxiterFly"
FlyBV.MaxForce =Vector3.new(1e9,1e9,1e9)
end
FlyBV.Velocity =Vector3.new()
FlyBV.Parent =root
if hum then hum.PlatformStand =true end
else
if FlyBV then FlyBV.Parent =nil end
if hum then hum.PlatformStand =false end
end
end
function PlayerMods:ToggleAntiVoid(v)
self.Settings.AntiVoid =v
lastSafeCFrame =nil
end
function PlayerMods:DisableAll()
self.Settings.SpeedEnabled =false
self.Settings.JumpEnabled =false
self.Settings.Noclip =false
self.Settings.InfJump =false
self.Settings.Fly =false
self.Settings.AntiVoid =false
RestoreCollisions()
if FlyBV then FlyBV.Parent =nil end
local hum =GetHumanoid()
if hum then
hum.WalkSpeed =16
hum.JumpPower =50
hum.PlatformStand =false
end
end
function PlayerMods:Unload()
self:DisableAll()
for _,c in pairs(Connections)do c:Disconnect()end
Connections ={}
if descendantConn then descendantConn:Disconnect()descendantConn =nil end
if FlyBV then FlyBV:Destroy()FlyBV =nil end
end
return PlayerMods
-- [Features/SpyChat.lua]
local SpyChat ={}
local Players =game:GetService("Players")
local UserInputService =game:GetService("UserInputService")
local CoreGui =game:GetService("CoreGui")
local TextChatService =game:GetService("TextChatService")
SpyChat.Enabled =false
SpyChat.Gui =nil
SpyChat.Minimized =false
SpyChat.Connections ={}
local function MakeDraggable(frame,handle)
local dragging,dragStart,startPos
local conns ={}
table.insert(conns,handle.InputBegan:Connect(function(input)
if input.UserInputType ==Enum.UserInputType.MouseButton1 or input.UserInputType ==Enum.UserInputType.Touch then
dragging =true;dragStart =input.Position;startPos =frame.Position
local changedConn
changedConn =input.Changed:Connect(function()
if input.UserInputState ==Enum.UserInputState.End then
dragging =false
if changedConn then changedConn:Disconnect()end
end
end)
table.insert(conns,changedConn)
end
end))
table.insert(conns,UserInputService.InputChanged:Connect(function(input)
if dragging and (input.UserInputType ==Enum.UserInputType.MouseMovement or input.UserInputType ==Enum.UserInputType.Touch)then
local delta =input.Position -dragStart
frame.Position =UDim2.new(startPos.X.Scale,startPos.X.Offset +delta.X,startPos.Y.Scale,startPos.Y.Offset +delta.Y)
end
end))
return conns
end
local function EscapeRichText(s)
s =tostring(s)
s =s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","&quot;")
return s
end
function SpyChat:LogMessage(pName,msg)
if not self.Gui or not self.Enabled then return end
local scroll =self.Gui.Main.Content.Scroll
local label =Instance.new("TextLabel")
label.Name =pName 
label.Parent =scroll
label.Size =UDim2.new(1,-10,0,20)
label.BackgroundTransparency =1
label.RichText =true
label.TextXAlignment =Enum.TextXAlignment.Left
label.Font =Enum.Font.Code
label.TextSize =14
label.TextColor3 =Color3.new(1,1,1)
label.Text =string.format(
"<font color='#AAAAAA'>[%s]</font> <font color='#00E5FF'><b>%s:</b></font> %s",
os.date("%X"),EscapeRichText(pName),EscapeRichText(msg)
)
label.AutomaticSize =Enum.AutomaticSize.Y
label.TextWrapped =true
end
function SpyChat:Filter(text)
local scroll =self.Gui.Main.Content.Scroll
local query =text:lower()
for _,child in pairs(scroll:GetChildren())do
if child:IsA("TextLabel")then
child.Visible =child.Name:lower():find(query)and true or false
end
end
end
function SpyChat:Toggle(state)
self.Enabled =state
if state then
local sg =Instance.new("ScreenGui",CoreGui);sg.Name ="InxiterSpyHUD"
self.Gui =sg
local main =Instance.new("Frame",sg)
main.Name ="Main"
main.Size =UDim2.new(0,400,0,250)
main.Position =UDim2.new(0.5,-200,0.5,-125)
main.BackgroundColor3 =Color3.fromRGB(15,15,15)
main.BackgroundTransparency =0.1
main.BorderSizePixel =0
local top =Instance.new("Frame",main)
top.Name ="Top"
top.Size =UDim2.new(1,0,0,30)
top.BackgroundColor3 =Color3.fromRGB(10,10,10)
top.BorderSizePixel =0
for _,c in pairs(MakeDraggable(main,top))do
if c then table.insert(self.Connections,c)end
end
local title =Instance.new("TextLabel",top)
title.Text ="  CHAT LOGS (HD ADMIN STYLE)"
title.Size =UDim2.new(1,-80,1,0)
title.BackgroundTransparency =1
title.TextColor3 =Color3.new(1,1,1)
title.Font =Enum.Font.GothamBold
title.TextSize =12
title.TextXAlignment =Enum.TextXAlignment.Left
local close =Instance.new("TextButton",top)
close.Text ="X";close.Size =UDim2.new(0,30,1,0);close.Position =UDim2.new(1,-30,0,0)
close.BackgroundColor3 =Color3.fromRGB(150,0,0);close.TextColor3 =Color3.new(1,1,1)
close.MouseButton1Click:Connect(function()self:Toggle(false)end)
local mini =Instance.new("TextButton",top)
mini.Text ="-";mini.Size =UDim2.new(0,30,1,0);mini.Position =UDim2.new(1,-60,0,0)
mini.BackgroundColor3 =Color3.fromRGB(40,40,40);mini.TextColor3 =Color3.new(1,1,1)
mini.MouseButton1Click:Connect(function()
self.Minimized =not self.Minimized
main.Content.Visible =not self.Minimized
main.Size =self.Minimized and UDim2.new(0,400,0,30)or UDim2.new(0,400,0,250)
end)
local content =Instance.new("Frame",main)
content.Name ="Content"
content.Size =UDim2.new(1,0,1,-30)
content.Position =UDim2.new(0,0,0,30)
content.BackgroundTransparency =1
local search =Instance.new("TextBox",content)
search.PlaceholderText ="Pesquisar usuário..."
search.Size =UDim2.new(1,-20,0,25)
search.Position =UDim2.new(0,10,0,5)
search.BackgroundColor3 =Color3.fromRGB(25,25,25)
search.TextColor3 =Color3.new(1,1,1)
search.BorderSizePixel =0
search:GetPropertyChangedSignal("Text"):Connect(function()self:Filter(search.Text)end)
local scroll =Instance.new("ScrollingFrame",content)
scroll.Name ="Scroll"
scroll.Size =UDim2.new(1,-20,1,-45)
scroll.Position =UDim2.new(0,10,0,35)
scroll.BackgroundTransparency =1
scroll.CanvasSize =UDim2.new(0,0,0,0)
scroll.ScrollBarThickness =2
scroll.AutomaticCanvasSize =Enum.AutomaticSize.Y
local layout =Instance.new("UIListLayout",scroll)
layout.SortOrder =Enum.SortOrder.LayoutOrder;layout.Padding =UDim.new(0,5)
local usingTextChatService =TextChatService.ChatVersion ==Enum.ChatVersion.TextChatService
if not usingTextChatService then
local function hook(p)
local c =p.Chatted:Connect(function(m)self:LogMessage(p.Name,m)end)
table.insert(self.Connections,c)
end
for _,p in pairs(Players:GetPlayers())do hook(p)end
table.insert(self.Connections,Players.PlayerAdded:Connect(hook))
else
local c =TextChatService.MessageReceived:Connect(function(res)
if res.TextSource then self:LogMessage(res.TextSource.DisplayName,res.Text)end
end)
table.insert(self.Connections,c)
end
else
if self.Gui then self.Gui:Destroy();self.Gui =nil end
for _,c in pairs(self.Connections)do c:Disconnect()end
self.Connections ={}
end
end
function SpyChat:Unload()
self:Toggle(false)
end
return SpyChat
-- [Features/Visuals.lua]
local Visuals ={}
local RunService =game:GetService("RunService")
Visuals.Settings ={StretchedEnabled =false,FOVValue =100 }
Visuals._conn =nil
function Visuals:ToggleStretched(v)
self.Settings.StretchedEnabled =v
if v then
local Camera =workspace.CurrentCamera
if Camera then Camera.FieldOfView =self.Settings.FOVValue end
if not self._conn then
self._conn =RunService.RenderStepped:Connect(function()
if Visuals.Settings.StretchedEnabled then
local cam =workspace.CurrentCamera
if cam then cam.FieldOfView =Visuals.Settings.FOVValue end
end
end)
end
else
if self._conn then self._conn:Disconnect()self._conn =nil end
local Camera =workspace.CurrentCamera
if Camera then Camera.FieldOfView =70 end
end
end
function Visuals:UpdateFOV(v)
self.Settings.FOVValue =v
if self.Settings.StretchedEnabled then
local Camera =workspace.CurrentCamera
if Camera then Camera.FieldOfView =v end
end
end
function Visuals:Unload()
self.Settings.StretchedEnabled =false
if self._conn then self._conn:Disconnect()self._conn =nil end
local Camera =workspace.CurrentCamera
if Camera then Camera.FieldOfView =70 end
end
return Visuals
-- [Interface/Main.lua]
local InterfaceMain ={}
local function GetCustomIconAsset()
if not (writefile and getcustomasset and isfile)then return nil end
local ICON_URL ="https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png"
local fileName ="1nxiter_icon.png"
local ok,result =pcall(function()
if not isfile(fileName)then
local data =game:HttpGet(ICON_URL .."?cache="..math.random(1,999999))
writefile(fileName,data)
end
return getcustomasset(fileName)
end)
return ok and result or nil
end
function InterfaceMain:Load(Hub,Config,State)
local success,WindUI =pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not success or not WindUI then
return warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI.")
end
pcall(function()WindUI:SetNotificationLower(true)end)
local customIcon =GetCustomIconAsset()
local windowConfig ={
Title ="1NXITER HUB",
Author ="V3.0 · Modular SRC",
Icon =customIcon or "house",
Folder ="InxiterHub",
Size =UDim2.fromOffset(580,460),
ToggleKey =Enum.KeyCode.LeftControl,
OpenButton ={
Title ="1NX",
Enabled =true,
Draggable =true,
OnlyMobile =false,
Color =ColorSequence.new(
Color3.fromRGB(120,60,200),
Color3.fromRGB(60,30,110)
),
},
}
local ok,Window =pcall(function()return WindUI:CreateWindow(windowConfig)end)
if not ok or not Window then
return warn("❌ [1NXITER]: Falha ao criar a janela WindUI -> "..tostring(Window))
end
local Players =game:GetService("Players")
local LocalPlayer =Players.LocalPlayer
local UserInputService =game:GetService("UserInputService")
local function KeepTouchControlsEnabled()
pcall(function()
local PlayerModule =require(LocalPlayer.PlayerScripts:WaitForChild("PlayerModule"))
PlayerModule:GetControls():Enable()
end)
pcall(function()UserInputService.ModalEnabled =false end)
end
KeepTouchControlsEnabled()
Window:OnOpen(KeepTouchControlsEnabled)
Window:OnClose(KeepTouchControlsEnabled)
local Tabs ={
Train =Window:Tab({Title ="Treino",Icon ="activity"}),
Combat =Window:Tab({Title ="Combate",Icon ="swords"}),
ESP =Window:Tab({Title ="Visual",Icon ="eye"}),
Movement =Window:Tab({Title ="Movimento",Icon ="move"}),
Camera =Window:Tab({Title ="Câmera",Icon ="camera"}),
System =Window:Tab({Title ="Sistema",Icon ="settings"})
}
local function SafeRender(tabName,tabObject)
local tabModule =Hub.UI.Tabs[tabName]
if tabModule and tabModule.Render then
local ok,err =pcall(function()
tabModule:Render(tabObject,Hub,Config,State)
end)
if not ok then warn("❌ [1NXITER]: Erro ao renderizar aba "..tabName ..": "..tostring(err))end
else
warn("⚠️ [1NXITER]: Módulo de aba não encontrado: "..tabName)
end
end
Hub.UI.Library =WindUI
Hub.UI.Window =Window
SafeRender("TrainTab",Tabs.Train)
SafeRender("CombatTab",Tabs.Combat)
SafeRender("ESPTab",Tabs.ESP)
SafeRender("MovementTab",Tabs.Movement)
SafeRender("CameraTab",Tabs.Camera)
SafeRender("SystemTab",Tabs.System)
Tabs.Train:Select()
WindUI:Notify({
Title ="1NXITER HUB",
Content ="Interface carregada com sucesso!",
Icon ="solar:bell-bold",
Duration =5
})
end
return InterfaceMain
-- [Interface/Tabs/CameraTab.lua]
local Tab ={}
function Tab:Render(WindowTab,Hub,Config)
local Vis =Hub.Features.Visuals
local Cam =Hub.Features.FreeCam
local Spy =Hub.Features.SpyChat
WindowTab:Section({Title ="Visual de Tela",Icon ="monitor"})
WindowTab:Toggle({Flag ="StretchE",Title ="Tela Esticada",Icon ="maximize-2",Value =false,Callback =function(v)Vis:ToggleStretched(v)end })
WindowTab:Slider({
Flag ="FOVVal",Title ="Zoom",Step =1,
Value ={Min =30,Max =120,Default =70 },
Callback =function(v)Vis:UpdateFOV(v)end
})
WindowTab:Section({Title ="Câmera Livre",Icon ="video"})
WindowTab:Toggle({Flag ="FreeE",Title ="Ativar FreeCam",Icon ="video",Value =false,Callback =function(v)Cam:Toggle(v)end })
WindowTab:Slider({
Flag ="FreeCamSpeed",Title ="Velocidade",Step =0.1,
Value ={Min =0.1,Max =10,Default =1 },
Callback =function(v)Cam.Settings.Speed =v end
})
WindowTab:Slider({
Flag ="FreeCamSens",Title ="Sensibilidade",Step =0.1,
Value ={Min =0.1,Max =3,Default =0.5 },
Callback =function(v)Cam.Settings.Sensitivity =v end
})
WindowTab:Section({Title ="Espionagem",Icon ="message-square"})
WindowTab:Toggle({Flag ="SpyE",Title ="Logs Spy Chat",Icon ="message-square-more",Value =false,Callback =function(v)Spy:Toggle(v)end })
end
return Tab
-- [Interface/Tabs/CombatTab.lua]
local Tab ={}
function Tab:Render(WindowTab,Hub,Config,State)
local Aim =Hub.Features.Aimbot
WindowTab:Section({
Title ="Aimbot Master",
Icon ="crosshair"
})
local Status =WindowTab:Section({
Title ="Status",
Desc ="Aimbot desligado"
})
task.spawn(function()
while getgenv().InxiterHubLoaded do
if not Aim.Settings.Enabled then
Status:SetDesc("Aimbot desligado")
elseif Aim.Settings.SilentAim and Aim.IsAiming then
Status:SetDesc("🔒 Alvo travado (Silent Aim — câmera livre)")
elseif Aim.IsAiming then
Status:SetDesc("🎯 Mirando em alvo")
else
Status:SetDesc("👀 Procurando alvo...")
end
task.wait(0.3)
end
end)
WindowTab:Toggle({
Flag ="AimE",
Title ="Ativar Auto-Mira",
Icon ="crosshair",
Value =false,
Callback =function(v)
Aim.Settings.Enabled =v
end
})
WindowTab:Toggle({
Flag ="AimSilent",
Title ="Silent Aim (não gira a câmera)",
Icon ="target",
Value =false,
Callback =function(v)
Aim.Settings.SilentAim =v
end
})
WindowTab:Toggle({
Flag ="AimKeyOnly",
Title ="Só mirar segurando E",
Icon ="keyboard",
Value =false,
Callback =function(v)
Aim.Settings.AimKeyOnly =v
end
})
WindowTab:Dropdown({
Flag ="AimPriority",
Title ="Prioridade de Alvo",
Values ={
"Mais perto da mira",
"Menor vida"
},
Value ="Mais perto da mira",
Callback =function(v)
Aim.Settings.Priority =
(v =="Menor vida")and "LowHealth"or "Closest"
end
})
WindowTab:Toggle({
Flag ="AimTeam",
Title ="Ignorar Time",
Icon ="users",
Value =false,
Callback =function(v)
Aim.Settings.TeamCheck =v
end
})
WindowTab:Toggle({
Flag ="AimW",
Title ="Wall Check",
Icon ="scan-eye",
Value =true,
Callback =function(v)
Aim.Settings.WallCheck =v
end
})
WindowTab:Toggle({
Flag ="AimFOVShow",
Title ="Mostrar Círculo do FOV",
Icon ="circle-dot",
Value =false,
Callback =function(v)
Aim.Settings.ShowFOV =v
end
})
WindowTab:Slider({
Flag ="AimS",
Title ="Suavidade",
Step =0.1,
Value ={
Min =0.1,
Max =1,
Default =0.5
},
Callback =function(v)
Aim.Settings.Smoothness =v
end
})
WindowTab:Slider({
Flag ="AimF",
Title ="Raio do FOV",
Step =1,
Value ={
Min =30,
Max =800,
Default =150
},
Callback =function(v)
Aim.Settings.FOVRadius =v
end
})
WindowTab:Section({
Title ="Hitbox Expander",
Icon ="scan"
})
WindowTab:Toggle({
Flag ="HitE",
Title ="Aumentar Hitbox",
Icon ="expand",
Value =false,
Callback =function(v)
Aim.Settings.HitboxExpander =v
end
})
WindowTab:Slider({
Flag ="HitS",
Title ="Tamanho da Hitbox",
Step =1,
Value ={
Min =2,
Max =50,
Default =10
},
Callback =function(v)
Aim.Settings.HitboxSize =v
end
})
end
return Tab
-- [Interface/Tabs/ESPTab.lua]
local Tab ={}
function Tab:Render(WindowTab,Hub,Config)
local Mod =Hub.Features.ESP
local Players =game:GetService("Players")
WindowTab:Section({Title ="Chams",Icon ="eye"})
local Status =WindowTab:Section({Title ="Jogadores detectados",Desc ="ESP desligado"})
task.spawn(function()
while getgenv().InxiterHubLoaded do
if Mod.Settings.Enabled then
local count =math.max(0,#Players:GetPlayers()-1)
Status:SetDesc(tostring(count).." jogador(es) na partida")
else
Status:SetDesc("ESP desligado")
end
task.wait(1)
end
end)
WindowTab:Toggle({Flag ="ESPE",Title ="Ativar Chams",Icon ="eye",Value =false,Callback =function(v)Mod:Toggle(v)end })
WindowTab:Toggle({
Flag ="ESPT",
Title ="Ocultar Aliados",Icon ="user-round-x",
Value =false,
Callback =function(v)
Mod.Settings.TeamCheck =v
Mod:Refresh()
end
})
WindowTab:Slider({
Flag ="ESPFill",
Title ="Transparência do Preenchimento",
Step =0.01,
Value ={Min =0,Max =1,Default =0.6 },
Callback =function(v)
Mod.Settings.FillTransparency =v
Mod:Refresh()
end
})
WindowTab:Section({Title ="Extras",Icon ="sparkles"})
WindowTab:Toggle({Flag ="ESPTracer",Title ="Tracers (linha até o jogador)",Icon ="route",Value =false,Callback =function(v)Mod.Settings.Tracers =v end })
WindowTab:Toggle({Flag ="ESPDist",Title ="Mostrar Distância",Icon ="ruler",Value =false,Callback =function(v)Mod.Settings.Distance =v end })
end
return Tab
-- [Interface/Tabs/MovementTab.lua]
local Tab ={}
function Tab:Render(WindowTab,Hub,Config)
local Mod =Hub.Features.PlayerMods
WindowTab:Section({Title ="Atributos",Icon ="gauge"})
WindowTab:Toggle({Flag ="SpeedE",Title ="Ativar Speed",Icon ="gauge",Value =false,Callback =function(v)Mod:ToggleSpeed(v)end })
WindowTab:Slider({
Flag ="SpeedV",Title ="Velocidade",Step =1,
Value ={Min =16,Max =500,Default =50 },
Callback =function(v)Mod.Settings.SpeedValue =v end
})
WindowTab:Toggle({Flag ="JumpE",Title ="Ativar Jump Power",Icon ="arrow-up",Value =false,Callback =function(v)Mod:ToggleJumpPower(v)end })
WindowTab:Slider({
Flag ="JumpV",Title ="Força do Pulo",Step =1,
Value ={Min =50,Max =500,Default =100 },
Callback =function(v)Mod.Settings.JumpValue =v end
})
WindowTab:Section({Title ="Física",Icon ="atom"})
WindowTab:Toggle({Flag ="NoclipE",Title ="Atravessar Paredes",Icon ="move-3d",Value =false,Callback =function(v)Mod:ToggleNoclip(v)end })
WindowTab:Toggle({Flag ="InfJumpE",Title ="Pulo Infinito",Icon ="infinity",Value =false,Callback =function(v)Mod:ToggleInfJump(v)end })
WindowTab:Section({Title ="Voo",Icon ="plane"})
WindowTab:Toggle({Flag ="FlyE",Title ="Ativar Fly",Icon ="plane",Value =false,Callback =function(v)Mod:ToggleFly(v)end })
WindowTab:Slider({
Flag ="FlyV",Title ="Velocidade do Fly",Step =1,
Value ={Min =10,Max =300,Default =50 },
Callback =function(v)Mod.Settings.FlySpeed =v end
})
WindowTab:Section({
Title ="Controles do Fly",
Icon ="gamepad-2",
Desc ="Anda com WASD/joystick. Espaço = subir, Ctrl = descer (teclado). No touch sem teclado, o botão de pulo dá um empurrão pra cima."
})
WindowTab:Section({Title ="Segurança",Icon ="shield-check"})
WindowTab:Toggle({
Flag ="AntiVoidE",
Title ="Anti-Queda (void)",Icon ="shield-alert",
Value =false,
Callback =function(v)Mod:ToggleAntiVoid(v)end
})
end
return Tab
-- [Interface/Tabs/SystemTab.lua]
local Tab ={}
local function IsPlaceholderLink(link)
if not link or link ==""then return true end
if link:find("SEU%-")or link:find("YOUR%-")or link:find("PLACEHOLDER")then return true end
return false
end
local function CopyToClipboard(text)
local copier =setclipboard or toclipboard
if type(copier)~="function"then
return false
end
local ok =pcall(copier,text)
return ok
end
function Tab:Render(WindowTab,Hub,Config,State)
local Utils =Hub.Core.Utils
local StateMod =Hub.Core.State
local WindUI =Hub.UI.Library
WindowTab:Section({
Title ="Aparência",
Icon ="palette"
})
WindowTab:Dropdown({
Flag ="UITheme",
Title ="Tema",
Values =(function()
local names ={}
for name in pairs(WindUI:GetThemes())do
table.insert(names,name)
end
table.sort(names)
return names
end)(),
Value =WindUI:GetCurrentTheme(),
Callback =function(v)
WindUI:SetTheme(v)
Config.UITheme =v
end
})
WindowTab:Section({
Title ="Gerenciamento",
Icon ="folder-cog"
})
WindowTab:Button({
Title ="SALVAR CONFIGURAÇÕES",
Icon ="save",
IconAlign ="Left",
Callback =function()
StateMod:SaveConfig(Config)
WindUI:Notify({
Title ="Salvo",
Content ="JSON atualizado!",
Icon ="check",
Duration =3
})
end
})
WindowTab:Button({
Title ="RESTAURAR PADRÕES",
Icon ="rotate-ccw",
IconAlign ="Left",
Callback =function()
StateMod:ResetConfig(Config)
StateMod:SaveConfig(Config)
WindUI:Notify({
Title ="Configurações restauradas",
Content ="Reabra o hub pra ver os controles atualizados.",
Icon ="refresh-cw",
Duration =5
})
end
})
WindowTab:Toggle({
Flag ="AutoRejoinE",
Title ="Auto-Rejoin (ao cair do servidor)",
Value =Config.AutoRejoin or false,
Callback =function(v)
Config.AutoRejoin =v
end
})
WindowTab:Section({
Title ="Utilitários",
Icon ="wrench"
})
WindowTab:Button({
Title ="FPS BOOST",
Icon ="zap",
IconAlign ="Left",
Callback =function()
Utils:AntiLag()
end
})
WindowTab:Button({
Title ="REJOIN",
Icon ="refresh-cw",
IconAlign ="Left",
Callback =function()
Utils:Rejoin()
end
})
WindowTab:Button({
Title ="SERVER HOP",
Icon ="globe",
IconAlign ="Left",
Callback =function()
Utils:ServerHop()
end
})
WindowTab:Section({
Title ="Discord",
Icon ="messages-square"
})
WindowTab:Paragraph({
Title ="Servidor do Discord",
Desc ='Entre na comunidade 1NXITER. Toque em "Copiar link" para copiar o convite.',
Image ="https://cdn.simpleicons.org/discord",
ImageSize =28,
Color ="White",
Buttons ={
{
Title ="Copiar link",
Icon ="copy",
Variant ="Tertiary",
Callback =function()
local DiscordLink =Config.DiscordLink
if IsPlaceholderLink(DiscordLink)then
WindUI:Notify({
Title ="Discord",
Content ="Configure Config.DiscordLink com o convite do servidor.",
Icon ="triangle-alert",
Duration =4
})
return
end
if CopyToClipboard(DiscordLink)then
WindUI:Notify({
Title ="Discord",
Content ="Link copiado!",
Icon ="check",
Duration =3
})
else
WindUI:Notify({
Title ="Discord",
Content =DiscordLink,
Icon ="copy",
Duration =5
})
end
end
}
}
})
WindowTab:Section({
Title ="Sistema",
Icon ="power"
})
WindowTab:Button({
Title ="FECHAR HUB",
Icon ="power",
IconAlign ="Left",
Callback =function()
Hub:Unload()
getgenv().InxiterHubLoaded =false
getgenv().InxiterHubInstance =nil
end
})
end
return Tab
-- [Interface/Tabs/TrainTab.lua]
local Tab ={}
function Tab:Render(WindowTab,Hub,Config,State)
local Mod =Hub.Features.AutoTrain
WindowTab:Section({Title ="Controle de Treino",Icon ="dumbbell"})
local Status =WindowTab:Section({Title ="Monitor",Desc ="Aguardando início..."})
WindowTab:Button({
Title ="INICIAR / PARAR TREINO",
Icon ="play",
Callback =function()
if Mod then
Mod:Toggle(Config,State,Hub,function(t)Status:SetDesc(t)end)
end
end
})
WindowTab:Dropdown({
Flag ="TrainMode",
Title ="Modo de Exercício",
Values ={"Canguru","Flexão","Polichinelo"},
Value =Config.Mode or "Canguru",
Callback =function(v)Config.Mode =v end
})
WindowTab:Section({Title ="Configurações da Série",Icon ="sliders-horizontal"})
WindowTab:Input({
Flag ="StartNum",
Title ="Número Inicial",
Value ="0",
Callback =function(v)Config.StartNum =tonumber(v)or 0 end
})
WindowTab:Input({
Flag ="Quantity",
Title ="Quantidade de Números",
Value ="50",
Callback =function(v)Config.Quantity =tonumber(v)or 50 end
})
Config.Quantity =Config.Quantity or 50
WindowTab:Toggle({
Flag ="IsCountdown",
Title ="Contagem Regressiva",
Value =false,
Callback =function(v)Config.IsCountdown =v end
})
WindowTab:Slider({
Flag ="TrainDelay",
Title ="Velocidade (Delay)",
Step =0.1,
Value ={Min =0.5,Max =5,Default =1.4 },
Callback =function(v)Config.Delay =v end
})
WindowTab:Toggle({
Flag ="AutoCrouch",
Title ="Auto Agachar (Canguru)",
Value =false,
Callback =function(v)Config.AutoCrouch =v end
})
end
return Tab