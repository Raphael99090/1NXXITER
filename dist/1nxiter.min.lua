-- [main.lua]
if getgenv().InxiterHubLoaded and getgenv().InxiterHubInstance then
warn("♻️ [1NXITER]: Instância anterior detectada — desligando antes de recarregar...")
local ak,ab =pcall(function()
getgenv().InxiterHubInstance:Unload()
end)
if not ak then
warn("⚠️ [1NXITER]: Erro ao desligar instância anterior -> "..tostring(ab))
end
getgenv().InxiterHubLoaded =false
getgenv().InxiterHubInstance =nil
end
local o ="Raphael99090/1NXXITER"
local b ="main"
local a ="https://raw.githubusercontent.com/"..o .."/"..b .."/src/"
local l ="1nxxiter"
local k ="https://ads.pandauth.com/getkey/"..l
local j ="https://api.pandadevelopment.net"
local s =false
local t ="TESTE-1NX"
if s then
warn("🧪 [1NXITER]: MODO DE TESTE ATIVO — key '"..t .."' libera sem checar o Panda. Desliga TESTING_MODE antes de publicar!")
end
local function e()
local ak,ah =pcall(function()
if gethwid then return gethwid()end
if get_hwid then return get_hwid()end
if identifyexecutor then
local aj =identifyexecutor()
return "id-"..tostring(aj).."-"..tostring(game:GetService("RbxAnalyticsService"):GetClientId())
end
return game:GetService("RbxAnalyticsService"):GetClientId()
end)
return ak and tostring(ah)or "unknown-hwid"
end
local m =false
local n =nil
task.spawn(function()
local ak,ai =pcall(function()
return loadstring(game:HttpGet("https://secure.pandauth.com/pv4/lib"))()
end)
if ak and ai and type(ai.configure)=="function"then
ai.configure({
serviceId =l,
})
n =ai
m =true
print("✅ [1NXITER]: Biblioteca do Panda Auth (PUSL V4) carregada com sucesso!")
else
warn("⚠️ [1NXITER]: Falha ao carregar a biblioteca do Panda Auth.")
end
end)
local function v(key,ag,callback)
print("🔑 [1NXITER]: Validando key no Panda...")
if not m or not n then
callback(false,"A biblioteca do Panda ainda está carregando ou falhou.\nTente novamente em alguns segundos.")
return
end
local ak,am =pcall(function()
return n.validate(key)
end)
if not ak or type(am)~="table"then
callback(false,"Erro interno de conexão com o Panda.")
return
end
if am.success then
print("✅ [1NXITER]: Key validada pelo Panda! Premium: "..tostring(am.isPremium))
callback(true)
else
callback(false,"Key inválida ou recusada pelo servidor.\nPegue uma nova no GetKey.")
end
end
local function c(key,callback)
if s then
if key ==t then
callback(true)
return
end
end
v(key,e(),callback)
end
local function p(onSuccess)
local ag =e()
local ao,w =pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not ao or not w then
warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI para o Key System.")
return
end
local x =w:CreateWindow({
Title ="1NXITER HUB",
Author ="Panda Key System",
Icon ="key",
Folder ="InxiterHub",
Size =UDim2.fromOffset(450,320),
OpenButton =false,
Transparent =true,
Theme ="Dark"
})
local u =x:Tab({Title ="Autenticação",Icon ="lock"})
local h =""
u:Input({
Title ="Insira sua Key",
Desc ="Cole a key gerada pelo Panda Auth abaixo.",
PlaceholderText ="Cole aqui...",
Callback =function(text)
h =text
end
})
u:Button({
Title ="Obter Key (Copiar Link)",
Desc ="Copia o link para o seu navegador.",
Icon ="link",
Callback =function()
local al =k .."?hwid="..ag
local aa =setclipboard or toclipboard
if type(aa)=="function"then
pcall(aa,al)
w:Notify({Title ="Key System",Content ="Link copiado para a área de transferência!",Duration =3})
else
w:Notify({Title ="Key System",Content ="Abra: "..al,Duration =5})
end
end
})
u:Button({
Title ="Copiar HWID",
Desc =ag,
Icon ="copy",
Callback =function()
local aa =setclipboard or toclipboard
if type(aa)=="function"then
pcall(aa,ag)
w:Notify({Title ="Key System",Content ="HWID copiado!",Duration =3})
end
end
})
local y =false
u:Button({
Title ="Validar e Entrar",
Icon ="check",
Callback =function()
if y then return end
if h ==""then
w:Notify({Title ="Aviso",Content ="Insira sua key antes de confirmar.",Duration =3})
return
end
y =true
w:Notify({Title ="Key System",Content ="Verificando key...",Duration =2})
c(h,function(valid,errorMsg)
y =false
if valid then
w:Notify({Title ="Sucesso",Content ="Key validada! Carregando Hub...",Duration =2})
task.wait(1.5)
pcall(function()x:Destroy()end)
onSuccess()
else
w:Notify({Title ="Erro",Content =errorMsg or "Key inválida. Tente novamente.",Duration =4})
end
end)
end
})
u:Select()
end
local f ={
Core ={},
Features ={},
UI ={
Tabs ={}
}
}
function f:Unload()
for aj,feature in pairs(self.Features)do
if type(feature)=="table"and feature.Unload then
local ak,ab =pcall(function()feature:Unload()end)
if not ak then
warn("⚠️ [1NXITER]: Erro ao descarregar Features/"..aj .." -> "..tostring(ab))
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
local function g(path)
local aq =a ..path ..".lua"
print("📥 [1NXITER]: Carregando -> "..path)
local ao,z =pcall(function()
return game:HttpGet(aq .."?cache="..math.random(1,999999))
end)
if ao and z and not z:match("^404")then
local af,ab =loadstring(z)
if af then
local an,am =pcall(af)
if an then
return am 
else
warn("❌ [1NXITER]: Erro ao executar módulo ("..path .."): "..tostring(am))
end
else
warn("❌ [1NXITER]: Erro de sintaxe em ("..path .."): "..tostring(ab))
end
else
warn("❌ [1NXITER]: Arquivo não encontrado ou erro de rede (404) -> "..aq)
end
return nil
end
local function i()
f.Core.Utils =g("Core/Utils")
f.Core.State =g("Core/State")
local ac ={
"AutoTrain","Aimbot","ESP","PlayerMods","FreeCam","SpyChat","Visuals"
}
for _,f in pairs(ac)do
f.Features[f]=g("Features/"..f)
end
local ap ={
"TrainTab","CombatTab","ESPTab","MovementTab","CameraTab","SystemTab"
}
for _,t in pairs(ap)do
f.UI.Tabs[t]=g("Interface/Tabs/"..t)
end
f.UI.Main =g("Interface/Main")
local function r()
if not f.Core.State or not f.UI.Main then
return warn("❌ [1NXITER]: Falha crítica. Verifique se as pastas e nomes no GitHub estão corretos.")
end
print("✅ [1NXITER]: Todos os módulos carregados. Iniciando sistema...")
getgenv().InxiterHubLoaded =true
getgenv().InxiterHubInstance =f
local d =f.Core.State:LoadConfig()
local q =f.Core.State:GetRuntimeState()
f.Core.State:StartAutoSave(d,8)
if f.Core.Utils then
f.Core.Utils:AntiAFK(q)
f.Core.Utils:AutoRejoin(d)
end
f.UI.Main:Load(f,d,q)
end
local ae,ad =pcall(r)
if not ae then
getgenv().InxiterHubLoaded =false
warn("❌ [1NXITER]: Erro fatal durante a inicialização -> "..tostring(ad))
end
end
p(i)
-- [Core/State.lua]
local i ={}
local g =game:GetService("HttpService")
local e ="1NXITER_HUB"
local d =e .."/Config_v3.json"
local c ={
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
local h ={
IsRunning =false,
IsActive =true,
LoadedAt =os.date("%X")
}
local function f()
return isfile and readfile and writefile and makefolder and isfolder
end
local function b(target,source)
for k,v in pairs(source)do
if type(v)=="table"and type(target[k])=="table"then
b(target[k],v)
else
target[k]=v
end
end
return target
end
local function a(t)
local k ={}
for k,v in pairs(t)do
k[k]=(type(v)=="table")and a(v)or v
end
return k
end
function i:GetRuntimeState()
return h
end
function i:LoadConfig()
if not f()then return c end
if isfile(d)then
local s,j =pcall(readfile,d)
if s then
local m,n =pcall(g.JSONDecode,g,j)
if m and type(n)=="table"then
local q ={}
for k,v in pairs(c)do q[k]=v end
return b(q,n)
end
end
end
return c
end
function i:SaveConfig(currentConfig)
if not f()then return false end
local s,p =pcall(function()
if not isfolder(e)then makefolder(e)end
local l =g:JSONEncode(currentConfig)
writefile(d,l)
end)
return s
end
function i:GetDefaults()
return a(c)
end
function i:ResetConfig(config)
for k,v in pairs(c)do
config[k]=v
end
return config
end
function i:StartAutoSave(config,intervalSeconds)
if not f()then return end
intervalSeconds =intervalSeconds or 8
task.spawn(function()
local r =nil
while getgenv().InxiterHubLoaded do
task.wait(intervalSeconds)
if not getgenv().InxiterHubLoaded then break end
if config.AutoSave then
local o,t =pcall(g.JSONEncode,g,config)
if o and t ~=r then
if self:SaveConfig(config)then
r =t
end
end
end
end
end)
end
return i
-- [Core/Utils.lua]
local m ={}
m._connections ={}
local j =game:GetService("Players")
local k =game:GetService("TeleportService")
local n =game:GetService("VirtualUser")
local g =game:GetService("GuiService")
local h =game:GetService("Lighting")
local i =j.LocalPlayer
local l ={"ZERO","UM","DOIS","TRÊS","QUATRO","CINCO","SEIS","SETE","OITO","NOVE"}
local f ={"DEZ","ONZE","DOZE","TREZE","QUATORZE","QUINZE","DEZESSEIS","DEZESSETE","DEZOITO","DEZENOVE"}
local e ={"","","VINTE","TRINTA","QUARENTA","CINQUENTA","SESSENTA","SETENTA","OITENTA","NOVENTA"}
local b ={"","CENTO","DUZENTOS","TREZENTOS","QUATROCENTOS","QUINHENTOS","SEISCENTOS","SETECENTOS","OITOCENTOS","NOVECENTOS"}
function m:NumberToText(n)
n =math.floor(tonumber(n)or 0)
if n ==0 then return l[1]end
if n >9999 then return tostring(n)end
local function s(num)
if num ==0 then return ""end
if num ==100 then return "CEM"end
local t ={}
local o =math.floor(num /100)
local w =num %100
if o >0 then table.insert(t,b[o +1])end
if w >0 then
if w >=10 and w <=19 then
table.insert(t,f[w -9])
else
local p =math.floor(w /10)
local ab =w %10
if p >=2 then table.insert(t,e[p +1])end
if ab >0 then table.insert(t,l[ab +1])end
end
end
return table.concat(t," E ")
end
if n >=1000 then
local r =math.floor(n /1000)
local w =n %1000
local aa =(r ==1)and "MIL"or (s(r).." MIL")
if w >0 then
local y =(w <100 or w %100 ==0)and " E "or " "
return aa ..y ..s(w)
end
return aa
end
return s(n)
end
function m:AntiAFK()
if self._connections["AntiAFK"]then return end
self._connections["AntiAFK"]=i.Idled:Connect(function()
n:CaptureController()
n:ClickButton2(Vector2.new())
end)
end
function m:AutoRejoin(Config)
if self._connections["AutoRejoin"]then self._connections["AutoRejoin"]:Disconnect()end
self._connections["AutoRejoin"]=g.ErrorMessageChanged:Connect(function()
if Config.AutoRejoin then
task.wait(5)
self:Rejoin()
end
end)
end
function m:Rejoin()
if #j:GetPlayers()<=1 then
k:Teleport(game.PlaceId,i)
else
k:TeleportToPlaceInstance(game.PlaceId,game.JobId,i)
end
end
function m:ServerHop()
local a ="https://games.roblox.com/v1/games/"..game.PlaceId .."/servers/Public?sortOrder=Desc&limit=100"
local z,x =pcall(function()
local v =game:HttpGet(a)
local q =game:GetService("HttpService"):JSONDecode(v)
for _,s in pairs(q.data)do
if s.playing <s.maxPlayers and s.id ~=game.JobId then
k:TeleportToPlaceInstance(game.PlaceId,s.id,i)
return
end
end
end)
if not z then k:Teleport(game.PlaceId,i)end
end
function m:AntiLag()
settings().Rendering.QualityLevel =1
h.GlobalShadows =false
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
function m:StopAll()
for _,o in pairs(self._connections)do o:Disconnect()end
self._connections ={}
end
return m
-- [Features/Aimbot.lua]
local a ={}
local k =game:GetService("Players")
local l =game:GetService("RunService")
local m =game:GetService("UserInputService")
local n =game:GetService("Workspace")
local h =k.LocalPlayer
local x ={}
local function g()
local v =pcall(function()
local j =require(h.PlayerScripts:WaitForChild("PlayerModule"))
j:GetControls():Enable()
end)
return v
end
a.Settings ={
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
local i =nil
do
local v,r =pcall(function()
local p =Drawing.new("Circle")
p.Color =Color3.fromRGB(255,60,60)
p.Thickness =2
p.Radius =10
p.Filled =false
p.NumSides =3
p.Visible =false
return p
end)
if v then i =r end
end
local d =nil
do
local v,r =pcall(function()
local p =Drawing.new("Circle")
p.Color =Color3.new(1,1,1)
p.Thickness =1
p.Filled =false
return p
end)
if v then d =r end
end
local function f(z,camera)
local y =RaycastParams.new()
y.FilterDescendantsInstances ={h.Character,camera}
y.FilterType =Enum.RaycastFilterType.Exclude
local ab =n:Raycast(camera.CFrame.Position,z.Position -camera.CFrame.Position,y)
return ab ==nil
end
local function e(camera)
local ae =nil
local o =nil
local q =Vector2.new(camera.ViewportSize.X/2,camera.ViewportSize.Y/2)
for _,p in pairs(k:GetPlayers())do
if p ~=h and p.Character and p.Character:FindFirstChild(a.Settings.TargetPart)then
if a.Settings.TeamCheck and p.Team ==h.Team then continue end
local z =p.Character[a.Settings.TargetPart]
local aa,w =camera:WorldToViewportPoint(z.Position)
if w then
local s =(Vector2.new(aa.X,aa.Y)-q).Magnitude
if s <a.Settings.FOVRadius then
if a.Settings.WallCheck and not f(z,camera)then continue end
local ad =s
if a.Settings.Priority =="LowHealth"then
local t =p.Character:FindFirstChildOfClass("Humanoid")
ad =t and t.Health or math.huge
end
if not o or ad <o then
o =ad
ae =z
end
end
end
end
end
return ae
end
local ag =false
a.IsAiming =false 
a.LockedTarget =nil 
a._conn =l.RenderStepped:Connect(function(dt)
local b =n.CurrentCamera
if not b then return end
if d then
d.Visible =a.Settings.ShowFOV
d.Radius =a.Settings.FOVRadius
d.Position =Vector2.new(b.ViewportSize.X/2,b.ViewportSize.Y/2)
end
if a.Settings.HitboxExpander then
for _,p in pairs(k:GetPlayers())do
if p ~=h and p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local ac =p.Character.HumanoidRootPart
if not x[p]then
x[p]=ac.Size
end
ac.Size =Vector3.new(a.Settings.HitboxSize,a.Settings.HitboxSize,a.Settings.HitboxSize)
ac.Transparency =0.7
ac.CanCollide =false
end
end
elseif next(x)then
for p,origSize in pairs(x)do
pcall(function()
if p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local ac =p.Character.HumanoidRootPart
ac.Size =origSize
ac.Transparency =0
ac.CanCollide =true
end
end)
end
x ={}
end
if a.Settings.Enabled then
local u =not a.Settings.AimKeyOnly or m:IsKeyDown(a.Settings.AimKey)
local ae =u and e(b)or nil
a.LockedTarget =ae
if ae and a.Settings.SilentAim then
if b.CameraType ~=Enum.CameraType.Custom then
b.CameraType =Enum.CameraType.Custom
end
ag =false
a.IsAiming =true
if i then
local aa,w =b:WorldToViewportPoint(ae.Position)
i.Visible =w
i.Position =Vector2.new(aa.X,aa.Y)
end
elseif ae then
if i then i.Visible =false end
if b.CameraType ~=Enum.CameraType.Scriptable then
b.CameraType =Enum.CameraType.Scriptable
g()
end
ag =true
a.IsAiming =true
local af =CFrame.new(b.CFrame.Position,ae.Position)
b.CFrame =b.CFrame:Lerp(af,a.Settings.Smoothness *(dt *60))
else
if i then i.Visible =false end
if ag then
b.CameraType =Enum.CameraType.Custom
ag =false
end
a.IsAiming =false
end
else
if i then i.Visible =false end
a.LockedTarget =nil
if ag then
b.CameraType =Enum.CameraType.Custom
ag =false
end
a.IsAiming =false
end
end)
function a:Unload()
self.Settings.Enabled =false
self.Settings.HitboxExpander =false
self.IsAiming =false
self.LockedTarget =nil
for p,origSize in pairs(x)do
pcall(function()
if p.Character and p.Character:FindFirstChild("HumanoidRootPart")then
local ac =p.Character.HumanoidRootPart
ac.Size =origSize
ac.Transparency =0
ac.CanCollide =true
end
end)
end
x ={}
if self._conn then self._conn:Disconnect()self._conn =nil end
local b =n.CurrentCamera
if b then b.CameraType =Enum.CameraType.Custom end
if d then d:Remove()end
if i then i:Remove()end
end
return a
-- [Features/AutoTrain.lua]
local a ={}
local c =game:GetService("Players")
local f =game:GetService("TextChatService")
local b =c.LocalPlayer
local x =false
pcall(function()
x =f.ChatVersion ==Enum.ChatVersion.TextChatService
end)
local function e(message)
if x then
local q =pcall(function()
local h =f.TextChannels:FindFirstChild("RBXGeneral")
if h then
h:SendAsync(message)
end
end)
if q then return true end
end
local q =pcall(function()
game:GetService("ReplicatedStorage")
.DefaultChatSystemChatEvents
.SayMessageRequest:FireServer(message,"All")
end)
return q
end
local y =game:GetService("VirtualInputManager")
local function d(key,holdTime)
y:SendKeyEvent(true,key,false,game)
task.wait(holdTime or 0.05)
y:SendKeyEvent(false,key,false,game)
end
function a:Toggle(Config,State,Hub,updateUI)
self._state =State
if State.IsRunning then 
State.IsRunning =false 
if updateUI then updateUI("STATUS: PAUSADO")end
return 
end
State.IsRunning =true
task.spawn(function()
local q,j =pcall(function()
local v =Config.IsCountdown and -1 or 1
local l =Config.IsCountdown 
and (Config.StartNum -Config.Quantity)
or (Config.StartNum +Config.Quantity)
local i =0
for i =Config.StartNum,l,v do
if not State.IsRunning or not State.IsActive then break end
local o =Config.Mode or "Canguru"
if updateUI then updateUI(o .." — Contagem: "..tostring(i))end
local p =(Hub.Core.Utils and Hub.Core.Utils:NumberToText(i))or tostring(i)
local s =e(p .." !")
if not s then
warn("⚠️ [1NXITER] AutoTrain: falha ao enviar no chat — verifique se o chat está disponível")
end
if b.Character and b.Character:FindFirstChild("Humanoid")then
local n =b.Character.Humanoid
local m =b.Character:FindFirstChild("HumanoidRootPart")
if o =="Canguru"then
if Config.AutoCrouch then
d(Enum.KeyCode.C)
task.wait(0.4)
d(Enum.KeyCode.C)
task.wait(0.2)
end
n:ChangeState(Enum.HumanoidStateType.Jumping)
if m then
local k =math.random(2,6)
if math.random()>0.5 then k =-k end
local w =360 -i +k
i =k
task.spawn(function()
local t =12
local u =0.4 /t
local g =w /t
local r =n.AutoRotate
n.AutoRotate =false
for j =1,t do
if m then
m.CFrame =m.CFrame *CFrame.Angles(0,math.rad(g),0)
end
task.wait(u)
end
n.AutoRotate =r
end)
end
elseif o =="Flexão"then
elseif o =="Polichinelo"then
end
end
task.wait(Config.Delay or 1.4)
end
end)
if not q then
warn("❌ [1NXITER] AutoTrain: erro na rotina -> "..tostring(j))
if updateUI then updateUI("STATUS: ERRO (veja o console F9)")end
else
if updateUI then updateUI("STATUS: CONCLUÍDO ✅")end
end
State.IsRunning =false
end)
end
function a:Unload()
if self._state then
self._state.IsRunning =false
self._state.IsActive =false
end
end
return a
-- [Features/ESP.lua]
local b ={}
local f =game:GetService("Players")
local g =game:GetService("RunService")
local k =game:GetService("Workspace")
local e =f.LocalPlayer
b.Settings ={
Enabled =false,
TeamCheck =false,
Color =Color3.fromRGB(255,40,40),
FillTransparency =0.6,
Tracers =false,
Distance =false
}
b._connections ={}
local function i(player,n)
if not n then return end
local r =n:FindFirstChild("InxiterChams")
local ac =b.Settings.Enabled
and player ~=e
and not (b.Settings.TeamCheck and player.Team ==e.Team)
if not ac then
if r then r:Destroy()end
return
end
if not r then
r =Instance.new("Highlight")
r.Name ="InxiterChams"
r.DepthMode =Enum.HighlightDepthMode.AlwaysOnTop
r.Parent =n
end
r.FillColor =b.Settings.Color
r.OutlineColor =b.Settings.Color
r.FillTransparency =b.Settings.FillTransparency
r.OutlineTransparency =0
end
local function h()
for _,player in pairs(f:GetPlayers())do
i(player,player.Character)
end
end
local q ={}
local function a(player)
local o =q[player]
if not o then return end
if o.Line then pcall(function()o.Line:Remove()end)end
if o.Text then pcall(function()o.Text:Remove()end)end
q[player]=nil
end
local function c(player)
local o =q[player]
if o then return o end
local w,v =pcall(function()
local u =Drawing.new("Line")
u.Thickness =1
u.Visible =false
return u
end)
local x,ae =pcall(function()
local ad =Drawing.new("Text")
ad.Size =13
ad.Center =true
ad.Outline =true
ad.Color =Color3.new(1,1,1)
ad.Visible =false
return ad
end)
o ={Line =w and v or nil,Text =x and ae or nil }
q[player]=o
return o
end
local function j()
if not (b.Settings.Tracers or b.Settings.Distance)then return end
local m =k.CurrentCamera
if not m then return end
local ab =Vector2.new(m.ViewportSize.X /2,m.ViewportSize.Y)
for _,player in pairs(f:GetPlayers())do
if player ~=e then
local n =player.Character
local aa =n and n:FindFirstChild("HumanoidRootPart")
local ac =b.Settings.Enabled and aa
and not (b.Settings.TeamCheck and player.Team ==e.Team)
if ac then
local z,y =m:WorldToViewportPoint(aa.Position)
local o =c(player)
if y then
if o.Line then
o.Line.Visible =b.Settings.Tracers
o.Line.From =ab
o.Line.To =Vector2.new(z.X,z.Y)
o.Line.Color =b.Settings.Color
end
if o.Text then
local p =(m.CFrame.Position -aa.Position).Magnitude
o.Text.Visible =b.Settings.Distance
o.Text.Position =Vector2.new(z.X,z.Y -16)
o.Text.Text =math.floor(p).."m"
end
else
if o.Line then o.Line.Visible =false end
if o.Text then o.Text.Visible =false end
end
elseif q[player]then
a(player)
end
end
end
end
local function d(player)
table.insert(b._connections,player.CharacterAdded:Connect(function(n)
task.wait()
i(player,n)
end))
i(player,player.Character)
end
function b:Toggle(state)
b.Settings.Enabled =state
if state then
if #b._connections >0 then
for _,c in pairs(b._connections)do c:Disconnect()end
b._connections ={}
end
for _,player in pairs(f:GetPlayers())do d(player)end
table.insert(b._connections,f.PlayerAdded:Connect(d))
table.insert(b._connections,g.RenderStepped:Connect(j))
table.insert(b._connections,f.PlayerRemoving:Connect(a))
else
for _,c in pairs(b._connections)do c:Disconnect()end
b._connections ={}
for _,player in pairs(f:GetPlayers())do
local n =player.Character
if n then
local s =n:FindFirstChild("InxiterChams")
if s then s:Destroy()end
end
a(player)
end
end
end
function b:Refresh()
if b.Settings.Enabled then h()end
end
function b:Unload()
self:Toggle(false)
end
return b
-- [Features/FreeCam.lua]
local c ={}
local k =game:GetService("RunService")
local m =game:GetService("UserInputService")
local i =game:GetService("Players")
local e =i.LocalPlayer
c.Settings ={Enabled =false,Speed =1,Sensitivity =0.5 }
local b =nil
local f =nil
local l =nil 
local j =Vector2.new(0,0)
local g =math.rad(89)
local function d()
pcall(function()
local h =require(e.PlayerScripts:WaitForChild("PlayerModule"))
h:GetControls():Enable()
end)
end
local s =Vector2.new(0,0)
local p =nil
function c:Toggle(state)
self.Settings.Enabled =state
local a =workspace.CurrentCamera
if not a then return end
if state then
a.CameraType =Enum.CameraType.Scriptable
d()
j =Vector2.new(0,0)
s =Vector2.new(0,0)
p =nil
f =m.InputChanged:Connect(function(input)
if input.UserInputType ==Enum.UserInputType.Touch then
if p then
s =Vector2.new(input.Position.X,input.Position.Y)-p
end
p =Vector2.new(input.Position.X,input.Position.Y)
end
end)
l =m.TouchEnded:Connect(function()
p =nil
end)
b =k.RenderStepped:Connect(function(dt)
local n =workspace.CurrentCamera 
if not n then return end
local o =m:GetMouseDelta()
if o.Magnitude ==0 then
o =s
s =Vector2.new(0,0)
end
j =j +(o *-0.005 *self.Settings.Sensitivity)
j =Vector2.new(j.X,math.clamp(j.Y,-g,g))
n.CFrame =CFrame.new(n.CFrame.Position)*CFrame.Angles(0,j.X,0)*CFrame.Angles(j.Y,0,0)
local q =Vector3.new()
if m:IsKeyDown(Enum.KeyCode.W)then q =q +Vector3.new(0,0,-1)end
if m:IsKeyDown(Enum.KeyCode.S)then q =q +Vector3.new(0,0,1)end
if m:IsKeyDown(Enum.KeyCode.A)then q =q +Vector3.new(-1,0,0)end
if m:IsKeyDown(Enum.KeyCode.D)then q =q +Vector3.new(1,0,0)end
local r =m:IsKeyDown(Enum.KeyCode.LeftShift)and 4 or 1
if q.Magnitude >0 then
n.CFrame =n.CFrame +n.CFrame:VectorToWorldSpace(q.Unit *self.Settings.Speed *r)
end
end)
else
if b then b:Disconnect()b =nil end
if f then f:Disconnect()f =nil end
if l then l:Disconnect()l =nil end
a.CameraType =Enum.CameraType.Custom
end
end
function c:Unload()
self:Toggle(false)
end
return c
-- [Features/PlayerMods.lua]
local e ={}
local i =game:GetService("RunService")
local j =game:GetService("UserInputService")
local f =game:GetService("Players")
local d =f.LocalPlayer
e.Settings ={
SpeedEnabled =false,SpeedValue =50,
JumpEnabled =false,JumpValue =100,
Noclip =false,InfJump =false,
Fly =false,FlySpeed =50,
AntiVoid =false
}
local k =-500 
local b =nil
local o =0 
local q =nil
local function c()
return d.Character and d.Character:FindFirstChildOfClass("Humanoid")
end
local l ={}
local function g(m)
l ={}
if not m then return end
for _,part in pairs(m:GetDescendants())do
if part:IsA("BasePart")then table.insert(l,part)end
end
end
local function h()
for _,part in pairs(l)do
if part and part.Parent then part.CanCollide =true end
end
end
local a ={}
if d.Character then g(d.Character)end
local n =nil
table.insert(a,d.CharacterAdded:Connect(function(m)
g(m)
if n then n:Disconnect()end
n =m.DescendantAdded:Connect(function(desc)
if desc:IsA("BasePart")then
table.insert(l,desc)
if e.Settings.Noclip then desc.CanCollide =false end
end
end)
end))
table.insert(a,i.RenderStepped:Connect(function()
local m =d.Character
local p =c()
local s =m and m:FindFirstChild("HumanoidRootPart")
if p then
if e.Settings.SpeedEnabled then p.WalkSpeed =e.Settings.SpeedValue end
if e.Settings.JumpEnabled then 
p.UseJumpPower =true
p.JumpPower =e.Settings.JumpValue 
end
end
if e.Settings.Fly and s and b then
local r =p and p.MoveDirection or Vector3.new()
local t =0
if j:IsKeyDown(Enum.KeyCode.Space)then
t =1
elseif j:IsKeyDown(Enum.KeyCode.LeftControl)then
t =-1
elseif tick()<o then
t =1
end
b.Velocity =(r *e.Settings.FlySpeed)+Vector3.new(0,t *e.Settings.FlySpeed,0)
end
if e.Settings.AntiVoid and s then
if p and p.FloorMaterial ~=Enum.Material.Air and s.Position.Y >k then
q =s.CFrame
elseif s.Position.Y <k and q then
s.CFrame =q
end
end
end))
table.insert(a,i.Stepped:Connect(function()
if e.Settings.Noclip then
for _,part in pairs(l)do
if part and part.Parent then part.CanCollide =false end
end
end
end))
table.insert(a,j.JumpRequest:Connect(function()
if e.Settings.InfJump then
local p =c()
if p then p:ChangeState(Enum.HumanoidStateType.Jumping)end
end
if e.Settings.Fly then
o =tick()+0.35
end
end))
function e:ToggleSpeed(v)self.Settings.SpeedEnabled =v end
function e:ToggleJumpPower(v)self.Settings.JumpEnabled =v end
function e:ToggleNoclip(v)
self.Settings.Noclip =v
if not v then h()end
end
function e:ToggleInfJump(v)self.Settings.InfJump =v end
function e:ToggleFly(v)
self.Settings.Fly =v
local m =d.Character
local p =m and m:FindFirstChildOfClass("Humanoid")
local s =m and m:FindFirstChild("HumanoidRootPart")
if v then
if not s then self.Settings.Fly =false return end
if not b then
b =Instance.new("BodyVelocity")
b.Name ="InxiterFly"
b.MaxForce =Vector3.new(1e9,1e9,1e9)
end
b.Velocity =Vector3.new()
b.Parent =s
if p then p.PlatformStand =true end
else
if b then b.Parent =nil end
if p then p.PlatformStand =false end
end
end
function e:ToggleAntiVoid(v)
self.Settings.AntiVoid =v
q =nil
end
function e:DisableAll()
self.Settings.SpeedEnabled =false
self.Settings.JumpEnabled =false
self.Settings.Noclip =false
self.Settings.InfJump =false
self.Settings.Fly =false
self.Settings.AntiVoid =false
h()
if b then b.Parent =nil end
local p =c()
if p then
p.WalkSpeed =16
p.JumpPower =50
p.PlatformStand =false
end
end
function e:Unload()
self:DisableAll()
for _,c in pairs(a)do c:Disconnect()end
a ={}
if n then n:Disconnect()n =nil end
if b then b:Destroy()b =nil end
end
return e
-- [Features/SpyChat.lua]
local f ={}
local e =game:GetService("Players")
local h =game:GetService("UserInputService")
local a =game:GetService("CoreGui")
local g =game:GetService("TextChatService")
f.Enabled =false
f.Gui =nil
f.Minimized =false
f.Connections ={}
local function d(frame,handle)
local p,o,z
local l ={}
table.insert(l,handle.InputBegan:Connect(function(input)
if input.UserInputType ==Enum.UserInputType.MouseButton1 or input.UserInputType ==Enum.UserInputType.Touch then
p =true;o =input.Position;z =frame.Position
local j
j =input.Changed:Connect(function()
if input.UserInputState ==Enum.UserInputState.End then
p =false
if j then j:Disconnect()end
end
end)
table.insert(l,j)
end
end))
table.insert(l,h.InputChanged:Connect(function(input)
if p and (input.UserInputType ==Enum.UserInputType.MouseMovement or input.UserInputType ==Enum.UserInputType.Touch)then
local n =input.Position -o
frame.Position =UDim2.new(z.X.Scale,z.X.Offset +n.X,z.Y.Scale,z.Y.Offset +n.Y)
end
end))
return l
end
local function b(s)
s =tostring(s)
s =s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;"):gsub("\"","&quot;")
return s
end
function f:LogMessage(pName,msg)
if not self.Gui or not self.Enabled then return end
local w =self.Gui.Main.Content.Scroll
local r =Instance.new("TextLabel")
r.Name =pName 
r.Parent =w
r.Size =UDim2.new(1,-10,0,20)
r.BackgroundTransparency =1
r.RichText =true
r.TextXAlignment =Enum.TextXAlignment.Left
r.Font =Enum.Font.Code
r.TextSize =14
r.TextColor3 =Color3.new(1,1,1)
r.Text =string.format(
"<font color='#AAAAAA'>[%s]</font> <font color='#00E5FF'><b>%s:</b></font> %s",
os.date("%X"),b(pName),b(msg)
)
r.AutomaticSize =Enum.AutomaticSize.Y
r.TextWrapped =true
end
function f:Filter(text)
local w =self.Gui.Main.Content.Scroll
local v =text:lower()
for _,child in pairs(w:GetChildren())do
if child:IsA("TextLabel")then
child.Visible =child.Name:lower():find(v)and true or false
end
end
end
function f:Toggle(state)
self.Enabled =state
if state then
local y =Instance.new("ScreenGui",a);y.Name ="InxiterSpyHUD"
self.Gui =y
local t =Instance.new("Frame",y)
t.Name ="Main"
t.Size =UDim2.new(0,400,0,250)
t.Position =UDim2.new(0.5,-200,0.5,-125)
t.BackgroundColor3 =Color3.fromRGB(15,15,15)
t.BackgroundTransparency =0.1
t.BorderSizePixel =0
local ab =Instance.new("Frame",t)
ab.Name ="Top"
ab.Size =UDim2.new(1,0,0,30)
ab.BackgroundColor3 =Color3.fromRGB(10,10,10)
ab.BorderSizePixel =0
for _,i in pairs(d(t,ab))do
if i then table.insert(self.Connections,i)end
end
local aa =Instance.new("TextLabel",ab)
aa.Text ="  CHAT LOGS (HD ADMIN STYLE)"
aa.Size =UDim2.new(1,-80,1,0)
aa.BackgroundTransparency =1
aa.TextColor3 =Color3.new(1,1,1)
aa.Font =Enum.Font.GothamBold
aa.TextSize =12
aa.TextXAlignment =Enum.TextXAlignment.Left
local k =Instance.new("TextButton",ab)
k.Text ="X";k.Size =UDim2.new(0,30,1,0);k.Position =UDim2.new(1,-30,0,0)
k.BackgroundColor3 =Color3.fromRGB(150,0,0);k.TextColor3 =Color3.new(1,1,1)
k.MouseButton1Click:Connect(function()self:Toggle(false)end)
local u =Instance.new("TextButton",ab)
u.Text ="-";u.Size =UDim2.new(0,30,1,0);u.Position =UDim2.new(1,-60,0,0)
u.BackgroundColor3 =Color3.fromRGB(40,40,40);u.TextColor3 =Color3.new(1,1,1)
u.MouseButton1Click:Connect(function()
self.Minimized =not self.Minimized
t.Content.Visible =not self.Minimized
t.Size =self.Minimized and UDim2.new(0,400,0,30)or UDim2.new(0,400,0,250)
end)
local m =Instance.new("Frame",t)
m.Name ="Content"
m.Size =UDim2.new(1,0,1,-30)
m.Position =UDim2.new(0,0,0,30)
m.BackgroundTransparency =1
local x =Instance.new("TextBox",m)
x.PlaceholderText ="Pesquisar usuário..."
x.Size =UDim2.new(1,-20,0,25)
x.Position =UDim2.new(0,10,0,5)
x.BackgroundColor3 =Color3.fromRGB(25,25,25)
x.TextColor3 =Color3.new(1,1,1)
x.BorderSizePixel =0
x:GetPropertyChangedSignal("Text"):Connect(function()self:Filter(x.Text)end)
local w =Instance.new("ScrollingFrame",m)
w.Name ="Scroll"
w.Size =UDim2.new(1,-20,1,-45)
w.Position =UDim2.new(0,10,0,35)
w.BackgroundTransparency =1
w.CanvasSize =UDim2.new(0,0,0,0)
w.ScrollBarThickness =2
w.AutomaticCanvasSize =Enum.AutomaticSize.Y
local s =Instance.new("UIListLayout",w)
s.SortOrder =Enum.SortOrder.LayoutOrder;s.Padding =UDim.new(0,5)
local ac =g.ChatVersion ==Enum.ChatVersion.TextChatService
if not ac then
local function q(p)
local i =p.Chatted:Connect(function(m)self:LogMessage(p.Name,m)end)
table.insert(self.Connections,i)
end
for _,p in pairs(e:GetPlayers())do q(p)end
table.insert(self.Connections,e.PlayerAdded:Connect(q))
else
local i =g.MessageReceived:Connect(function(res)
if res.TextSource then self:LogMessage(res.TextSource.DisplayName,res.Text)end
end)
table.insert(self.Connections,i)
end
else
if self.Gui then self.Gui:Destroy();self.Gui =nil end
for _,i in pairs(self.Connections)do i:Disconnect()end
self.Connections ={}
end
end
function f:Unload()
self:Toggle(false)
end
return f
-- [Features/Visuals.lua]
local c ={}
local b =game:GetService("RunService")
c.Settings ={StretchedEnabled =false,FOVValue =100 }
c._conn =nil
function c:ToggleStretched(v)
self.Settings.StretchedEnabled =v
if v then
local a =workspace.CurrentCamera
if a then a.FieldOfView =self.Settings.FOVValue end
if not self._conn then
self._conn =b.RenderStepped:Connect(function()
if c.Settings.StretchedEnabled then
local d =workspace.CurrentCamera
if d then d.FieldOfView =c.Settings.FOVValue end
end
end)
end
else
if self._conn then self._conn:Disconnect()self._conn =nil end
local a =workspace.CurrentCamera
if a then a.FieldOfView =70 end
end
end
function c:UpdateFOV(v)
self.Settings.FOVValue =v
if self.Settings.StretchedEnabled then
local a =workspace.CurrentCamera
if a then a.FieldOfView =v end
end
end
function c:Unload()
self.Settings.StretchedEnabled =false
if self._conn then self._conn:Disconnect()self._conn =nil end
local a =workspace.CurrentCamera
if a then a.FieldOfView =70 end
end
return c
-- [Interface/Main.lua]
local c ={}
local function a()
if not (writefile and getcustomasset and isfile)then return nil end
local b ="https://raw.githubusercontent.com/Raphael99090/1NXXITER/main/Assets/1784776415112.png"
local p ="1nxiter_icon.png"
local q,r =pcall(function()
if not isfile(p)then
local n =game:HttpGet(b .."?cache="..math.random(1,999999))
writefile(p,n)
end
return getcustomasset(p)
end)
return q and r or nil
end
function c:Load(Hub,Config,State)
local s,k =pcall(function()
return loadstring(game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/main/dist/main.lua"))()
end)
if not s or not k then
return warn("❌ [1NXITER]: Falha ao carregar a biblioteca WindUI.")
end
pcall(function()k:SetNotificationLower(true)end)
local m =a()
local u ={
Title ="1NXITER HUB",
Author ="V3.0 · Modular SRC",
Icon =m or "house",
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
local q,l =pcall(function()return k:CreateWindow(u)end)
if not q or not l then
return warn("❌ [1NXITER]: Falha ao criar a janela WindUI -> "..tostring(l))
end
local g =game:GetService("Players")
local e =g.LocalPlayer
local j =game:GetService("UserInputService")
local function d()
pcall(function()
local f =require(e.PlayerScripts:WaitForChild("PlayerModule"))
f:GetControls():Enable()
end)
pcall(function()j.ModalEnabled =false end)
end
d()
l:OnOpen(d)
l:OnClose(d)
local i ={
Train =l:Tab({Title ="Treino",Icon ="activity"}),
Combat =l:Tab({Title ="Combate",Icon ="swords"}),
ESP =l:Tab({Title ="Visual",Icon ="eye"}),
Movement =l:Tab({Title ="Movimento",Icon ="move"}),
Camera =l:Tab({Title ="Câmera",Icon ="camera"}),
System =l:Tab({Title ="Sistema",Icon ="settings"})
}
local function h(tabName,tabObject)
local t =Hub.UI.Tabs[tabName]
if t and t.Render then
local q,o =pcall(function()
t:Render(tabObject,Hub,Config,State)
end)
if not q then warn("❌ [1NXITER]: Erro ao renderizar aba "..tabName ..": "..tostring(o))end
else
warn("⚠️ [1NXITER]: Módulo de aba não encontrado: "..tabName)
end
end
Hub.UI.Library =k
Hub.UI.Window =l
h("TrainTab",i.Train)
h("CombatTab",i.Combat)
h("ESPTab",i.ESP)
h("MovementTab",i.Movement)
h("CameraTab",i.Camera)
h("SystemTab",i.System)
i.Train:Select()
k:Notify({
Title ="1NXITER HUB",
Content ="Interface carregada com sucesso!",
Icon ="solar:bell-bold",
Duration =5
})
end
return c
-- [Interface/Tabs/CameraTab.lua]
local c ={}
function c:Render(WindowTab,Hub,Config)
local d =Hub.Features.Visuals
local a =Hub.Features.FreeCam
local b =Hub.Features.SpyChat
WindowTab:Section({Title ="Visual de Tela",Icon ="monitor"})
WindowTab:Toggle({Flag ="StretchE",Title ="Tela Esticada",Icon ="maximize-2",Value =false,Callback =function(v)d:ToggleStretched(v)end })
WindowTab:Slider({
Flag ="FOVVal",Title ="Zoom",Step =1,
Value ={Min =30,Max =120,Default =70 },
Callback =function(v)d:UpdateFOV(v)end
})
WindowTab:Section({Title ="Câmera Livre",Icon ="video"})
WindowTab:Toggle({Flag ="FreeE",Title ="Ativar FreeCam",Icon ="video",Value =false,Callback =function(v)a:Toggle(v)end })
WindowTab:Slider({
Flag ="FreeCamSpeed",Title ="Velocidade",Step =0.1,
Value ={Min =0.1,Max =10,Default =1 },
Callback =function(v)a.Settings.Speed =v end
})
WindowTab:Slider({
Flag ="FreeCamSens",Title ="Sensibilidade",Step =0.1,
Value ={Min =0.1,Max =3,Default =0.5 },
Callback =function(v)a.Settings.Sensitivity =v end
})
WindowTab:Section({Title ="Espionagem",Icon ="message-square"})
WindowTab:Toggle({Flag ="SpyE",Title ="Logs Spy Chat",Icon ="message-square-more",Value =false,Callback =function(v)b:Toggle(v)end })
end
return c
-- [Interface/Tabs/CombatTab.lua]
local c ={}
function c:Render(WindowTab,Hub,Config,State)
local a =Hub.Features.Aimbot
WindowTab:Section({
Title ="Aimbot Master",
Icon ="crosshair"
})
local b =WindowTab:Section({
Title ="Status",
Desc ="Aimbot desligado"
})
task.spawn(function()
while getgenv().InxiterHubLoaded do
if not a.Settings.Enabled then
b:SetDesc("Aimbot desligado")
elseif a.Settings.SilentAim and a.IsAiming then
b:SetDesc("🔒 Alvo travado (Silent Aim — câmera livre)")
elseif a.IsAiming then
b:SetDesc("🎯 Mirando em alvo")
else
b:SetDesc("👀 Procurando alvo...")
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
a.Settings.Enabled =v
end
})
WindowTab:Toggle({
Flag ="AimSilent",
Title ="Silent Aim (não gira a câmera)",
Icon ="target",
Value =false,
Callback =function(v)
a.Settings.SilentAim =v
end
})
WindowTab:Toggle({
Flag ="AimKeyOnly",
Title ="Só mirar segurando E",
Icon ="keyboard",
Value =false,
Callback =function(v)
a.Settings.AimKeyOnly =v
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
a.Settings.Priority =
(v =="Menor vida")and "LowHealth"or "Closest"
end
})
WindowTab:Toggle({
Flag ="AimTeam",
Title ="Ignorar Time",
Icon ="users",
Value =false,
Callback =function(v)
a.Settings.TeamCheck =v
end
})
WindowTab:Toggle({
Flag ="AimW",
Title ="Wall Check",
Icon ="scan-eye",
Value =true,
Callback =function(v)
a.Settings.WallCheck =v
end
})
WindowTab:Toggle({
Flag ="AimFOVShow",
Title ="Mostrar Círculo do FOV",
Icon ="circle-dot",
Value =false,
Callback =function(v)
a.Settings.ShowFOV =v
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
a.Settings.Smoothness =v
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
a.Settings.FOVRadius =v
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
a.Settings.HitboxExpander =v
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
a.Settings.HitboxSize =v
end
})
end
return c
-- [Interface/Tabs/ESPTab.lua]
local d ={}
function d:Render(WindowTab,Hub,Config)
local a =Hub.Features.ESP
local b =game:GetService("Players")
WindowTab:Section({Title ="Chams",Icon ="eye"})
local c =WindowTab:Section({Title ="Jogadores detectados",Desc ="ESP desligado"})
task.spawn(function()
while getgenv().InxiterHubLoaded do
if a.Settings.Enabled then
local e =math.max(0,#b:GetPlayers()-1)
c:SetDesc(tostring(e).." jogador(es) na partida")
else
c:SetDesc("ESP desligado")
end
task.wait(1)
end
end)
WindowTab:Toggle({Flag ="ESPE",Title ="Ativar Chams",Icon ="eye",Value =false,Callback =function(v)a:Toggle(v)end })
WindowTab:Toggle({
Flag ="ESPT",
Title ="Ocultar Aliados",Icon ="user-round-x",
Value =false,
Callback =function(v)
a.Settings.TeamCheck =v
a:Refresh()
end
})
WindowTab:Slider({
Flag ="ESPFill",
Title ="Transparência do Preenchimento",
Step =0.01,
Value ={Min =0,Max =1,Default =0.6 },
Callback =function(v)
a.Settings.FillTransparency =v
a:Refresh()
end
})
WindowTab:Section({Title ="Extras",Icon ="sparkles"})
WindowTab:Toggle({Flag ="ESPTracer",Title ="Tracers (linha até o jogador)",Icon ="route",Value =false,Callback =function(v)a.Settings.Tracers =v end })
WindowTab:Toggle({Flag ="ESPDist",Title ="Mostrar Distância",Icon ="ruler",Value =false,Callback =function(v)a.Settings.Distance =v end })
end
return d
-- [Interface/Tabs/MovementTab.lua]
local b ={}
function b:Render(WindowTab,Hub,Config)
local a =Hub.Features.PlayerMods
WindowTab:Section({Title ="Atributos",Icon ="gauge"})
WindowTab:Toggle({Flag ="SpeedE",Title ="Ativar Speed",Icon ="gauge",Value =false,Callback =function(v)a:ToggleSpeed(v)end })
WindowTab:Slider({
Flag ="SpeedV",Title ="Velocidade",Step =1,
Value ={Min =16,Max =500,Default =50 },
Callback =function(v)a.Settings.SpeedValue =v end
})
WindowTab:Toggle({Flag ="JumpE",Title ="Ativar Jump Power",Icon ="arrow-up",Value =false,Callback =function(v)a:ToggleJumpPower(v)end })
WindowTab:Slider({
Flag ="JumpV",Title ="Força do Pulo",Step =1,
Value ={Min =50,Max =500,Default =100 },
Callback =function(v)a.Settings.JumpValue =v end
})
WindowTab:Section({Title ="Física",Icon ="atom"})
WindowTab:Toggle({Flag ="NoclipE",Title ="Atravessar Paredes",Icon ="move-3d",Value =false,Callback =function(v)a:ToggleNoclip(v)end })
WindowTab:Toggle({Flag ="InfJumpE",Title ="Pulo Infinito",Icon ="infinity",Value =false,Callback =function(v)a:ToggleInfJump(v)end })
WindowTab:Section({Title ="Voo",Icon ="plane"})
WindowTab:Toggle({Flag ="FlyE",Title ="Ativar Fly",Icon ="plane",Value =false,Callback =function(v)a:ToggleFly(v)end })
WindowTab:Slider({
Flag ="FlyV",Title ="Velocidade do Fly",Step =1,
Value ={Min =10,Max =300,Default =50 },
Callback =function(v)a.Settings.FlySpeed =v end
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
Callback =function(v)a:ToggleAntiVoid(v)end
})
end
return b
-- [Interface/Tabs/SystemTab.lua]
local e ={}
local function c(link)
if not link or link ==""then return true end
if link:find("SEU%-")or link:find("YOUR%-")or link:find("PLACEHOLDER")then return true end
return false
end
local function a(text)
local h =setclipboard or toclipboard
if type(h)~="function"then
return false
end
local j =pcall(h,text)
return j
end
function e:Render(WindowTab,Hub,Config,State)
local f =Hub.Core.Utils
local d =Hub.Core.State
local g =Hub.UI.Library
WindowTab:Section({
Title ="Aparência",
Icon ="palette"
})
WindowTab:Dropdown({
Flag ="UITheme",
Title ="Tema",
Values =(function()
local i ={}
for name in pairs(g:GetThemes())do
table.insert(i,name)
end
table.sort(i)
return i
end)(),
Value =g:GetCurrentTheme(),
Callback =function(v)
g:SetTheme(v)
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
d:SaveConfig(Config)
g:Notify({
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
d:ResetConfig(Config)
d:SaveConfig(Config)
g:Notify({
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
f:AntiLag()
end
})
WindowTab:Button({
Title ="REJOIN",
Icon ="refresh-cw",
IconAlign ="Left",
Callback =function()
f:Rejoin()
end
})
WindowTab:Button({
Title ="SERVER HOP",
Icon ="globe",
IconAlign ="Left",
Callback =function()
f:ServerHop()
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
local b =Config.DiscordLink
if c(b)then
g:Notify({
Title ="Discord",
Content ="Configure Config.DiscordLink com o convite do servidor.",
Icon ="triangle-alert",
Duration =4
})
return
end
if a(b)then
g:Notify({
Title ="Discord",
Content ="Link copiado!",
Icon ="check",
Duration =3
})
else
g:Notify({
Title ="Discord",
Content =b,
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
return e
-- [Interface/Tabs/TrainTab.lua]
local c ={}
function c:Render(WindowTab,Hub,Config,State)
local a =Hub.Features.AutoTrain
WindowTab:Section({Title ="Controle de Treino",Icon ="dumbbell"})
local b =WindowTab:Section({Title ="Monitor",Desc ="Aguardando início..."})
WindowTab:Button({
Title ="INICIAR / PARAR TREINO",
Icon ="play",
Callback =function()
if a then
a:Toggle(Config,State,Hub,function(t)b:SetDesc(t)end)
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
return c