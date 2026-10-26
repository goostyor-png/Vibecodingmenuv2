local Players = game:GetService("Players")
local TS = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local MPS = game:GetService("MarketplaceService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local Stats = game:GetService("Stats")
local okVU, VU = pcall(game.GetService, game, "VirtualUser")

local lp = Players.LocalPlayer
local pgui = lp:WaitForChild("PlayerGui")
local genv = (getgenv and getgenv()) or _G
if genv.AuraUnload then pcall(genv.AuraUnload) end
if pgui:FindFirstChild("AuraMenu") then pgui.AuraMenu:Destroy() end
if SoundService:FindFirstChild("AuraSound") then SoundService.AuraSound:Destroy() end
for _, v in ipairs(Lighting:GetChildren()) do if v.Name == "AuraBlur" then v:Destroy() end end

local WIN_W, WIN_H, TOP, SB = 420, 270, 36, 96
local EASE, DIR = Enum.EasingStyle, Enum.EasingDirection
local WHITE = Color3.new(1, 1, 1)
local C = {
	bg = Color3.fromRGB(13, 13, 20), bar = Color3.fromRGB(19, 19, 28),
	card = Color3.fromRGB(25, 25, 37), card2 = Color3.fromRGB(38, 38, 55),
	text = Color3.fromRGB(238, 238, 248), sub = Color3.fromRGB(140, 140, 168),
	off = Color3.fromRGB(52, 52, 72), bad = Color3.fromRGB(255, 95, 105), good = Color3.fromRGB(80, 225, 140),
}
local accent = Color3.fromRGB(130, 100, 255)
local reg, conns, trReg, ctl = {}, {}, {}, {}
local rainbow, hue = false, 0
local lang = "Русский"
local cfg = {}

local EN = {
	["Музыка"] = "Music", ["Эффекты"] = "Effects", ["Визуал"] = "Visuals", ["Разное"] = "Misc", ["Настройки"] = "Settings",
	["ПЛЕЕР"] = "PLAYER", ["Вставьте ID песни"] = "Paste song ID", ["Играть"] = "Play", ["Пауза"] = "Pause", ["Стоп"] = "Stop",
	["-10с"] = "-10s", ["+10с"] = "+10s", ["Трек"] = "Track", ["Повтор трека"] = "Repeat track",
	["СКОРОСТЬ И ТОНАЛЬНОСТЬ"] = "SPEED & PITCH", ["Скорость"] = "Speed", ["Менять тон со скоростью"] = "Pitch follows speed",
	["Тональность"] = "Pitch", ["пт"] = "st", ["ГРОМКОСТЬ"] = "VOLUME", ["Усиление"] = "Gain", ["Сбросить всё"] = "Reset all",
	["ПРЕСЕТЫ"] = "PRESETS", ["Сброс"] = "Reset", ["ЭКВАЛАЙЗЕР"] = "EQUALIZER", ["Низкие"] = "Low", ["Средние"] = "Mid",
	["Высокие"] = "High", ["ПРОСТРАНСТВО"] = "SPACE", ["Реверберация"] = "Reverb", ["Эхо"] = "Echo",
	["ОТОБРАЖЕНИЕ"] = "DISPLAY", ["Подсветка игроков"] = "Player highlight", ["Скелет"] = "Skeleton", ["Имена"] = "Names",
	["Дистанция"] = "Distance", ["Дальность"] = "Range", ["Стиль"] = "Style", ["Контур"] = "Outline", ["Заливка"] = "Fill",
	["Градиент"] = "Gradient", ["ст."] = "studs", ["ОБЩЕЕ"] = "GENERAL", ["Анти-АФК"] = "Anti-AFK", ["Показывать FPS"] = "Show FPS",
	["Авто-перезаход"] = "Auto rejoin", ["Поле зрения"] = "Field of view", ["Язык"] = "Language",
	["Сохранить конфиг"] = "Save config", ["Загрузить конфиг"] = "Load config", ["ЦВЕТ АКЦЕНТА"] = "ACCENT COLOR",
	["Оттенок"] = "Hue", ["ОКНО"] = "WINDOW", ["Прозрачность"] = "Transparency", ["Размер меню"] = "Menu size",
	["Размытие фона"] = "Background blur", ["Сбросить позицию"] = "Reset position", ["Выгрузить меню"] = "Unload menu",
	["Ничего не играет"] = "Nothing playing", ["Введите ID и нажмите «Играть»"] = "Enter an ID and press Play",
	["Введите числовой ID"] = "Enter a numeric ID", ["Загрузка..."] = "Loading...", ["Играет"] = "Playing",
	["На паузе"] = "Paused", ["Остановлено"] = "Stopped", ["Трек закончился"] = "Track ended", ["Ошибка"] = "Error",
	["Не загрузилось: ID закрыт или неверный"] = "Failed to load: ID is private or invalid",
	["Трек загружен"] = "Track loaded", ["Не удалось загрузить ID"] = "Could not load ID", ["Пресет: "] = "Preset: ",
	["Всё сброшено"] = "Everything reset", ["Акцент изменён"] = "Accent changed", ["Радужный режим"] = "Rainbow mode",
	["Радуга выключена"] = "Rainbow off", ["Конфиг сохранён"] = "Config saved", ["Сохранение недоступно"] = "Saving unavailable",
	["Конфиг загружен"] = "Config loaded", ["Конфиг не найден"] = "Config not found", ["Переподключение..."] = "Reconnecting...",
	["AURA загружено"] = "AURA loaded", ["Найти"] = "Search", ["Введите название песни"] = "Enter a song title",
}

local function T(s)
	if lang == "English" then return EN[s] or s end
	return s
end

local function bind(o, s, prop)
	prop = prop or "Text"
	o[prop] = T(s)
	trReg[#trReg + 1] = function() o[prop] = T(s) end
end

local function setLang(i)
	lang = i == 2 and "English" or "Русский"
	for _, f in ipairs(trReg) do f() end
	for _, o in pairs(ctl) do if o.Refresh then o.Refresh() end end
end

local function cn(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns + 1] = c
	return c
end

local function tw(o, p, t, st, dr)
	local tween = TS:Create(o, TweenInfo.new(t or .2, st or EASE.Quint, dr or DIR.Out), p)
	tween:Play()
	return tween
end

local lo = 0
local function new(class, props, parent)
	local o = Instance.new(class)
	if o:IsA("GuiObject") then o.BorderSizePixel = 0 end
	if class == "UIListLayout" then o.SortOrder = Enum.SortOrder.LayoutOrder end
	for k, v in pairs(props) do o[k] = v end
	if parent then
		if o:IsA("GuiObject") and parent:FindFirstChildOfClass("UIListLayout") then lo += 1; o.LayoutOrder = lo end
		o.Parent = parent
	end
	return o
end

local function round(o, r) new("UICorner", {CornerRadius = UDim.new(0, r or 8)}, o) end
local function stroke(p, th, col, tr)
	return new("UIStroke", {Thickness = th, Color = col, Transparency = tr, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}, p)
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end

local function acc(o, prop, get)
	get = get or function() return accent end
	o[prop] = get()
	reg[#reg + 1] = function(instant)
		if instant then o[prop] = get() else tw(o, {[prop] = get()}, .35) end
	end
end

local function light(c) return c:Lerp(WHITE, .65) end
local function dark(c) return c:Lerp(Color3.new(0, 0, 0), .8) end
local function shift(c)
	local h, s, v = c:ToHSV()
	return Color3.fromHSV((h + .18) % 1, s, v)
end
local function loop(o, props, t)
	TS:Create(o, TweenInfo.new(t, EASE.Linear, DIR.InOut, -1), props):Play()
end

local function grad(parent, mk, props)
	local g = new("UIGradient", props or {}, parent)
	g.Color = mk()
	reg[#reg + 1] = function() g.Color = mk() end
	return g
end

local function lbl(parent, text, size, color, extra)
	local p = {BackgroundTransparency = 1, TextSize = size or 13, TextColor3 = color or C.text, Font = Enum.Font.GothamMedium,
		TextXAlignment = Enum.TextXAlignment.Left, Size = UDim2.fromScale(1, 1), TextTruncate = Enum.TextTruncate.AtEnd}
	for k, v in pairs(extra or {}) do p[k] = v end
	local o = new("TextLabel", p, parent)
	if text ~= "" then bind(o, text) end
	return o
end

local function press(b, flat)
	local s = new("UIScale", {Name = "Pop"}, b)
	b.ClipsDescendants = true
	local cr = b:FindFirstChildOfClass("UICorner")
	local ov = new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 4}, b)
	if cr then new("UICorner", {CornerRadius = cr.CornerRadius}, ov) end
	cn(b.MouseEnter, function() tw(ov, {BackgroundTransparency = .9}, .2) end)
	cn(b.MouseLeave, function() tw(ov, {BackgroundTransparency = 1}, .3) end)
	cn(b.InputBegan, function(i)
		if not isPress(i) then return end
		tw(s, {Scale = .93}, .1)
		local sz = b.AbsoluteSize
		if flat or sz.X < 1 then return end
		local k = math.max(sz.X, sz.Y) * 2.2
		local rp = new("Frame", {BackgroundColor3 = WHITE, BackgroundTransparency = .75, AnchorPoint = Vector2.new(.5, .5),
			Position = UDim2.fromScale((i.Position.X - b.AbsolutePosition.X) / sz.X, (i.Position.Y - b.AbsolutePosition.Y) / sz.Y),
			Size = UDim2.fromOffset(0, 0), ZIndex = 5}, b)
		round(rp, 200)
		tw(rp, {Size = UDim2.fromOffset(k, k), BackgroundTransparency = 1}, .55).Completed:Connect(function() rp:Destroy() end)
	end)
	cn(b.InputEnded, function(i) if isPress(i) then tw(s, {Scale = 1}, .3, EASE.Back) end end)
end

local CFG_FILE = "AuraMenu.json"
local function loadCfg()
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_FILE)) end)
	if ok and type(data) == "table" then cfg = data return true end
	return false
