--// CyberDesk (Exploit Edition) — single file
--// Safe CoreGui parenting, anti-duplicate, pcall-wrapped effects, getgenv() config.
--// by SerovEX (rewritten for executors)

-- ============ CONFIG ============
local CFG = getgenv().CyberDesk or {}
CFG.Hotkey = CFG.Hotkey or Enum.KeyCode.RightShift
CFG.Title  = CFG.Title  or "CyberDesk"
CFG.Sub    = CFG.Sub    or "SerovEX • Neon UI"
CFG.ReloadOnTeleport = (CFG.ReloadOnTeleport == nil) and true or CFG.ReloadOnTeleport
-- =================================

-- Services
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Debris = game:GetService("Debris")
local SoundService = game:GetService("SoundService")

local LocalPlayer = Players.LocalPlayer

-- Utils
local function safe(fn, ...)
    local ok, res = pcall(fn, ...)
    return ok, res
end
local function mk(class, props, parent)
    local o = Instance.new(class)
    if props then for k,v in pairs(props) do o[k]=v end end
    if parent then o.Parent = parent end
    return o
end
local function tween(o, t, props, style, dir)
    return TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end
local function corner(p, r) mk("UICorner", {CornerRadius = UDim.new(0,r or 12)}, p) end
local function stroke(p, th, tr) mk("UIStroke", {Thickness = th or 1, Transparency = tr or 0.6, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p) end
local function grad(p, seq, rot) return mk("UIGradient", {Color = ColorSequence.new(seq), Rotation = rot or 0}, p) end
local function playClick()
    local s = mk("Sound", {SoundId="rbxassetid://9120299506", Volume=0.25}, SoundService)
    s:Play() ; s.Ended:Connect(function() s:Destroy() end)
end

-- Parent target (protected)
local function getGuiParent()
    local ok, ui = pcall(function()
        if syn and syn.protect_gui then
            local g = Instance.new("ScreenGui")
            syn.protect_gui(g)
            g.Parent = game:GetService("CoreGui")
            return g
        end
    end)
    if ok and ui then return ui end

    local ok2, ui2 = pcall(function()
        if gethui then
            local g = Instance.new("ScreenGui")
            g.Parent = gethui()
            return g
        end
    end)
    if ok2 and ui2 then return ui2 end

    local g = Instance.new("ScreenGui")
    g.Parent = (game:GetService("CoreGui"))
    return g
end

-- Anti-duplicate (clean previous)
do
    local CG = game:GetService("CoreGui")
    for _,v in ipairs(CG:GetChildren()) do
        if v:IsA("ScreenGui") and v.Name == "CyberDesk_ExploitGUI" then
            v:Destroy()
        end
    end
    if gethui then
        for _,v in ipairs(gethui():GetChildren()) do
            if v:IsA("ScreenGui") and v.Name == "CyberDesk_ExploitGUI" then
                v:Destroy()
            end
        end
    end
end

-- Root GUI
local gui = getGuiParent()
gui.Name = "CyberDesk_ExploitGUI"
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false

-- Shade + (safe) Blur
local shade = mk("Frame", {BackgroundColor3 = Color3.new(0,0,0), BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Visible=false}, gui)

local function setBlur(on)
    safe(function()
        local name = "CyberDesk_Exploit_Blur"
        local b = Lighting:FindFirstChild(name)
        if on then
            if not b then b = mk("BlurEffect", {Name=name, Size=0}, Lighting) end
            tween(b, 0.25, {Size=12}):Play()
        else
            if b then
                tween(b, 0.25, {Size=0}):Play()
                task.delay(0.3, function() if b then b:Destroy() end end)
            end
        end
    end)
end

-- Window
math.randomseed(tick()%1*1e7)
local root = mk("Frame", {
    Name = ("Wnd_%d"):format(math.random(10000,99999)),
    Size = UDim2.fromScale(0.42,0.52),
    Position = UDim2.fromScale(0.29,0.24),
    BackgroundColor3 = Color3.fromRGB(12,12,16),
    BackgroundTransparency = 0.15,
    BorderSizePixel = 0,
    Visible=false
}, gui)
corner(root, 18)
stroke(root, 1.2, 0.2)
grad(root, {
    ColorSequenceKeypoint.new(0, Color3.fromRGB(12,12,16)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,28)),
}, 0)

-- Neon border
local neonStroke = stroke(root, 2.2, 0.15)
local neonGrad = grad(neonStroke, {
    ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0,255,213)),
    ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,119,255)),
    ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0,255,136)),
}, 0)
task.spawn(function()
    while root.Parent do
        local tw = tween(neonGrad, 6, {Rotation = (neonGrad.Rotation + 360)%360}, Enum.EasingStyle.Linear)
        tw:Play(); tw.Completed:Wait()
    end
end)

