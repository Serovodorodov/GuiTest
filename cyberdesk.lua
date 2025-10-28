--!strict
-- CyberDesk — стильный неоновый GUI (один LocalScript, положите в StarterPlayerScripts)
-- Особенности:
--  • Вызов/скрытие по RightShift
--  • Перетаскиваемое окно с “стеклянным” фоном, неоновый градиент и подсветка
--  • Вкладки: Главная / Инструменты / Настройки
--  • Кнопки с рипплом, тумблеры, слайдер (0..100) с подсказками
--  • Тост-уведомления (правый-низ)
--  • Лёгкий блюр сцены при открытом меню
--  • Мобильная поддержка (тач)

---------------------
-- Services/Globals
---------------------
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

---------------------
-- Helpers
---------------------
local function tween(o: Instance, t: number, props: any, style: Enum.EasingStyle?, dir: Enum.EasingDirection?)
	return TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local function mk(className: string, props: {}?, parent: Instance?)
	local o = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			(o :: any)[k] = v
		end
	end
	if parent then o.Parent = parent end
	return o
end

local function makeUIStroke(parent: Instance, thickness: number, transparency: number)
	local stroke = mk("UIStroke", {
		Thickness = thickness,
		Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	}, parent)
	return stroke
end

local function addCorner(parent: Instance, radius: number)
	return mk("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function makeGradient(parent: Instance, colors: {ColorSequenceKeypoint}, rotation: number?)
	local g = mk("UIGradient", {
		Color = ColorSequence.new(colors),
		Rotation = rotation or 0
	}, parent)
	return g
end

local function rippleAt(button: TextButton | ImageButton, pos: Vector2)
	-- Матовый риппл-аним, без дорогих масок
	local ripple = mk("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromOffset(pos.X, pos.Y),
		Size = UDim2.fromOffset(0, 0),
		BackgroundColor3 = Color3.fromRGB(255,255,255),
		BackgroundTransparency = 0.7,
		BorderSizePixel = 0,
		ZIndex = (button.ZIndex or 1) + 1,
	}, button)
	addCorner(ripple, 999)
	local max = math.max(button.AbsoluteSize.X, button.AbsoluteSize.Y) * 1.4
	tween(ripple, 0.35, {Size = UDim2.fromOffset(max, max), BackgroundTransparency = 1}):Play()
	game:GetService("Debris"):AddItem(ripple, 0.4)
end

local function playClick()
	local s = mk("Sound", {
		SoundId = "rbxassetid://9120299506", -- лёгкий клик (из памяти проекта)
		Volume = 0.25,
	}, SoundService)
	s:Play()
	s.Ended:Connect(function() s:Destroy() end)
end

---------------------
-- ScreenGui + Blur
---------------------
local gui = mk("ScreenGui", {
	Name = "CyberDeskGUI",
	IgnoreGuiInset = false,
	ResetOnSpawn = false,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

-- Лёгкое затемнение заднего плана при открытом окне
local shade = mk("Frame", {
	BackgroundColor3 = Color3.new(0,0,0),
	BackgroundTransparency = 1,
	Size = UDim2.fromScale(1,1),
	Visible = false
}, gui)

-- Создаём блюр Lighting (уникальное имя, чтобы не конфликтовать)
local function ensureBlur(enable: boolean)
	local name = "CyberDesk_Blur"
	local blur = Lighting:FindFirstChild(name) :: BlurEffect?
	if enable then
		if not blur then
			blur = mk("BlurEffect", { Name = name, Size = 0 }, Lighting) :: BlurEffect
		end
		tween(blur, 0.25, {Size = 12}):Play()
	else
		if blur then
			tween(blur, 0.25, {Size = 0}):Play()
			task.delay(0.3, function()
				if blur then blur:Destroy() end
			end)
		end
	end
end

---------------------
-- Main Window
---------------------
local root = mk("Frame", {
	Name = "Window",
	Size = UDim2.fromScale(0.42, 0.52),
	Position = UDim2.fromScale(0.29, 0.24),
	BackgroundTransparency = 0.15,
	BackgroundColor3 = Color3.fromRGB(12,12,16),
	BorderSizePixel = 0,
	Visible = false,
}, gui)
addCorner(root, 18)
makeUIStroke(root, 1.2, 0.2)
local bgGlass = makeGradient(root, {
	ColorSequenceKeypoint.new(0, Color3.fromRGB(12,12,16)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(18,18,28)),
})

-- Неоновая рамка
local neonStroke = makeUIStroke(root, 2.2, 0.15)
local neonGrad = makeGradient(neonStroke, {
	ColorSequenceKeypoint.new(0.00, Color3.fromRGB(0, 255, 213)),
	ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 119, 255)),
	ColorSequenceKeypoint.new(1.00, Color3.fromRGB(0, 255, 136)),
})
neonGrad.Rotation = 0
task.spawn(function()
	while root and root.Parent do
		local tw = tween(neonGrad, 6, {Rotation = (neonGrad.Rotation + 360)%360}, Enum.EasingStyle.Linear)
		tw:Play()
		tw.Completed:Wait()
	end
end)