end
local function saveCfg()
	return pcall(function() writefile(CFG_FILE, HttpService:JSONEncode(cfg)) end)
end
loadCfg()
if type(cfg.accent) == "table" and cfg.accent[3] then accent = Color3.new(cfg.accent[1], cfg.accent[2], cfg.accent[3]) end
rainbow = cfg.rainbow == true
lang = cfg.lang == 2 and "English" or "Русский"

local gui = new("ScreenGui", {Name = "AuraMenu", ResetOnSpawn = false, IgnoreGuiInset = true,
	ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 100}, pgui)
local blur = new("BlurEffect", {Name = "AuraBlur", Size = 0}, Lighting)
local blurOn = true
local skelLayer = new("Frame", {Name = "ESP", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, gui)

local toastF
local function toast(text, col)
	text = T(text)
	if toastF then toastF:Destroy() end
	local f = new("Frame", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.new(.5, 0, 0, -50), Size = UDim2.fromOffset(0, 34),
		AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.bar, ZIndex = 20}, gui)
	toastF = f
	round(f, 17)
	new("UIPadding", {PaddingLeft = UDim.new(0, 30), PaddingRight = UDim.new(0, 18)}, f)
	stroke(f, 1.5, accent, .3)
	local dot = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.new(0, -15, .5, 0), Size = UDim2.fromOffset(8, 8),
		BackgroundColor3 = col or accent, ZIndex = 21}, f)
	round(dot, 4)
	TS:Create(dot, TweenInfo.new(.6, EASE.Sine, DIR.InOut, -1, true), {BackgroundTransparency = .6}):Play()
	new("TextLabel", {BackgroundTransparency = 1, Text = text, TextSize = 13, TextColor3 = C.text, Font = Enum.Font.GothamMedium,
		Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 21}, f)
	tw(f, {Position = UDim2.new(.5, 0, 0, 14)}, .55, EASE.Back)
	task.delay(2.4, function()
		if f.Parent then
			tw(f, {Position = UDim2.new(.5, 0, 0, -50)}, .4, EASE.Quad, DIR.In).Completed:Connect(function() f:Destroy() end)
		end
	end)
end

local function drag(handle, target, bounds)
	local st = {moved = false}
	local active, inp, origin, start
	cn(handle.InputBegan, function(i)
		if isPress(i) then
			active, inp, origin, start, st.moved = true, i, i.Position, target.Position, false
			i.Changed:Connect(function() if i.UserInputState == Enum.UserInputState.End then active = false end end)
		end
	end)
	cn(UIS.InputChanged, function(i)
		if active and (i == inp or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - origin
			if d.Magnitude > 6 then st.moved = true end
			if not st.moved then return end
			local W, H = gui.AbsoluteSize.X, gui.AbsoluteSize.Y
			local x0, x1, y0, y1 = bounds(W, H)
			local nx = math.clamp(start.X.Scale * W + start.X.Offset + d.X, x0, x1) - start.X.Scale * W
			local ny = math.clamp(start.Y.Scale * H + start.Y.Offset + d.Y, y0, y1) - start.Y.Scale * H
			tw(target, {Position = UDim2.new(start.X.Scale, nx, start.Y.Scale, ny)}, .06, EASE.Quad)
		end
	end)
	return st
end

local cam0 = workspace.CurrentCamera
local vp = cam0 and cam0.ViewportSize or Vector2.new(800, 400)
if vp.Y < 150 then vp = Vector2.new(800, 400) end
local baseScale = math.clamp((vp.Y - 40) / WIN_H, .6, 1)
local baseGT, opened, collapsed, openTok = 0, false, false, 0
local startPos = UDim2.new(.5, 0, 0, math.max(6, (vp.Y - WIN_H * baseScale) / 2))

local holder = new("Frame", {Name = "Holder", Size = UDim2.fromOffset(WIN_W, WIN_H), AnchorPoint = Vector2.new(.5, 0),
	Position = startPos, BackgroundTransparency = 1}, gui)
local main = new("CanvasGroup", {AnchorPoint = Vector2.new(.5, 0), Position = UDim2.fromScale(.5, 0), Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = C.bg, GroupTransparency = 1, Visible = false}, holder)
round(main, 12)
local mscale = new("UIScale", {Scale = baseScale}, main)
local mstroke = stroke(main, 2, WHITE, .15)
loop(grad(mstroke, function() return ColorSequence.new({ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, dark(accent)), ColorSequenceKeypoint.new(1, accent)}) end), {Rotation = 360}, 5)

local tint = new("Frame", {Size = UDim2.fromScale(1, 1)}, main)
acc(tint, "BackgroundColor3")
new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .88), NumberSequenceKeypoint.new(1, 1)})}, tint)

for k = 1, 2 do
	local o = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(220, 220), BackgroundTransparency = .93,
		Position = UDim2.fromScale(k == 1 and .1 or .95, k == 1 and .05 or .98)}, main)
	round(o, 110); acc(o, "BackgroundColor3")
	TS:Create(o, TweenInfo.new(7 + k * 2, EASE.Sine, DIR.InOut, -1, true),
		{Position = UDim2.fromScale(k == 1 and .3 or .75, k == 1 and .25 or .8), BackgroundTransparency = .97}):Play()
end

for _ = 1, 14 do
	local sz, d = math.random(3, 6), math.random(60, 120) / 10
	local pt = new("Frame", {BackgroundTransparency = .9, Size = UDim2.fromOffset(sz, sz), AnchorPoint = Vector2.new(.5, .5),
		Position = UDim2.fromScale(math.random(), 1.05)}, main)
	round(pt, 3); acc(pt, "BackgroundColor3")
	TS:Create(pt, TweenInfo.new(d, EASE.Linear, DIR.Out, -1), {Position = UDim2.fromScale(math.random(), -.05)}):Play()
	TS:Create(pt, TweenInfo.new(d / 2, EASE.Sine, DIR.InOut, -1, true), {BackgroundTransparency = .55}):Play()
end