-- Header
local header = mk("Frame", {Size = UDim2.new(1,0,0,48), BackgroundColor3 = Color3.fromRGB(14,18,24), BackgroundTransparency=0.25, BorderSizePixel=0}, root)
corner(header, 18); stroke(header, 1, 0.65)
local title = mk("TextLabel", {Text = CFG.Title, Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.fromRGB(230,244,255), BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.fromScale(0.04,0.5), Size=UDim2.fromScale(0.55,1), TextXAlignment=Enum.TextXAlignment.Left}, header)
mk("TextLabel", {Text = CFG.Sub, Font=Enum.Font.Gotham, TextSize=13, TextColor3=Color3.fromRGB(160,200,245), BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.fromScale(0.04,0.78), Size=UDim2.fromScale(0.6,0.5), TextXAlignment=Enum.TextXAlignment.Left}, header)

local btnClose = mk("TextButton", {Text="✕", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(230,230,240), BackgroundTransparency=0.8, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.fromScale(0.97,0.5), Size=UDim2.fromOffset(32,28), AutoButtonColor=false}, header) ; corner(btnClose,12)
local btnMin   = mk("TextButton", {Text="—", Font=Enum.Font.GothamBold, TextSize=16, TextColor3=Color3.fromRGB(230,230,240), BackgroundTransparency=0.8, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.fromScale(0.90,0.5), Size=UDim2.fromOffset(32,28), AutoButtonColor=false}, header) ; corner(btnMin,12)

-- Sidebar
local sidebar = mk("Frame", {Size=UDim2.new(0,160,1,-48), Position=UDim2.fromOffset(0,48), BackgroundColor3=Color3.fromRGB(10,12,18), BackgroundTransparency=0.35, BorderSizePixel=0}, root)
corner(sidebar,18); stroke(sidebar,1,0.7)
mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, Padding=UDim.new(0,8), HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Start}, sidebar)
mk("UIPadding", {PaddingTop=UDim.new(0,12)}, sidebar)

local function tabButton(t)
    local b = mk("TextButton", {Text=t, Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.fromRGB(220,235,255), AutoButtonColor=false, BackgroundColor3=Color3.fromRGB(18,22,30), BackgroundTransparency=0.15, Size=UDim2.fromOffset(136,40)}, sidebar)
    corner(b,12); stroke(b,1,0.7); return b
end
local tabHomeBtn = tabButton("Главная")
local tabToolsBtn = tabButton("Инструменты")
local tabSettingsBtn = tabButton("Настройки")

-- Content
local content = mk("Frame", {Size=UDim2.new(1,-160,1,-48), Position=UDim2.fromOffset(160,48), BackgroundTransparency=1}, root)
local function page(name) return mk("Frame", {Name=name, Size=UDim2.fromScale(1,1), BackgroundTransparency=1, Visible=false}, content) end
local pageHome, pageTools, pageSettings = page("Home"), page("Tools"), page("Settings")

local function showPage(p)
    for _,ch in ipairs(content:GetChildren()) do if ch:IsA("Frame") then ch.Visible=false end end
    p.Visible=true
end
showPage(pageHome)

-- Ripple
local function ripple(btn, pos)
    local r = mk("Frame", {AnchorPoint=Vector2.new(0.5,0.5), Position=UDim2.fromOffset(pos.X, pos.Y), Size=UDim2.fromOffset(0,0), BackgroundColor3=Color3.fromRGB(255,255,255), BackgroundTransparency=0.7, BorderSizePixel=0, ZIndex=(btn.ZIndex or 1)+1}, btn)
    corner(r, 999)
    local max = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 1.4
    tween(r, 0.35, {Size=UDim2.fromOffset(max,max), BackgroundTransparency=1}):Play()
    Debris:AddItem(r, 0.4)
end