-- Шапка
local header = mk("Frame", {
	Name = "Header",
	Size = UDim2.new(1, 0, 0, 48),
	BackgroundTransparency = 0.25,
	BackgroundColor3 = Color3.fromRGB(14,18,24),
	BorderSizePixel = 0,
}, root)
addCorner(header, 18)
makeUIStroke(header, 1, 0.65)

local title = mk("TextLabel", {
	Text = "CyberDesk",
	Font = Enum.Font.GothamBold,
	TextSize = 20,
	TextColor3 = Color3.fromRGB(230, 244, 255),
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.04, 0.5),
	Size = UDim2.fromScale(0.5, 1),
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

local subtitle = mk("TextLabel", {
	Text = "SerovEX • Neon UI",
	Font = Enum.Font.Gotham,
	TextSize = 13,
	TextColor3 = Color3.fromRGB(160, 200, 245),
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0, 0.5),
	Position = UDim2.fromScale(0.04, 0.78),
	Size = UDim2.fromScale(0.5, 0.5),
	TextXAlignment = Enum.TextXAlignment.Left,
}, header)

-- Кнопки управления (минимайз/закрыть)
local btnClose = mk("TextButton", {
	Text = "✕",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(230,230,240),
	BackgroundTransparency = 0.8,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.97, 0.5),
	Size = UDim2.fromOffset(32, 28),
	AutoButtonColor = false,
}, header)
addCorner(btnClose, 12)

local btnMin = mk("TextButton", {
	Text = "—",
	Font = Enum.Font.GothamBold,
	TextSize = 16,
	TextColor3 = Color3.fromRGB(230,230,240),
	BackgroundTransparency = 0.8,
	AnchorPoint = Vector2.new(1, 0.5),
	Position = UDim2.fromScale(0.90, 0.5),
	Size = UDim2.fromOffset(32, 28),
	AutoButtonColor = false,
}, header)
addCorner(btnMin, 12)

-- Левая панель вкладок
local sidebar = mk("Frame", {
	Name = "Sidebar",
	Size = UDim2.new(0, 160, 1, -48),
	Position = UDim2.fromOffset(0, 48),
	BackgroundTransparency = 0.35,
	BackgroundColor3 = Color3.fromRGB(10, 12, 18),
	BorderSizePixel = 0,
}, root)
local sbStroke = makeUIStroke(sidebar, 1, 0.7)
addCorner(sidebar, 18)

local list = mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	Padding = UDim.new(0,8),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Start,
}, sidebar)
mk("UIPadding", {
	PaddingTop = UDim.new(0, 12)
}, sidebar)

local function makeTabButton(text: string)
	local b = mk("TextButton", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(220, 235, 255),
		AutoButtonColor = false,
		BackgroundColor3 = Color3.fromRGB(18, 22, 30),
		BackgroundTransparency = 0.15,
		Size = UDim2.fromOffset(136, 40),
	}, sidebar)
	addCorner(b, 12)
	makeUIStroke(b, 1, 0.7)
	return b