local top = new("Frame", {Size = UDim2.new(1, 0, 0, TOP), BackgroundColor3 = C.bar}, main)
local title = lbl(top, "AURA", 16, WHITE, {Position = UDim2.fromOffset(12, 0), Size = UDim2.fromOffset(56, TOP), Font = Enum.Font.GothamBlack})
loop(grad(title, function() return ColorSequence.new({ColorSequenceKeypoint.new(0, accent), ColorSequenceKeypoint.new(.5, light(accent)), ColorSequenceKeypoint.new(1, accent)}) end,
	{Offset = Vector2.new(-.5, 0)}), {Offset = Vector2.new(.5, 0)}, 1.8)
lbl(top, "by claude", 11, C.sub, {Position = UDim2.fromOffset(70, 1), Size = UDim2.fromOffset(110, TOP)})
local line = new("Frame", {Position = UDim2.new(0, 0, 1, -2), Size = UDim2.new(1, 0, 0, 2)}, top)
acc(line, "BackgroundColor3")
loop(new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .9), NumberSequenceKeypoint.new(.5, 0), NumberSequenceKeypoint.new(1, .9)}),
	Offset = Vector2.new(-1, 0)}, line), {Offset = Vector2.new(1, 0)}, 2.2)

local mini = {}
local miniF = new("Frame", {BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -84, .5, 0), Size = UDim2.fromOffset(16, 12)}, top)
for k = 1, 3 do
	local b = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, (k - 1) * 6, 1, 0), Size = UDim2.fromOffset(4, 3)}, miniF)
	round(b, 2); acc(b, "BackgroundColor3")
	mini[k] = {f = b, h = 3}
end

local function topBtn(txt, n)
	local b = new("TextButton", {Text = txt, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = C.text,
		AutoButtonColor = false, BackgroundColor3 = C.card2, Size = UDim2.fromOffset(28, 22),
		AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8 - (n - 1) * 34, .5, -1)}, top)
	round(b, 6); press(b)
	return b
end
local closeB, colB = topBtn("×", 1), topBtn("–", 2)
cn(closeB.MouseEnter, function() tw(closeB, {BackgroundColor3 = C.bad}, .2) end)
cn(closeB.MouseLeave, function() tw(closeB, {BackgroundColor3 = C.card2}, .25) end)

drag(top, holder, function(W, H) return 40, W - 40, 0, H - 40 end)

local side = new("Frame", {Position = UDim2.fromOffset(6, TOP + 8), Size = UDim2.new(0, SB, 1, -TOP - 14), BackgroundTransparency = 1}, main)
new("Frame", {Position = UDim2.fromOffset(SB + 7, TOP + 14), Size = UDim2.new(0, 1, 1, -TOP - 28), BackgroundColor3 = WHITE, BackgroundTransparency = .92}, main)
local CPOS = UDim2.fromOffset(SB + 12, TOP + 8)
local content = new("CanvasGroup", {Position = CPOS, Size = UDim2.new(1, -SB - 18, 1, -TOP - 14), BackgroundTransparency = 1}, main)

local function setOpen(v)
	if opened == v then return end
	opened = v; openTok += 1
	local my = openTok
	if v then
		main.Visible = true
		tw(blur, {Size = blurOn and 14 or 0}, .5)
		mscale.Scale = baseScale * .86
		tw(main, {GroupTransparency = baseGT}, .28)
		tw(mscale, {Scale = baseScale}, .5, EASE.Back)
	else
		tw(main, {GroupTransparency = 1}, .2)
		tw(blur, {Size = 0}, .3)
		tw(mscale, {Scale = baseScale * .86}, .2, EASE.Quad, DIR.In)
		task.delay(.22, function() if openTok == my then main.Visible = false end end)
	end
end

local function setCollapsed(v)
	collapsed = v
	colB.Text = v and "+" or "–"
	tw(main, {Size = v and UDim2.new(1, 0, 0, TOP) or UDim2.fromScale(1, 1)}, .45, EASE.Quint)
end
cn(closeB.Activated, function() setOpen(false) end)
cn(colB.Activated, function() setCollapsed(not collapsed) end)

local fab = new("TextButton", {Text = "A", Font = Enum.Font.GothamBlack, TextSize = 20, TextColor3 = WHITE,
	AutoButtonColor = false, Size = UDim2.fromOffset(46, 46), Position = UDim2.new(0, 14, .5, -23)}, gui)
round(fab, 23); acc(fab, "BackgroundColor3"); press(fab, true)
local fs = stroke(fab, 2, accent, .5); acc(fs, "Color")
TS:Create(fs, TweenInfo.new(1.4, EASE.Sine, DIR.InOut, -1, true), {Thickness = 6, Transparency = .9}):Play()
local fabDrag = drag(fab, fab, function(W, H) return 0, W - 46, 0, H - 46 end)
cn(fab.Activated, function()
	if fabDrag.moved then return end
	setOpen(not opened)
	tw(fab, {Rotation = fab.Rotation + 360}, .7, EASE.Back)
end)

local cols = {Color3.fromRGB(130, 100, 255), Color3.fromRGB(0, 200, 255), Color3.fromRGB(255, 85, 150),
	Color3.fromRGB(60, 220, 130), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 75, 85)}
local swb = {}
local function mark(idx)
	for k, b in pairs(swb) do tw(b.S, {Transparency = k == idx and 0 or 1}, .25) end
end
local function setAccent(col, idx, instant)
	accent = col
	cfg.accent = {col.R, col.G, col.B}
	for _, f in ipairs(reg) do f(instant) end
	mark(idx)
end

local function card(p, h)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = C.card}, p)
	round(f, 8)
	return f, stroke(f, 1, WHITE, .93)
end

local function hov(b, f, st)
	cn(b.MouseEnter, function() tw(st, {Transparency = .75}, .2); tw(f, {BackgroundColor3 = C.card:Lerp(WHITE, .035)}, .2) end)
	cn(b.MouseLeave, function() tw(st, {Transparency = .93}, .25); tw(f, {BackgroundColor3 = C.card}, .25) end)
end

local function section(p, text)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1}, p)
	local bar = new("Frame", {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 1, .5, 1), Size = UDim2.fromOffset(3, 10)}, f)
	round(bar, 2); acc(bar, "BackgroundColor3")
	lbl(f, text, 11, C.sub, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -10, 1, 0), Font = Enum.Font.GothamBold})
	return f
end

local function row(p, h)
	local f = new("Frame", {Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1}, p)
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6)}, f)
	return f
end

local function button(p, text, cb, primary, size)
	local b = new("TextButton", {Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.text, AutoButtonColor = false,
		BackgroundColor3 = C.card2, Size = size or UDim2.new(1, 0, 0, 32)}, p)
	bind(b, text)
	round(b, 8); press(b)
	if primary then acc(b, "BackgroundColor3") end
	if cb then cn(b.Activated, cb) end
	return b
end

local function toggle(p, text, def, cb, key)
	local f, st = card(p, 36)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(1, -60, 1, 0)})
	local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1)}, f)
	local fromCfg = key and cfg[key] ~= nil
	local on = def and true or false
	if fromCfg then on = cfg[key] and true or false end
	local sw = new("Frame", {AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -10, .5, 0), Size = UDim2.fromOffset(38, 20)}, f)
	round(sw, 10)
	acc(sw, "BackgroundColor3", function() return on and accent or C.off end)
	local knob = new("Frame", {BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0, .5), Size = UDim2.fromOffset(14, 14), Position = UDim2.new(0, 3, .5, 0)}, sw)
	round(knob, 7)
	local held = false
	local function place(fast)
		local w = held and 18 or 14
		local props = {Size = UDim2.fromOffset(w, 14), Position = UDim2.new(0, on and 35 - w or 3, .5, 0)}
		if fast then for k, v in pairs(props) do knob[k] = v end else tw(knob, props, .3, EASE.Back) end
	end
	place(true)
	local obj = {}
	function obj.Set(v, silent)
		on = v and true or false
		if key then cfg[key] = on end
		tw(sw, {BackgroundColor3 = on and accent or C.off}, .2)
		place()
		if not silent and cb then cb(on) end
	end
	cn(b.InputBegan, function(i) if isPress(i) then held = true; place() end end)
	cn(b.InputEnded, function(i) if isPress(i) then held = false; place() end end)
	cn(b.Activated, function() obj.Set(not on) end)
	hov(b, f, st)
	if key then ctl[key] = obj; cfg[key] = on end
	if fromCfg and cb then cb(on) end
	return obj