-- Home page
do
    local card = mk("Frame", {Size=UDim2.fromScale(0.9,0.4), Position=UDim2.fromScale(0.5,0.32), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.fromRGB(15,18,26), BackgroundTransparency=0.1}, pageHome)
    corner(card,20); stroke(card,1.2,0.35)
    grad(card, {ColorSequenceKeypoint.new(0,Color3.fromRGB(18,20,30)), ColorSequenceKeypoint.new(1,Color3.fromRGB(12,12,20))}, 90)
    mk("TextLabel", {Text="Добро пожаловать!", Font=Enum.Font.GothamBlack, TextSize=26, TextColor3=Color3.fromRGB(230,245,255), BackgroundTransparency=1, Position=UDim2.fromScale(0.5,0.25), AnchorPoint=Vector2.new(0.5,0.5)}, card)
    mk("TextLabel", {
        Text="Неон-UI для эксплойтов: вкладки, тосты, слайдеры, перетаскивание.\nГорячая клавиша: "..tostring(CFG.Hotkey),
        Font=Enum.Font.Gotham, TextWrapped=true, TextSize=16, TextTransparency=0.05,
        TextColor3=Color3.fromRGB(195,215,245), BackgroundTransparency=1,
        Position=UDim2.fromScale(0.5,0.55), Size=UDim2.fromScale(0.9,0.5), AnchorPoint=Vector2.new(0.5,0.5)
    }, card)

    -- мини-частицы
    for i=1,12 do
        local d = mk("Frame", {Size=UDim2.fromOffset(math.random(3,6), math.random(3,6)), BackgroundColor3=Color3.fromRGB(0,255,200), BackgroundTransparency=0.35, BorderSizePixel=0, Position=UDim2.fromScale(math.random(), math.random()), ZIndex=(card.ZIndex or 1)+1}, card)
        corner(d, 99)
        task.spawn(function()
            while d.Parent do
                local nx, ny = math.random(), math.random()
                tween(d, math.random(6,10)/10, {Position=UDim2.fromScale(nx,ny), BackgroundTransparency=math.random()*0.6+0.2}, Enum.EasingStyle.Sine):Play()
                task.wait(math.random(8,14)/10)
            end
        end)
    end
end

-- Toasts
local toastHolder = mk("Frame", {Size=UDim2.fromScale(0.38,1), Position=UDim2.fromScale(0.99,0.98), AnchorPoint=Vector2.new(1,1), BackgroundTransparency=1}, pageTools)
mk("UIListLayout", {FillDirection=Enum.FillDirection.Vertical, HorizontalAlignment=Enum.HorizontalAlignment.Right, VerticalAlignment=Enum.VerticalAlignment.Bottom, Padding=UDim.new(0,6)}, toastHolder)
local function toast(text, dur)
    local box = mk("Frame", {Size=UDim2.fromOffset(0,60), BackgroundColor3=Color3.fromRGB(14,18,26), BackgroundTransparency=0.1}, toastHolder)
    corner(box,12); stroke(box,1,0.5)
    mk("TextLabel", {Text=text, Font=Enum.Font.Gotham, TextSize=15, TextWrapped=true, TextColor3=Color3.fromRGB(220,235,255), BackgroundTransparency=1, Size=UDim2.fromScale(1,1)}, box)
    tween(box, 0.25, {Size=UDim2.fromOffset(320,60)}):Play()
    task.delay(dur or 2.5, function()
        if box then local tw=tween(box,0.25,{BackgroundTransparency=1, Size=UDim2.fromOffset(0,60)}); tw:Play(); tw.Completed:Wait(); if box then box:Destroy() end end
    end)
end

-- Tools card + controls
local toolsCard = mk("Frame", {Size=UDim2.fromScale(0.9,0.75), Position=UDim2.fromScale(0.5,0.52), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.fromRGB(15,18,26), BackgroundTransparency=0.08}, pageTools)
corner(toolsCard,18); stroke(toolsCard,1.1,0.45)
mk("UIListLayout", {Padding=UDim.new(0,10), HorizontalAlignment=Enum.HorizontalAlignment.Center, VerticalAlignment=Enum.VerticalAlignment.Top}, toolsCard)
mk("UIPadding", {PaddingTop=UDim.new(0,16)}, toolsCard)

local function button(text)
    local b = mk("TextButton", {Text=text, Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.fromRGB(225,235,255), AutoButtonColor=false, Size=UDim2.fromOffset(420,44), BackgroundColor3=Color3.fromRGB(20,24,34), BackgroundTransparency=0.05}, toolsCard)
    corner(b,10); stroke(b,1,0.6)
    b.MouseButton1Down:Connect(function(x,y) ripple(b, Vector2.new(x - b.AbsolutePosition.X, y - b.AbsolutePosition.Y)); playClick() end)
    return b
end

local btnToast = button("Показать тост")
btnToast.Activated:Connect(function() toast("Это демо уведомление ✨", 2.5) end)