end

local tabHomeBtn = makeTabButton("Главная")
local tabToolsBtn = makeTabButton("Инструменты")
local tabSettingsBtn = makeTabButton("Настройки")

-- Контентная область
local content = mk("Frame", {
	Name = "Content",
	Size = UDim2.new(1, -160, 1, -48),
	Position = UDim2.fromOffset(160, 48),
	BackgroundTransparency = 1
}, root)

local function makePage(name: string)
	local p = mk("Frame", {
		Name = name,
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
		Visible = false
	}, content)
	return p
end

local pageHome = makePage("Home")
local pageTools = makePage("Tools")
local pageSettings = makePage("Settings")

local function showPage(p: Frame)
	for _, ch in ipairs(content:GetChildren()) do
		if ch:IsA("Frame") then
			ch.Visible = false
		end
	end
	p.Visible = true
end
showPage(pageHome)

---------------------
-- Home Page
---------------------
do
	local card = mk("Frame", {
		Size = UDim2.fromScale(0.9, 0.4),
		Position = UDim2.fromScale(0.5, 0.32),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 18, 26),
		BackgroundTransparency = 0.1,
	}, pageHome)
	addCorner(card, 20)
	makeUIStroke(card, 1.2, 0.35)
	makeGradient(card, {
		ColorSequenceKeypoint.new(0, Color3.fromRGB(18,20,30)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(12,12,20)),
	}, 90)

	local h = mk("TextLabel", {
		Text = "Добро пожаловать!",
		Font = Enum.Font.GothamBlack,
		TextSize = 26,
		TextColor3 = Color3.fromRGB(230, 245, 255),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.25),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, card)

	local p = mk("TextLabel", {
		Text = "Это демонстрация крутого неон-UI: вкладки, анимации, слайдеры, уведомления.\nНажми RightShift чтобы скрыть/показать панель.",
		Font = Enum.Font.Gotham,
		TextWrapped = true,
		TextSize = 16,
		TextTransparency = 0.05,
		TextColor3 = Color3.fromRGB(195, 215, 245),
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.5, 0.55),
		Size = UDim2.fromScale(0.9, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, card)

	-- Мини “частицы” (UI-пузырьки)
	for i = 1, 16 do
		local dot = mk("Frame", {
			Size = UDim2.fromOffset(math.random(3,6), math.random(3,6)),
			BackgroundColor3 = Color3.fromRGB(0, 255, 200),
			BackgroundTransparency = 0.35,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(math.random(), math.random()),
			ZIndex = (card.ZIndex or 1) + 1
		}, card)
		addCorner(dot, 99)
		task.spawn(function()
			while dot.Parent do
				local nx, ny = math.random(), math.random()
				tween(dot, math.random(6,10)/10, {
					Position = UDim2.fromScale(nx, ny),
					BackgroundTransparency = math.random() * 0.6 + 0.2
				}, Enum.EasingStyle.Sine):Play()
				task.wait(math.random(8,14)/10)
			end
		end)
	end
end

---------------------
-- Tools Page (кнопки/тумблер/слайдер)
---------------------
-- Тосты
local toastContainer = mk("Frame", {
	Size = UDim2.fromScale(0.38, 1),
	Position = UDim2.fromScale(0.99, 0.98),
	AnchorPoint = Vector2.new(1,1),
	BackgroundTransparency = 1,
}, pageTools)

mk("UIListLayout", {
	FillDirection = Enum.FillDirection.Vertical,
	HorizontalAlignment = Enum.HorizontalAlignment.Right,
	VerticalAlignment = Enum.VerticalAlignment.Bottom,
	Padding = UDim.new(0,6),
}, toastContainer)

local function toast(text: string, dur: number?)
	local box = mk("Frame", {
		Size = UDim2.fromOffset(320, 60),
		BackgroundColor3 = Color3.fromRGB(14, 18, 26),
		BackgroundTransparency = 0.1,
	}, toastContainer)
	addCorner(box, 12)
	makeUIStroke(box, 1, 0.5)
	local t = mk("TextLabel", {
		Text = text,
		Font = Enum.Font.Gotham,
		TextSize = 15,
		TextWrapped = true,
		TextColor3 = Color3.fromRGB(220,235,255),
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1,1),
	}, box)
	box.Size = UDim2.fromOffset(0, 60)
	tween(box, 0.25, {Size = UDim2.fromOffset(320,60)}):Play()
	task.delay(dur or 2.5, function()
		if box and box.Parent then
			local tw = tween(box, 0.25, {BackgroundTransparency = 1, Size = UDim2.fromOffset(0, 60)})
			tw:Play()
			tw.Completed:Wait()
			box:Destroy()
		end
	end)