end

local function slider(p, text, min, max, def, fmt, cb, step, key, commit)
	local f, st = card(p, 50)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 5), Size = UDim2.new(1, -90, 0, 20)})
	local val = lbl(f, "", 12, C.sub, {AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 5),
		Size = UDim2.fromOffset(76, 20), TextXAlignment = Enum.TextXAlignment.Right})
	local hit = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
		Position = UDim2.fromOffset(0, 26), Size = UDim2.new(1, 0, 0, 24)}, f)
	local track = new("Frame", {BackgroundColor3 = C.card2, AnchorPoint = Vector2.new(0, .5),
		Position = UDim2.new(0, 10, .5, 0), Size = UDim2.new(1, -20, 0, 6)}, hit)
	round(track, 3)
	local fill = new("Frame", {BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1)}, track)
	round(fill, 3)
	grad(fill, function() return ColorSequence.new(accent:Lerp(Color3.new(0, 0, 0), .3), accent) end)
	local knob = new("Frame", {BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(.5, .5), Size = UDim2.fromOffset(14, 14),
		Position = UDim2.fromScale(0, .5), ZIndex = 2}, track)
	round(knob, 7)
	local ks = stroke(knob, 0, accent, .55); acc(ks, "Color")
	local fromCfg = key and cfg[key] ~= nil
	if fromCfg then def = cfg[key] end
	local obj = {Label = val, Dragging = false}
	local cur = def
	local function set(v, silent, instant)
		v = math.clamp(v, min, max)
		if step then v = math.floor(v / step + .5) * step end
		cur = v
		if key then cfg[key] = v end
		local a = (v - min) / (max - min)
		if instant then
			fill.Size = UDim2.fromScale(a, 1); knob.Position = UDim2.fromScale(a, .5)
		else
			tw(fill, {Size = UDim2.fromScale(a, 1)}, .12, EASE.Quad)
			tw(knob, {Position = UDim2.fromScale(a, .5)}, .12, EASE.Quad)
		end
		local s = fmt and fmt(v) or tostring(v)
		if val.Text ~= s then val.Text = s end
		if not silent and cb and not (commit and obj.Dragging) then cb(v) end
	end
	local function fromX(x)
		set(min + (max - min) * math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1))
	end
	cn(hit.InputBegan, function(i)
		if not isPress(i) then return end
		obj.Dragging = true
		local sf = f:FindFirstAncestorOfClass("ScrollingFrame")
		if sf then sf.ScrollingEnabled = false end
		fromX(i.Position.X)
		tw(knob, {Size = UDim2.fromOffset(19, 19)}, .15); tw(ks, {Thickness = 5}, .2); tw(val, {TextColor3 = accent}, .15)
		local conn
		conn = UIS.InputChanged:Connect(function(c)
			if c == i or c.UserInputType == Enum.UserInputType.MouseMovement then fromX(c.Position.X) end
		end)
		i.Changed:Connect(function()
			if i.UserInputState == Enum.UserInputState.End then
				conn:Disconnect(); obj.Dragging = false
				if sf then sf.ScrollingEnabled = true end
				if commit and cb then cb(cur) end
				tw(knob, {Size = UDim2.fromOffset(14, 14)}, .25, EASE.Back); tw(ks, {Thickness = 0}, .3); tw(val, {TextColor3 = C.sub}, .3)
			end
		end)
	end)
	hov(hit, f, st)
	obj.Set = set
	function obj.Refresh() set(cur, true, true) end
	set(def, not fromCfg, true)
	if key then ctl[key] = obj end
	return obj
end

local function segment(p, text, opts, cb, def, key)
	local f, st = card(p, 36)
	lbl(f, text, 13, nil, {Position = UDim2.fromOffset(10, 0), Size = UDim2.new(.34, -10, 1, 0)})
	local seg = new("Frame", {BackgroundColor3 = C.card2, AnchorPoint = Vector2.new(1, .5), Position = UDim2.new(1, -8, .5, 0), Size = UDim2.new(.66, -12, 0, 24)}, f)
	round(seg, 6)
	local n = #opts
	local ind = new("Frame", {Size = UDim2.new(1 / n, -4, 1, -4), Position = UDim2.new(0, 2, 0, 2)}, seg)
	round(ind, 5); acc(ind, "BackgroundColor3")
	local btns, cur = {}, 1
	local obj = {}
	function obj.Set(i, silent, fast)
		i = math.clamp(math.floor(i + .5), 1, n)
		cur = i
		if key then cfg[key] = i end
		local pos = UDim2.new((i - 1) / n, 2, 0, 2)
		if fast then ind.Position = pos else tw(ind, {Position = pos}, .35, EASE.Back) end
		for k, b in ipairs(btns) do
			local c = k == i and WHITE or C.sub
			if fast then b.TextColor3 = c else tw(b, {TextColor3 = c}, .2) end
		end
		if not silent and cb then cb(i) end
	end
	for k, o in ipairs(opts) do
		local b = new("TextButton", {Font = Enum.Font.GothamBold, TextSize = n > 2 and 10 or 11, TextColor3 = C.sub, BackgroundTransparency = 1,
			AutoButtonColor = false, Position = UDim2.fromScale((k - 1) / n, 0), Size = UDim2.fromScale(1 / n, 1), ZIndex = 2}, seg)
		bind(b, o)
		btns[k] = b
		cn(b.Activated, function() if cur ~= k then obj.Set(k) end end)
		cn(b.MouseEnter, function() tw(st, {Transparency = .75}, .2) end)
		cn(b.MouseLeave, function() tw(st, {Transparency = .93}, .25) end)
	end
	local fromCfg = key and cfg[key] ~= nil
	obj.Set(fromCfg and cfg[key] or def or 1, not fromCfg, true)
	if key then ctl[key] = obj end
	return obj
end

local pages, order = {}, {"Музыка", "Эффекты", "Визуал", "Разное", "Настройки"}
local function page(name)
	local p = new("ScrollingFrame", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ScrollBarThickness = 3,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollingDirection = Enum.ScrollingDirection.Y,
		Visible = false, ScrollBarImageTransparency = .3}, content)
	new("UIListLayout", {Padding = UDim.new(0, 6)}, p)
	new("UIPadding", {PaddingRight = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6), PaddingTop = UDim.new(0, 2)}, p)
	acc(p, "ScrollBarImageColor3")
	pages[name] = p
	return p
end

local function fmtT(s) s = math.floor(s); return string.format("%d:%02d", s // 60, s % 60) end

local sound = new("Sound", {Name = "AuraSound", Volume = 1}, SoundService)
local pitch = new("PitchShiftSoundEffect", {Octave = 1, Enabled = false}, sound)
local eq = new("EqualizerSoundEffect", {LowGain = 0, MidGain = 0, HighGain = 0}, sound)
local reverb = new("ReverbSoundEffect", {Enabled = false, DecayTime = 2.8, DryLevel = -2, WetLevel = -4}, sound)
local echo = new("EchoSoundEffect", {Enabled = false, Delay = .35, Feedback = .45, DryLevel = 0, WetLevel = -6}, sound)

local S = {speed = 1, semi = 0, tape = true, db = 0}
local function applyAudio()
	sound.PlaybackSpeed = S.speed
	local target = 2 ^ (S.semi / 12) * (S.tape and S.speed or 1)
	local oct = math.clamp(target / S.speed, .5, 2)
	pitch.Octave = oct
	pitch.Enabled = math.abs(oct - 1) > .001
	sound.Volume = math.min(10 ^ (S.db / 20), 10)
end

local nameL, statusL, histBox, box, play
local history, playTok = {}, 0
local touched, trackOK, endedF = false, false, false
local function setStatus(t, col)
	statusL.Text = t
	tw(statusL, {TextColor3 = col or C.sub}, .25)
end
local function idle()
	if touched then return end
	nameL.Text = T("Ничего не играет")
	setStatus(T("Введите ID и нажмите «Играть»"))
end

local function addHistory(id)
	local i = table.find(history, id); if i then table.remove(history, i) end
	table.insert(history, 1, id); if #history > 3 then table.remove(history) end
	for _, c in ipairs(histBox:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
	for _, v in ipairs(history) do
		local b = new("TextButton", {Text = v, Font = Enum.Font.GothamMedium, TextSize = 11, TextColor3 = C.text,
			AutoButtonColor = false, BackgroundColor3 = C.card, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0)}, histBox)
		round(b, 6); press(b)
		stroke(b, 1, WHITE, .9)
		new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)}, b)
		local sc = b:FindFirstChild("Pop")
		sc.Scale = .6
		tw(sc, {Scale = 1}, .45, EASE.Back)
		cn(b.Activated, function() box.Text = v; play(v) end)
	end
	histBox.Visible = true