local function toggle(text, default)
    local holder = mk("Frame", {Size=UDim2.fromOffset(420,44), BackgroundTransparency=1}, toolsCard)
    mk("TextLabel", {Text=text, Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.fromRGB(210,225,245), BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0.5), Position=UDim2.fromScale(0,0.5), Size=UDim2.fromScale(0.7,1), TextXAlignment=Enum.TextXAlignment.Left}, holder)
    local sw = mk("TextButton", {AutoButtonColor=false, AnchorPoint=Vector2.new(1,0.5), Position=UDim2.fromScale(1,0.5), Size=UDim2.fromOffset(64,28), BackgroundColor3=Color3.fromRGB(28,34,46), Text=""}, holder)
    corner(sw,14); stroke(sw,1,0.6)
    local dot = mk("Frame", {Size=UDim2.fromOffset(24,24), Position=UDim2.fromOffset(default and 38 or 4,2), BackgroundColor3= default and Color3.fromRGB(0,210,255) or Color3.fromRGB(90,98,112)}, sw)
    corner(dot,12)
    local state = default
    local function setState(on)
        state = on
        tween(dot, 0.18, {Position=UDim2.fromOffset(on and 38 or 4,2), BackgroundColor3= on and Color3.fromRGB(0,210,255) or Color3.fromRGB(90,98,112)}):Play()
    end
    setState(default)
    sw.Activated:Connect(function() playClick(); setState(not state); toast((state and "Включено: " or "Выключено: ")..text, 1.4) end)
    return {Get=function() return state end, Set=setState}
end
local tgPulse = toggle("Пульс рамки", true)

local function slider(text, default)
    local holder = mk("Frame", {Size=UDim2.fromOffset(420,70), BackgroundTransparency=1}, toolsCard)
    local label = mk("TextLabel", {Text=text.." ("..default..")", Font=Enum.Font.GothamMedium, TextSize=16, TextColor3=Color3.fromRGB(210,225,245), BackgroundTransparency=1, AnchorPoint=Vector2.new(0,0), Position=UDim2.fromOffset(0,0), Size=UDim2.fromOffset(420,24), TextXAlignment=Enum.TextXAlignment.Left}, holder)
    local bar = mk("Frame", {Size=UDim2.fromOffset(420,10), Position=UDim2.fromOffset(0,34), BackgroundColor3=Color3.fromRGB(26,32,45)}, holder)
    corner(bar,6); stroke(bar,1,0.7)
    local fill = mk("Frame", {Size=UDim2.fromScale(default/100,1), BackgroundColor3=Color3.fromRGB(0,200,255)}, bar) ; corner(fill,6)
    local knob = mk("ImageButton", {Size=UDim2.fromOffset(18,18), Position=UDim2.fromOffset(math.floor(bar.AbsoluteSize.X*(default/100)-9), -4), BackgroundTransparency=1, Image="rbxassetid://7072724538"}, bar)
    local val, dragging = default, false
    local function setValue(v) val = math.clamp(math.floor(v+0.5),0,100); label.Text = text.." ("..val..")"; fill.Size = UDim2.fromScale(val/100,1) end
    setValue(default)
    local function update(px) local rel=(px - bar.AbsolutePosition.X)/bar.AbsoluteSize.X; setValue(rel*100) end
    knob.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=true; playClick() end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dragging=false end end)
    UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then update(i.Position.X) end end)
    bar.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then update(i.Position.X) end end)
    return {Get=function() return val end, Set=setValue}
end
local slGlow = slider("Яркость подсветки", 60)

local btnApply = button("Применить подсветку")
btnApply.Activated:Connect(function()
    playClick()
    local brightness = slGlow.Get()/100
    neonStroke.Transparency = 0.25 + (1 - brightness) * 0.6
    toast(("Подсветка: %d%%"):format(slGlow.Get()), 2)
end)

-- Pulse loop (safe)
task.spawn(function()
    while root.Parent do
        if tgPulse.Get() then
            local t1 = tween(neonStroke, 0.85, {Thickness=2.8}); t1:Play(); t1.Completed:Wait()
            local t2 = tween(neonStroke, 0.85, {Thickness=1.8}); t2:Play(); t2.Completed:Wait()
        else task.wait(0.2) end
    end
end)