end

-- Карточка инструментов
local toolsCard = mk("Frame", {
	Size = UDim2.fromScale(0.9, 0.75),
	Position = UDim2.fromScale(0.5, 0.52),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundColor3 = Color3.fromRGB(15, 18, 26),
	BackgroundTransparency = 0.08,
}, pageTools)
addCorner(toolsCard, 18)
makeUIStroke(toolsCard, 1.1, 0.45)

local toolsLayout = mk("UIListLayout", {
	Padding = UDim.new(0, 10),
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Top,
}, toolsCard)
mk("UIPadding", {
	PaddingTop = UDim.new(0, 16)
}, toolsCard)

local function makeButton(text: string)
	local b = mk("TextButton", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(225,235,255),
		AutoButtonColor = false,
		Size = UDim2.fromOffset(420, 44),
		BackgroundColor3 = Color3.fromRGB(20,24,34),
		BackgroundTransparency = 0.05,
	}, toolsCard)
	addCorner(b, 10)
	makeUIStroke(b, 1, 0.6)
	b.MouseButton1Down:Connect(function(x,y)
		local p = Vector2.new(x - b.AbsolutePosition.X, y - b.AbsolutePosition.Y)
		rippleAt(b, p); playClick()
	end)
	return b
end

local btnDemo = makeButton("Показать тост-уведомление")
btnDemo.Activated:Connect(function()
	toast("Это демо уведомление ✨", 2.5)
end)

-- Тумблер
local function makeToggle(text: string, default: boolean)
	local holder = mk("Frame", {
		Size = UDim2.fromOffset(420, 44),
		BackgroundTransparency = 1,
	}, toolsCard)
	local label = mk("TextLabel", {
		Text = text,
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(210,225,245),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(0, 0.5),
		Size = UDim2.fromScale(0.7, 1),
		TextXAlignment = Enum.TextXAlignment.Left
	}, holder)

	local sw = mk("TextButton", {
		AutoButtonColor = false,
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1,0.5),
		Size = UDim2.fromOffset(64, 28),
		BackgroundColor3 = Color3.fromRGB(28, 34, 46),
		Text = "",
	}, holder)
	addCorner(sw, 14)
	makeUIStroke(sw, 1, 0.6)

	local dot = mk("Frame", {
		Size = UDim2.fromOffset(24,24),
		Position = UDim2.fromOffset(default and 38 or 4, 2),
		BackgroundColor3 = default and Color3.fromRGB(0,210,255) or Color3.fromRGB(90,98,112),
	}, sw)
	addCorner(dot, 12)

	local state = default
	local function setState(on: boolean)
		state = on
		tween(dot, 0.18, {
			Position = UDim2.fromOffset(on and 38 or 4, 2),
			BackgroundColor3 = on and Color3.fromRGB(0,210,255) or Color3.fromRGB(90,98,112)
		}):Play()
	end
	setState(default)

	sw.Activated:Connect(function()
		playClick()
		setState(not state)
		toast((state and "Включено" or "Выключено") .. ": ".. text, 1.7)
	end)

	return {
		Holder = holder,
		Get = function() return state end,
		Set = setState,
	}