end

function play(raw)
	local id = tostring(raw or ""):match("%d+")
	if not id then setStatus(T("Введите числовой ID"), C.bad) return end
	touched, trackOK, endedF = true, false, false
	playTok += 1
	local my = playTok
	sound:Stop()
	sound.SoundId = "rbxassetid://" .. id
	applyAudio()
	sound:Play()
	nameL.Text = id
	setStatus(T("Загрузка..."))
	local t0 = os.clock()
	while my == playTok and not sound.IsLoaded and os.clock() - t0 < 8 do task.wait(.1) end
	if my ~= playTok then return end
	if sound.IsLoaded and sound.TimeLength > 0 then
		local ok, info = pcall(function() return MPS:GetProductInfo(tonumber(id)) end)
		if my ~= playTok then return end
		nameL.Text = (ok and info and info.Name) or id
		trackOK = true
		toast("Трек загружен", C.good)
		addHistory(id)
	else
		sound:Stop()
		nameL.Text = T("Ошибка")
		setStatus(T("Не загрузилось: ID закрыт или неверный"), C.bad)
		toast("Не удалось загрузить ID", C.bad)
	end
end

local V = {hl = true, skel = false, names = true, dist = false, range = 250, style = 1, fps = false}
local esp = {}
local espAny, espWas = true, false
local function refresh() espAny = V.hl or V.skel or V.names or V.dist end

local function mkLine()
	return new("Frame", {AnchorPoint = Vector2.new(.5, .5), BackgroundColor3 = accent, Visible = false}, skelLayer)
end
local function mkTag()
	return new("TextLabel", {AnchorPoint = Vector2.new(.5, 1), Size = UDim2.fromOffset(160, 32), BackgroundTransparency = 1, Text = "",
		Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = WHITE, TextStrokeTransparency = .35, TextStrokeColor3 = Color3.new(0, 0, 0),
		TextYAlignment = Enum.TextYAlignment.Bottom, Visible = false}, skelLayer)
end