-- Settings page
do
    local box = mk("Frame", {Size=UDim2.fromScale(0.9,0.6), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5), BackgroundColor3=Color3.fromRGB(15,18,26), BackgroundTransparency=0.08}, pageSettings)
    corner(box,16); stroke(box,1.1,0.45)
    mk("TextLabel", {Text="Настройки UI", Font=Enum.Font.GothamBold, TextSize=20, TextColor3=Color3.fromRGB(230,245,255), BackgroundTransparency=1, Position=UDim2.fromOffset(16,10), Size=UDim2.fromOffset(300,26), TextXAlignment=Enum.TextXAlignment.Left}, box)
    mk("TextLabel", {Text="Горячая клавиша: "..tostring(CFG.Hotkey).." (см. CFG.Hotkey через getgenv())", Font=Enum.Font.Gotham, TextSize=16, TextColor3=Color3.fromRGB(200,215,235), BackgroundTransparency=1, Position=UDim2.fromOffset(16,44), Size=UDim2.fromOffset(560,24), TextXAlignment=Enum.TextXAlignment.Left}, box)
    mk("TextLabel", {Text="Кнопка Unload закроет UI и очистит эффекты.", Font=Enum.Font.Gotham, TextSize=16, TextColor3=Color3.fromRGB(200,215,235), BackgroundTransparency=1, Position=UDim2.fromOffset(16,74), Size=UDim2.fromOffset(560,24), TextXAlignment=Enum.TextXAlignment.Left}, box)
    local unload = button("Unload (закрыть и удалить GUI)")
    unload.Parent = box
    unload.Size = UDim2.fromOffset(300,40)
    unload.Position = UDim2.fromOffset(16,110)
    unload.Activated:Connect(function()
        playClick()
        setBlur(false)
        if gui then gui:Destroy() end
    end)
end

-- Tabs logic
local function selectTab(btn, page)
    playClick()
    for _,b in ipairs({tabHomeBtn, tabToolsBtn, tabSettingsBtn}) do
        tween(b, 0.12, {BackgroundTransparency = (b==btn) and 0 or 0.15}):Play()
    end
    showPage(page)
end
tabHomeBtn.Activated:Connect(function() selectTab(tabHomeBtn, pageHome) end)
tabToolsBtn.Activated:Connect(function() selectTab(tabToolsBtn, pageTools) end)
tabSettingsBtn.Activated:Connect(function() selectTab(tabSettingsBtn, pageSettings) end)
tabHomeBtn.BackgroundTransparency = 0

-- Drag
do
    local dragging, dragStart, startPos = false, nil, nil
    local function begin(input) dragging=true; dragStart=input.Position; startPos=root.Position end
    local function update(input)
        if not dragging or not dragStart or not startPos then return end
        local delta = input.Position - dragStart
        root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
    local function stop() dragging=false end
    header.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then begin(i) end end)
    UIS.InputChanged:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch then update(i) end end)
    UIS.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then stop() end end)
end

-- Min/Close
local function clickRipple(b,x,y) ripple(b, Vector2.new(x - b.AbsolutePosition.X, y - b.AbsolutePosition.Y)); playClick() end
btnMin.MouseButton1Down:Connect(function(x,y) clickRipple(btnMin,x,y) end)
btnClose.MouseButton1Down:Connect(function(x,y) clickRipple(btnClose,x,y) end)
btnMin.Activated:Connect(function()
    playClick()
    tween(root, 0.2, {Size=UDim2.fromScale(0.42,0.1)}):Play()
    tween(root, 0.2, {BackgroundTransparency=0.25}):Play()
    task.delay(0.22, function() content.Visible=false end)
end)
btnClose.Activated:Connect(function()
    playClick()
    root.Visible=false; shade.Visible=false
    setBlur(false)
end)

-- Toggle show/hide
local shown=false
local function openUI()
    content.Visible=true; root.Visible=true; shade.Visible=true
    tween(shade,0.2,{BackgroundTransparency=0.35}):Play()
    setBlur(true)
    local cam = workspace.CurrentCamera
    local vp = (cam and cam.ViewportSize) or Vector2.new(1280,720)
    local s = math.clamp(math.min(vp.X/1920, vp.Y/1080), 0.35, 1)
    root.Size = UDim2.fromScale(0.42*s/0.7, 0.52*s/0.7)
end
local function closeUI()
    tween(shade,0.2,{BackgroundTransparency=1}):Play()
    task.delay(0.2, function() shade.Visible=false end)
    root.Visible=false; setBlur(false)
end
local function toggleUI() shown = not shown; if shown then openUI() else closeUI() end end

UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == CFG.Hotkey then toggleUI() end
end)
shade.InputBegan:Connect(function(i)
    if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then closeUI(); shown=false end
end)

-- First open
task.delay(0.2, function()
    shown=true; openUI()
    toast("GUI загружен ✨", 2.6)
end)

-- Queue on teleport (optional)
if CFG.ReloadOnTeleport and queue_on_teleport then
    queue_on_teleport([[pcall(function() loadstring(game:HttpGet("]]..
        (getgenv().CyberDeskURL or "https://raw.githubusercontent.com/Serovodorodov/GuiTest/main/cyberdesk.lua") ..
    [["))() end)]])
end