end

local tgPulse = makeToggle("Пульс подсветки рамки", true)

-- Слайдер (0..100)
local function makeSlider(text: string, defaultVal: number)
	local holder = mk("Frame", {
		Size = UDim2.fromOffset(420, 70),
		BackgroundTransparency = 1,
	}, toolsCard)
	local label = mk("TextLabel", {
		Text = text.."  ("..tostring(defaultVal)..")",
		Font = Enum.Font.GothamMedium,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(210,225,245),
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(420, 24),
		TextXAlignment = Enum.TextXAlignment.Left
	}, holder)

	local bar = mk("Frame", {
		Size = UDim2.fromOffset(420, 10),
		Position = UDim2.fromOffset(0, 34),
		BackgroundColor3 = Color3.fromRGB(26, 32, 45),
	}, holder)
	addCorner(bar, 6)
	makeUIStroke(bar, 1, 0.7)

	local fill = mk("Frame", {
		Size = UDim2.fromScale(defaultVal/100, 1),
		BackgroundColor3 = Color3.fromRGB(0, 200, 255),
	}, bar)
	addCorner(fill, 6)

	local knob = mk("ImageButton", {
		Size = UDim2.fromOffset(18,18),
		Position = UDim2.fromOffset(math.floor( (bar.AbsoluteSize.X) * (defaultVal/100) - 9), -4),
		BackgroundTransparency = 1,
		Image = "rbxassetid://7072724538", -- кругленький маркер
	}, bar)

	local dragging = false
	local value = defaultVal

	local function setValue(v: number)
		value = math.clamp(math.floor(v + 0.5), 0, 100)
		label.Text = text .. "  (".. value ..")"
		fill.Size = UDim2.fromScale(value/100, 1)
	end
	setValue(defaultVal)

	local function updateFromPointer(px: number)
		local rel = (px - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		setValue(rel * 100)
	end

	knob.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			playClick()
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			updateFromPointer(input.Position.X)
		end
	end)
	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			updateFromPointer(input.Position.X)
		end
	end)

	return {
		Holder = holder,
		Get = function() return value end,
		Set = setValue,
	}
end

local slGlow = makeSlider("Яркость подсветки (визуально)", 60)

local btnApply = makeButton("Применить настройки подсветки")
btnApply.Activated:Connect(function()
	playClick()
	local brightness = slGlow.Get() / 100
	neonStroke.Transparency = 0.25 + (1 - brightness) * 0.6
	toast(("Подсветка: %.0f%%"):format(slGlow.Get()), 2)
end)

-- Пульсация рамки
task.spawn(function()
	while root and root.Parent do
		if tgPulse.Get() then
			local t1 = tween(neonStroke, 0.85, {Thickness = 2.8})
			t1:Play(); t1.Completed:Wait()
			local t2 = tween(neonStroke, 0.85, {Thickness = 1.8})
			t2:Play(); t2.Completed:Wait()
		else
			task.wait(0.2)
		end
	end
end)

---------------------
-- Settings Page
---------------------
do
	local box = mk("Frame", {
		Size = UDim2.fromScale(0.9, 0.6),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 18, 26),
		BackgroundTransparency = 0.08,
	}, pageSettings)
	addCorner(box, 16)
	makeUIStroke(box, 1.1, 0.45)

	local t = mk("TextLabel", {
		Text = "Настройки UI",
		Font = Enum.Font.GothamBold,
		TextSize = 20,
		TextColor3 = Color3.fromRGB(230,245,255),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 10),
		Size = UDim2.fromOffset(300, 26),
		TextXAlignment = Enum.TextXAlignment.Left
	}, box)

	local kb = mk("TextLabel", {
		Text = "Горячая клавиша: RightShift — показать/скрыть",
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(200,215,235),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 44),
		Size = UDim2.fromOffset(520, 24),
		TextXAlignment = Enum.TextXAlignment.Left
	}, box)

	local info = mk("TextLabel", {
		Text = "Подгонка под мобильные экраны: окно адаптируется по ширине/высоте.",
		Font = Enum.Font.Gotham,
		TextSize = 16,
		TextColor3 = Color3.fromRGB(200,215,235),
		BackgroundTransparency = 1,
		Position = UDim2.fromOffset(16, 74),
		Size = UDim2.fromOffset(560, 24),
		TextXAlignment = Enum.TextXAlignment.Left
	}, box)