local function buildBones(e, char)
	local motors = {}
	for _, d in ipairs(char:GetDescendants()) do
		if d:IsA("Motor6D") and d.Part0 and d.Part1 then motors[#motors + 1] = d end
	end
	local bones = {}
	for _, m in ipairs(motors) do
		local kids = false
		for _, n in ipairs(motors) do
			if n.Part0 == m.Part1 then kids = true; bones[#bones + 1] = {m, n} end
		end
		if not kids then bones[#bones + 1] = {m} end
	end
	e.bones = bones
	while #e.lines < #bones do e.lines[#e.lines + 1] = mkLine() end
end

local function drawSkel(e, cam, vs)
	e.lv = true
	for k, l in ipairs(e.lines) do
		local bn = e.bones[k]
		local ok = false
		if bn then
			local m, n = bn[1], bn[2]
			local p0, p1 = m.Part0, m.Part1
			if p0 and p1 then
				local a = (p0.CFrame * m.C0).Position
				local b
				if n and n.Part0 then
					b = (n.Part0.CFrame * n.C0).Position
				else
					local c = p1.Position
					b = p1.Name == "Head" and c or c * 2 - a
				end
				local pa = cam:WorldToViewportPoint(a)
				local pb = cam:WorldToViewportPoint(b)
				if pa.Z > 0 and pb.Z > 0 then
					local dx, dy = pb.X - pa.X, pb.Y - pa.Y
					l.Position = UDim2.fromScale((pa.X + pb.X) / 2 / vs.X, (pa.Y + pb.Y) / 2 / vs.Y)
					l.Size = UDim2.fromOffset(math.sqrt(dx * dx + dy * dy), 2)
					l.Rotation = math.deg(math.atan2(dy, dx))
					l.BackgroundColor3 = accent
					ok = true
				end
			end
		end
		l.Visible = ok
	end
end

local function updateESP(t)
	local cam = workspace.CurrentCamera
	if not cam then return end
	local vs = cam.ViewportSize
	local myc = lp.Character
	local mh = myc and myc:FindFirstChild("HumanoidRootPart")
	local origin = mh and mh.Position or cam.CFrame.Position
	for plr, e in pairs(esp) do
		local char = plr.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local d = hrp and (hrp.Position - origin).Magnitude or math.huge
		local alive = hrp ~= nil and hum ~= nil and hum.Health > 0 and d <= V.range
		local hl = e.hl
		if e.char ~= char then
			e.char = char
			hl.Adornee = char
			hl.Parent = char
		end
		local showHl = V.hl and alive
		hl.Enabled = showHl
		if showHl then
			if V.style == 1 then
				hl.FillColor = accent; hl.OutlineColor = accent
				hl.FillTransparency = 1; hl.OutlineTransparency = 0
			elseif V.style == 2 then
				hl.FillColor = accent; hl.OutlineColor = WHITE
				hl.FillTransparency = .45; hl.OutlineTransparency = .2
			else
				local k = (math.sin(t * 2.4 + e.ph) + 1) / 2
				hl.FillColor = accent:Lerp(shift(accent), k); hl.OutlineColor = shift(accent):Lerp(accent, k)
				hl.FillTransparency = .5; hl.OutlineTransparency = .1
			end
		end
		local sk = V.skel and alive
		if sk and (e.bchar ~= char or t - e.bt > (#e.bones < 8 and .5 or 3)) then
			e.bchar, e.bt = char, t
			buildBones(e, char)
		end
		if sk then
			drawSkel(e, cam, vs)
		elseif e.lv then
			for _, l in ipairs(e.lines) do l.Visible = false end
			e.lv = false
		end
		local tag = e.tag
		if alive and (V.names or V.dist) then
			local head = char:FindFirstChild("Head") or hrp
			local pt = cam:WorldToViewportPoint(head.Position + Vector3.new(0, head.Size.Y / 2 + .6, 0))
			if pt.Z > 0 then
				local s = V.names and plr.DisplayName or ""
				if V.dist then s = (s ~= "" and s .. "\n" or "") .. string.format("%d %s", math.floor(d), T("ст.")) end
				tag.Text = s
				tag.Position = UDim2.fromScale(pt.X / vs.X, pt.Y / vs.Y)
				tag.Visible = true
			else
				tag.Visible = false
			end
		else
			tag.Visible = false
		end
	end
end

local function attach(plr)
	if plr == lp or esp[plr] then return end
	local hl = new("Highlight", {Name = "AuraHL", DepthMode = Enum.HighlightDepthMode.AlwaysOnTop, Enabled = false,
		FillTransparency = 1, OutlineTransparency = 1})
	esp[plr] = {hl = hl, tag = mkTag(), lines = {}, bones = {}, bt = 0, ph = math.random() * 6, lv = false}
end
local function detach(plr)
	local e = esp[plr]
	if not e then return end
	e.hl:Destroy(); e.tag:Destroy()
	for _, l in ipairs(e.lines) do l:Destroy() end
	esp[plr] = nil
end
for _, p in ipairs(Players:GetPlayers()) do attach(p) end
cn(Players.PlayerAdded, attach)
cn(Players.PlayerRemoving, detach)

local afkOn, rejoinOn, rejoining = true, false, false
local fovT, fovOn = (workspace.CurrentCamera and workspace.CurrentCamera.FieldOfView) or 70, false
cn(lp.Idled, function()
	if afkOn and okVU and VU then
		pcall(function() VU:CaptureController(); VU:ClickButton2(Vector2.new()) end)
	end
end)
local function rejoin()
	if not rejoinOn or rejoining then return end
	rejoining = true
	toast("Переподключение...")
	task.wait(1)
	local ok = pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, lp) end)
	if not ok then pcall(function() TeleportService:Teleport(game.PlaceId, lp) end) end
	task.delay(8, function() rejoining = false end)
end
cn(GuiService.ErrorMessageChanged, function()
	local ok, m = pcall(function() return GuiService:GetErrorMessage() end)
	if rejoinOn and (not ok or m ~= "") then task.spawn(rejoin) end
end)
cn(TeleportService.TeleportInitFailed, function()
	if rejoinOn then task.delay(2, function() pcall(function() TeleportService:Teleport(game.PlaceId, lp) end) end) end
end)

local fpsF = new("Frame", {Size = UDim2.fromOffset(112, 26), Position = UDim2.new(1, -122, 0, 10), BackgroundColor3 = C.bar, Visible = false, ZIndex = 15}, gui)
round(fpsF, 13); stroke(fpsF, 1, WHITE, .85)
local fpsS = new("UIScale", {Scale = .01}, fpsF)
local fpsD = new("Frame", {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 10, .5, 0), Size = UDim2.fromOffset(8, 8), BackgroundColor3 = C.good, ZIndex = 16}, fpsF)
round(fpsD, 4)
local fpsL = new("TextLabel", {BackgroundTransparency = 1, Position = UDim2.fromOffset(24, 0), Size = UDim2.new(1, -28, 1, 0), Font = Enum.Font.GothamBold,
	TextSize = 12, TextColor3 = C.text, TextXAlignment = Enum.TextXAlignment.Left, Text = "", ZIndex = 16}, fpsF)
drag(fpsF, fpsF, function(W, H) return 0, W - 112, 0, H - 26 end)
local function showFps(v)
	if v then
		fpsF.Visible = true
		tw(fpsS, {Scale = 1}, .45, EASE.Back)
	else
		tw(fpsS, {Scale = .01}, .25, EASE.Quad, DIR.In)
		task.delay(.27, function() if not V.fps then fpsF.Visible = false end end)
	end
end
local fpsA, fpsN = 0, 0

local function unload()
	pcall(function() RS:UnbindFromRenderStep("AuraMenuLoop") end)
	for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
	for plr in pairs(esp) do detach(plr) end
	if blur then blur:Destroy() end
	sound:Destroy()
	gui:Destroy()
	genv.AuraUnload = nil
end
genv.AuraUnload = unload

local spd, tapeT, semi, vol, bassS, midS, trebS, reverbT, echoT, prog, pauseB
local function resetAll()
	spd.Set(1); tapeT.Set(true); semi.Set(0); vol.Set(0)
	bassS.Set(0); midS.Set(0); trebS.Set(0); reverbT.Set(false); echoT.Set(false)
end
local function dbfmt(v) return string.format("%+.0f dB", v) end

local pg = page("Музыка")
section(pg, "ПЛЕЕР")
local idc = card(pg, 42)
box = new("TextBox", {Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 13, TextColor3 = C.text,
	PlaceholderColor3 = C.sub, BackgroundColor3 = C.card2, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	Position = UDim2.fromOffset(6, 6), Size = UDim2.new(1, -94, 1, -12)}, idc)
bind(box, "Вставьте ID песни", "PlaceholderText")
round(box, 6); new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, box)
local bs = stroke(box, 1.5, accent, 1); acc(bs, "Color")
cn(box.Focused, function() tw(bs, {Transparency = 0}, .2) end)
cn(box.FocusLost, function(enter)
	tw(bs, {Transparency = 1}, .25)
	box.Text = box.Text:match("%d+") or ""
	if enter then play(box.Text) end
end)
cn(box:GetPropertyChangedSignal("Text"), function()
	local s = box.Text:match("%d+") or ""
	if s ~= box.Text then box.Text = s end
end)
local go = button(idc, "Играть", function() play(box.Text) end, true, UDim2.new(0, 76, 1, -12))
go.Position = UDim2.new(1, -82, 0, 6)

local searchCard = card(pg, 42)
local searchBox = new("TextBox", {Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamMedium, TextSize = 12,
	TextColor3 = C.text, PlaceholderColor3 = C.sub, PlaceholderText = "Поиск песни по названию", BackgroundColor3 = C.card2,
	TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, Position = UDim2.fromOffset(6, 6),
	Size = UDim2.new(1, -94, 1, -12)}, searchCard)
round(searchBox, 6)
new("UIPadding", {PaddingLeft = UDim.new(0, 8)}, searchBox)
local searchBtn = button(searchCard, "Найти", nil, true, UDim2.new(0, 76, 1, -12))
searchBtn.Position = UDim2.new(1, -82, 0, 6)
local searchResults = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 1, Visible = false}, pg)
new("UIListLayout", {Padding = UDim.new(0, 4)}, searchResults)
local searchBusy = false
local function searchSongs()
	local query = searchBox.Text:gsub("^%s+", ""):gsub("%s+$", "")
	if #query < 2 then toast("Введите название песни", C.bad); return end
	if searchBusy then return end
	local requester = request or http_request or (syn and syn.request)
	if type(requester) ~= "function" then
		toast("Поиск требует HTTP-запросы в исполнителе", C.bad)
		return
	end
	searchBusy = true
	searchBtn.Text = "..."
	for _, child in ipairs(searchResults:GetChildren()) do
		if child:IsA("GuiObject") and not child:IsA("UIListLayout") then child:Destroy() end
	end
	searchResults.Visible = true
	task.spawn(function()
		local url = "https://catalog.roblox.com/v1/search/items/details?Category=Audio&Keyword=" .. HttpService:UrlEncode(query) .. "&Limit=10&SortType=3"
		local ok, response = pcall(function() return requester({Url = url, Method = "GET"}) end)
		local body
		if ok and type(response) == "table" and (response.StatusCode == 200 or response.StatusCode == 0 or response.StatusCode == nil) then
			local decodedOk, decoded = pcall(function() return HttpService:JSONDecode(response.Body or response.body or "") end)
			if decodedOk and type(decoded) == "table" then body = decoded end
		end
		if not body or type(body.data) ~= "table" then
			local msg = new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30),
				Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, Text = "Ничего не найдено или поиск недоступен"}, searchResults)
		else
			local count = 0
			for _, item in ipairs(body.data) do
				local id = item.id or item.assetId
				local titleText = tostring(item.name or "Без названия")
				if id and count < 8 then
					count += 1
					local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = C.card,
						Size = UDim2.new(1, 0, 0, 32)}, searchResults)
					round(b, 7)
					stroke(b, 1, WHITE, .94)
					lbl(b, titleText, 11, C.text, {Position = UDim2.fromOffset(9, 0), Size = UDim2.new(1, -76, 1, 0)})
					lbl(b, tostring(id), 10, C.sub, {Position = UDim2.new(1, -66, 0, 0), Size = UDim2.fromOffset(58, 32),
						TextXAlignment = Enum.TextXAlignment.Right})
					press(b, true)
					cn(b.Activated, function() box.Text = tostring(id); play(tostring(id)) end)
				end
			end
			if count == 0 then
				new("TextLabel", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30),
					Font = Enum.Font.Gotham, TextSize = 11, TextColor3 = C.sub, Text = "Нет доступных аудио по этому запросу"}, searchResults)
			end
		end
		searchBusy = false
		if searchBtn.Parent then searchBtn.Text = T("Найти") end
	end)
end
cn(searchBtn.Activated, searchSongs)
cn(searchBox.FocusLost, function(enter) if enter then searchSongs() end end)

local np = card(pg, 60)
local vinyl = new("Frame", {AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 10, .5, 0), Size = UDim2.fromOffset(44, 44),
	BackgroundColor3 = WHITE}, np)
round(vinyl, 22)
local vs = stroke(vinyl, 2, accent, .4); acc(vs, "Color")
local hi, lo2 = Color3.fromRGB(95, 95, 118), Color3.fromRGB(22, 22, 30)
new("UIGradient", {Rotation = 35, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, hi), ColorSequenceKeypoint.new(.25, lo2),
	ColorSequenceKeypoint.new(.5, hi), ColorSequenceKeypoint.new(.75, lo2), ColorSequenceKeypoint.new(1, hi)})}, vinyl)
for _, d in ipairs({36, 28}) do
	local g = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(d, d), BackgroundTransparency = 1}, vinyl)
	round(g, d / 2); stroke(g, 1, WHITE, .88)
end
local vlab = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(16, 16)}, vinyl)
round(vlab, 8); acc(vlab, "BackgroundColor3")
local vhole = new("Frame", {AnchorPoint = Vector2.new(.5, .5), Position = UDim2.fromScale(.5, .5), Size = UDim2.fromOffset(4, 4), BackgroundColor3 = C.card}, vlab)
round(vhole, 2)
nameL = lbl(np, "", 13, nil, {Position = UDim2.fromOffset(64, 10), Size = UDim2.new(1, -74, 0, 18), Font = Enum.Font.GothamBold})
statusL = lbl(np, "", 11, C.sub, {Position = UDim2.fromOffset(64, 30), Size = UDim2.new(1, -74, 0, 16)})
trReg[#trReg + 1] = idle
idle()

histBox = new("Frame", {Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Visible = false}, pg)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 5)}, histBox)

local vc = card(pg, 56)
local bars = {}
for n = 1, 28 do
	local b = new("Frame", {BackgroundColor3 = WHITE, AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((n - 1) / 28, 2, 1, -6), Size = UDim2.new(1 / 28, -3, 0, 3)}, vc)
	round(b, 2)
	grad(b, function() return ColorSequence.new(light(accent):Lerp(accent, .4), accent) end, {Rotation = 90})
	local cap = new("Frame", {AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((n - 1) / 28, 2, 1, -11), Size = UDim2.new(1 / 28, -3, 0, 2)}, vc)
	round(cap, 1); acc(cap, "BackgroundColor3")
	bars[n] = {f = b, c = cap, h = 0, p = 0}
end
prog = slider(pg, "Трек", 0, 1, 0, function(v)
	local l = sound.TimeLength
	return fmtT(v * l) .. " / " .. fmtT(l)
end, function(v)
	if sound.TimeLength > 0 then sound.TimePosition = v * sound.TimeLength end
end, nil, nil, true)
local r = row(pg, 32)
local q = UDim2.new(.25, -5, 1, 0)
button(r, "-10с", function() sound.TimePosition = math.max(0, sound.TimePosition - 10) end, false, q)
pauseB = button(r, "Пауза", function()
	if sound.IsPlaying then sound:Pause()
	elseif sound.IsPaused then sound:Resume()
	elseif sound.SoundId ~= "" then endedF = false; sound:Play() end
end, true, q)
button(r, "Стоп", function()
	playTok += 1
	sound:Stop()
	if not trackOK and touched then setStatus(T("Остановлено")) end
end, false, q)
button(r, "+10с", function() sound.TimePosition = math.min(sound.TimeLength, sound.TimePosition + 10) end, false, q)
toggle(pg, "Повтор трека", false, function(v) sound.Looped = v end, "loop")

section(pg, "СКОРОСТЬ И ТОНАЛЬНОСТЬ")
spd = slider(pg, "Скорость", .25, 3, 1, function(v) return string.format("%.2fx", v) end, function(v) S.speed = v; applyAudio() end, .05, "speed")
tapeT = toggle(pg, "Менять тон со скоростью", true, function(v) S.tape = v; applyAudio() end, "tape")
semi = slider(pg, "Тональность", -12, 12, 0, function(v) return string.format("%+.0f %s", v, T("пт")) end, function(v) S.semi = v; applyAudio() end, 1, "semi")
section(pg, "ГРОМКОСТЬ")
vol = slider(pg, "Усиление", -40, 20, 0, dbfmt, function(v) S.db = v; applyAudio() end, 1, "db")
button(pg, "Сбросить всё", resetAll)

local pe = page("Эффекты")
local function preset(name, fn)
	return function() resetAll(); fn(); toast(T("Пресет: ") .. name) end
end
section(pe, "ПРЕСЕТЫ")
local pr = row(pe, 30)
button(pr, "Night", preset("Night", function() spd.Set(1.25); tapeT.Set(true) end), false, q)
button(pr, "Slowed", preset("Slowed", function() spd.Set(.85); tapeT.Set(true); reverbT.Set(true) end), false, q)
button(pr, "Bass", preset("Bass", function() bassS.Set(10); midS.Set(-3); trebS.Set(2) end), false, q)
button(pr, "Сброс", function() resetAll(); toast("Всё сброшено") end, false, q)
section(pe, "ЭКВАЛАЙЗЕР")
bassS = slider(pe, "Низкие", -20, 10, 0, dbfmt, function(v) eq.LowGain = v end, 1, "bass")
midS = slider(pe, "Средние", -20, 10, 0, dbfmt, function(v) eq.MidGain = v end, 1, "mid")
trebS = slider(pe, "Высокие", -20, 10, 0, dbfmt, function(v) eq.HighGain = v end, 1, "treb")
section(pe, "ПРОСТРАНСТВО")
reverbT = toggle(pe, "Реверберация", false, function(v) reverb.Enabled = v end, "reverb")
echoT = toggle(pe, "Эхо", false, function(v) echo.Enabled = v end, "echo")

local pv = page("Визуал")
section(pv, "ОТОБРАЖЕНИЕ")
toggle(pv, "Подсветка игроков", true, function(v) V.hl = v; refresh() end, "hl")
toggle(pv, "Скелет", false, function(v) V.skel = v; refresh() end, "skel")
toggle(pv, "Имена", true, function(v) V.names = v; refresh() end, "names")
toggle(pv, "Дистанция", false, function(v) V.dist = v; refresh() end, "dist")
slider(pv, "Дальность", 50, 1000, 250, function(v) return string.format("%d %s", v, T("ст.")) end, function(v) V.range = v end, 10, "range")
segment(pv, "Стиль", {"Контур", "Заливка", "Градиент"}, function(i) V.style = i end, 1, "style")

local pm = page("Разное")
section(pm, "ОБЩЕЕ")
toggle(pm, "Анти-АФК", true, function(v) afkOn = v end, "afk")
toggle(pm, "Показывать FPS", false, function(v) V.fps = v; showFps(v) end, "fps")
toggle(pm, "Авто-перезаход", false, function(v) rejoinOn = v end, "rejoin")
slider(pm, "Поле зрения", 50, 120, 70, function(v) return string.format("%.0f°", v) end, function(v) fovT = v; fovOn = true end, 1, "fov")
segment(pm, "Язык", {"Русский", "English"}, setLang, 1, "lang")
local cr = row(pm, 32)
local half = UDim2.new(.5, -3, 1, 0)
button(cr, "Сохранить конфиг", function()
	local ok = saveCfg()
	toast(ok and "Конфиг сохранён" or "Сохранение недоступно", ok and C.good or C.bad)
end, true, half)
button(cr, "Загрузить конфиг", function()
	if loadCfg() then
		for k, o in pairs(ctl) do if cfg[k] ~= nil then o.Set(cfg[k]) end end
		rainbow = cfg.rainbow == true
		if rainbow then mark(7)
		elseif type(cfg.accent) == "table" and cfg.accent[3] then setAccent(Color3.new(cfg.accent[1], cfg.accent[2], cfg.accent[3]), 0) end
		toast("Конфиг загружен", C.good)
	else
		toast("Конфиг не найден", C.bad)
	end
end, false, half)

local ps = page("Настройки")
section(ps, "ЦВЕТ АКЦЕНТА")
local swc = card(ps, 46)
new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center,
	VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10)}, swc)
for k, col in ipairs(cols) do
	local b = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = col, Size = UDim2.fromOffset(26, 26)}, swc)
	round(b, 13); press(b, true)
	swb[k] = {S = stroke(b, 2, WHITE, 1)}
	cn(b.Activated, function() rainbow = false; cfg.rainbow = false; setAccent(col, k); toast("Акцент изменён") end)