end

---------------------
-- Tabs logic
---------------------
local function selectTab(btn: TextButton, page: Frame)
	playClick()
	for _, b in ipairs({tabHomeBtn, tabToolsBtn, tabSettingsBtn}) do
		tween(b, 0.12, {BackgroundTransparency = b == btn and 0 or 0.15}):Play()
	end
	showPage(page)
end

tabHomeBtn.Activated:Connect(function() selectTab(tabHomeBtn, pageHome) end)
tabToolsBtn.Activated:Connect(function() selectTab(tabToolsBtn, pageTools) end)
tabSettingsBtn.Activated:Connect(function() selectTab(tabSettingsBtn, pageSettings) end)
tabHomeBtn.BackgroundTransparency = 0 -- активна по умолчанию

---------------------
-- Drag window
---------------------
do
	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil

	local function begin(input: InputObject)
		dragging = true
		dragStart = input.Position
		startPos = root.Position
	end

	local function update(input: InputObject)
		if not dragging or not dragStart or not startPos then return end
		local delta = input.Position - dragStart
		root.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end

	local function stop()
		dragging = false
	end

	header.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			begin(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			update(input)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			stop()
		end
	end)
end

---------------------
-- Min/Close
---------------------
btnMin.MouseButton1Down:Connect(function(x,y) rippleAt(btnMin, Vector2.new(x - btnMin.AbsolutePosition.X, y - btnMin.AbsolutePosition.Y)); playClick() end)
btnClose.MouseButton1Down:Connect(function(x,y) rippleAt(btnClose, Vector2.new(x - btnClose.AbsolutePosition.X, y - btnClose.AbsolutePosition.Y)); playClick() end)

btnMin.Activated:Connect(function()
	playClick()
	tween(root, 0.2, {Size = UDim2.fromScale(0.42, 0.1)}):Play()
	tween(root, 0.2, {BackgroundTransparency = 0.25}):Play()
	task.delay(0.22, function()
		content.Visible = false
	end)
end)

btnClose.Activated:Connect(function()
	playClick()
	root.Visible = false
	shade.Visible = false
	ensureBlur(false)
end)

---------------------
-- Show / Hide (RightShift)
---------------------
local function openUI()
	content.Visible = true
	root.Visible = true
	shade.Visible = true
	tween(shade, 0.2, {BackgroundTransparency = 0.35}):Play()
	ensureBlur(true)

	-- Адаптация под мобильные экраны
	local minW, minH = 540, 360
	local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
	local scaleW = math.clamp(vp.X / 1920, 0.26, 1)
	local scaleH = math.clamp(vp.Y / 1080, 0.26, 1)
	local s = math.clamp(math.min(scaleW, scaleH), 0.35, 1)
	root.Size = UDim2.fromScale(0.42*s/0.7, 0.52*s/0.7)
end

local function closeUI()
	tween(shade, 0.2, {BackgroundTransparency = 1}):Play()
	task.delay(0.2, function() shade.Visible = false end)
	root.Visible = false
	ensureBlur(false)
end

local shown = false
local function toggleUI()
	shown = not shown
	if shown then openUI() else closeUI() end
end

UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.RightShift then
		toggleUI()
	end
end)

-- Щёлк по тёмной подложке — закрыть
shade.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		closeUI()
		shown = false
	end
end)

-- Открываем первый раз красиво
task.delay(0.2, function()
	shown = true
	openUI()
	toast("GUI загружен ✨ Приятной работы!", 2.8)
end)