end
local rb = new("TextButton", {Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(26, 26)}, swc)
round(rb, 13); press(rb, true)
new("UIGradient", {Rotation = 45, Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 80)),
	ColorSequenceKeypoint.new(.33, Color3.fromRGB(80, 255, 120)), ColorSequenceKeypoint.new(.66, Color3.fromRGB(80, 140, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 80, 200))})}, rb)
swb[7] = {S = stroke(rb, 2, WHITE, 1)}
cn(rb.Activated, function()
	rainbow = not rainbow
	cfg.rainbow = rainbow
	if rainbow then mark(7) else mark(0) end
	toast(rainbow and "Радужный режим" or "Радуга выключена")
end)
do
	local sel = 0
	for k, c in ipairs(cols) do
		if (c.R - accent.R) ^ 2 + (c.G - accent.G) ^ 2 + (c.B - accent.B) ^ 2 < 1e-4 then sel = k end
	end
	mark(rainbow and 7 or sel)
end
slider(ps, "Оттенок", 0, 360, (accent:ToHSV()) * 360, function(v) return string.format("%.0f°", v) end, function(v)
	rainbow = false; cfg.rainbow = false
	setAccent(Color3.fromHSV(v / 360, .65, 1), 0, true)
end, 1)
section(ps, "ОКНО")
slider(ps, "Прозрачность", 0, 50, 0, function(v) return string.format("%.0f%%", v) end, function(v)
	baseGT = v / 100
	if opened then tw(main, {GroupTransparency = baseGT}, .2) end
end, 1, "gt")
slider(ps, "Размер меню", 60, 130, baseScale * 100, function(v) return string.format("%.0f%%", v) end, function(v)
	baseScale = v / 100
	tw(mscale, {Scale = baseScale}, .25)
end, 5, "size")
toggle(ps, "Размытие фона", true, function(v)
	blurOn = v
	if opened then tw(blur, {Size = v and 14 or 0}, .3) end
end, "blur")
button(ps, "Сбросить позицию", function() tw(holder, {Position = startPos}, .6, EASE.Back) end)
button(ps, "Выгрузить меню", function() setOpen(false); task.delay(.4, unload) end)

local tabBtns, cur, tok = {}, nil, nil
local ind = new("Frame", {Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = .8}, side)
round(ind, 8); acc(ind, "BackgroundColor3")
local ibar = new("Frame", {Size = UDim2.new(0, 3, .6, 0), AnchorPoint = Vector2.new(0, .5), Position = UDim2.new(0, 4, .5, 0)}, ind)
round(ibar, 2); acc(ibar, "BackgroundColor3")

local function popIn(name)
	local n = 0
	for _, c in ipairs(pages[name]:GetChildren()) do
		if c:IsA("GuiObject") and c.Visible then
			n += 1
			if n > 9 then break end
			local sc = c:FindFirstChild("Pop") or new("UIScale", {Name = "Pop"}, c)
			sc.Scale = .85
			task.delay(n * .04, function() tw(sc, {Scale = 1}, .5, EASE.Back) end)
		end
	end
end

local function selectTab(name, instant)
	if cur == name then return end
	cur = name
	local my = {}
	tok = my
	for n, b in pairs(tabBtns) do tw(b, {TextColor3 = n == name and C.text or C.sub}, .25) end
	tw(ind, {Position = UDim2.fromOffset(0, (table.find(order, name) - 1) * 36)}, .4, EASE.Back)
	local function swap() for n, p in pairs(pages) do p.Visible = n == name end end
	if instant then swap(); popIn(name) return end
	task.spawn(function()
		tw(content, {GroupTransparency = 1, Position = CPOS + UDim2.fromOffset(0, 10)}, .12).Completed:Wait()
		if tok ~= my then return end
		swap()
		content.Position = CPOS - UDim2.fromOffset(0, 10); popIn(name)
		tw(content, {GroupTransparency = 0, Position = CPOS}, .3)
	end)
end

for i, name in ipairs(order) do
	local b = new("TextButton", {Font = Enum.Font.GothamBold, TextSize = 13, TextColor3 = C.sub, TextXAlignment = Enum.TextXAlignment.Left,
		BackgroundTransparency = 1, AutoButtonColor = false, Position = UDim2.fromOffset(0, (i - 1) * 36), Size = UDim2.new(1, 0, 0, 32)}, side)
	bind(b, name)
	new("UIPadding", {PaddingLeft = UDim.new(0, 16)}, b)
	tabBtns[name] = b
	cn(b.Activated, function() selectTab(name) end)
	cn(b.MouseEnter, function() if cur ~= name then tw(b, {TextColor3 = C.text:Lerp(C.sub, .45)}, .2) end end)
	cn(b.MouseLeave, function() tw(b, {TextColor3 = cur == name and C.text or C.sub}, .25) end)
end

cn(sound.Ended, function() if not sound.Looped then endedF = true end end)
cn(UIS.InputBegan, function(i, gp)
	if not gp and i.KeyCode == Enum.KeyCode.RightShift then setOpen(not opened) end
end)

local spinV = 0
RS:BindToRenderStep("AuraMenuLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local t = os.clock()
	if rainbow then
		hue = (hue + dt * .2) % 1
		accent = Color3.fromHSV(hue, .65, 1)
		for _, f in ipairs(reg) do f(true) end
	end
	if fovOn then
		local c = workspace.CurrentCamera
		if c then c.FieldOfView += (fovT - c.FieldOfView) * math.min(1, dt * 8) end
	end
	if espAny or espWas then updateESP(t) end
	espWas = espAny
	if V.fps then
		fpsA += dt; fpsN += 1
		if fpsA >= .4 then
			local f = math.floor(fpsN / fpsA + .5)
			fpsA, fpsN = 0, 0
			local ok, ping = pcall(function() return Stats.Network.ServerStatsItem["Data Ping"]:GetValue() end)
			fpsL.Text = f .. " FPS · " .. (ok and math.floor(ping + .5) .. " ms" or "-- ms")
			fpsD.BackgroundColor3 = f >= 50 and C.good or (f >= 30 and Color3.fromRGB(255, 190, 70) or C.bad)
		end
	end
	if not main.Visible then return end
	local playing = sound.IsPlaying
	local loud = math.clamp(sound.PlaybackLoudness / 350, 0, 1)
	for k, m in ipairs(mini) do
		local target = playing and 3 + (.5 + .5 * math.sin(t * (6 + k * 1.7) + k)) * 9 * (.4 + loud * .6) or 3
		m.h += (target - m.h) * .25
		m.f.Size = UDim2.fromOffset(4, math.floor(m.h + .5))
	end
	if not pages["Музыка"].Visible then return end
	for n, b in ipairs(bars) do
		local target = playing and loud * (.35 + .65 * math.abs(math.sin(t * 5 + n * .8) * math.cos(t * 2.3 + n * .37))) or 0
		b.h += (target - b.h) * .3
		b.p = math.max(b.h, b.p - dt * .8)
		b.f.Size = UDim2.new(1 / 28, -3, 0, 3 + b.h * 36)
		b.c.Position = UDim2.new((n - 1) / 28, 2, 1, -11 - b.p * 36)
	end
	spinV += ((playing and 150 or 0) - spinV) * math.min(1, dt * 3)
	vinyl.Rotation = (vinyl.Rotation + spinV * dt) % 360
	vs.Thickness = 2 + loud * 3
	local len = sound.TimeLength
	if not prog.Dragging then prog.Set(len > 0 and sound.TimePosition / len or 0, true, true) end
	local want = T(playing and "Пауза" or "Играть")
	if pauseB.Text ~= want then pauseB.Text = want end
	if trackOK then
		local s = playing and "Играет" or (sound.IsPaused and "На паузе" or (endedF and "Трек закончился" or "Остановлено"))
		s = T(s)
		if statusL.Text ~= s then setStatus(s, playing and C.good or C.sub) end
	end
end)

selectTab(order[1], true)
setOpen(true)
task.delay(.9, function() toast("AURA загружено") end)
