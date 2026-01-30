-- Next Bot Gui By Old Scripts

--------------------------------------------------
-- SERVICES
--------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local botsFolder = Workspace:WaitForChild("bots")

--------------------------------------------------
-- GUI (CoreGui)
--------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "BotToolsHub"
gui.ResetOnSpawn = false
gui.Parent = game.CoreGui

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.fromOffset(280, 240)
frame.Position = UDim2.fromScale(0.4, 0.3)
frame.BackgroundColor3 = Color3.fromRGB(25,25,30)
frame.BorderSizePixel = 0
frame.Active = true
frame.Draggable = true
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, -20, 0, 35)
title.Position = UDim2.fromOffset(10, 5)
title.BackgroundTransparency = 1
title.Text = "Nextbot Gui"
title.Font = Enum.Font.GothamBold
title.TextSize = 18
title.TextColor3 = Color3.new(1,1,1)
title.TextXAlignment = Enum.TextXAlignment.Left

--------------------------------------------------
-- BOTÕES
--------------------------------------------------
local function createButton(text, y, color)
	local b = Instance.new("TextButton", frame)
	b.Size = UDim2.new(1, -20, 0, 45)
	b.Position = UDim2.fromOffset(10, y)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 15
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = color
	b.BorderSizePixel = 0
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,10)
	return b
end

local espButton   = createButton("ATIVAR BOT ESP", 50, Color3.fromRGB(60,0,90))
local antiJumpBtn = createButton("ATIVAR ANTI JUMPSCARE", 105, Color3.fromRGB(90,170,255))
local antiBotBtn  = createButton("ATIVAR ANTI NEXTBOT TP", 160, Color3.fromRGB(255,170,60))

--------------------------------------------------
-- ================= BOT ESP REAL =================
--------------------------------------------------
local ESP_COLOR = Color3.fromRGB(170, 80, 255)
local ESP_TRANSPARENCY = 0.4
local espEnabled = false
local espCache = {}

local function createAnchor(model)
	local anchor = Instance.new("Part")
	anchor.Name = "_ESPAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1,1,1)
	anchor.Parent = model
	return anchor
end

local function addESP(model)
	if espCache[model] then return end

	local anchor = createAnchor(model)

	local box = Instance.new("BoxHandleAdornment")
	box.Adornee = anchor
	box.AlwaysOnTop = true
	box.ZIndex = 5
	box.Color3 = ESP_COLOR
	box.Transparency = ESP_TRANSPARENCY
	box.Parent = anchor

	espCache[model] = {anchor = anchor, box = box}
end

local function removeESP()
	for _,v in pairs(espCache) do
		if v.anchor then v.anchor:Destroy() end
	end
	table.clear(espCache)
end

RunService.RenderStepped:Connect(function()
	if not espEnabled then return end
	for model,data in pairs(espCache) do
		if model and model.Parent then
			local cf,size = model:GetBoundingBox()
			data.anchor.CFrame = cf
			data.box.Size = size
		else
			if data.anchor then data.anchor:Destroy() end
			espCache[model] = nil
		end
	end
end)

espButton.MouseButton1Click:Connect(function()
	espEnabled = not espEnabled
	if espEnabled then
		espButton.Text = "DESATIVAR BOT ESP"
		for _,bot in ipairs(botsFolder:GetChildren()) do
			if bot:IsA("Model") then addESP(bot) end
		end
	else
		espButton.Text = "ATIVAR BOT ESP"
		removeESP()
	end
end)

botsFolder.ChildAdded:Connect(function(bot)
	if espEnabled and bot:IsA("Model") then
		task.wait(0.1)
		addESP(bot)
	end
end)

--------------------------------------------------
-- ================= ANTI JUMPSCARE =================
--------------------------------------------------
local antiJumpEnabled = false
local antiJumpConn
local origJump, origScary

local function getBoolValues()
	local options = player.PlayerScripts:WaitForChild("options")
	return options:WaitForChild("jumpscare"), options:WaitForChild("scary")
end

antiJumpBtn.MouseButton1Click:Connect(function()
	antiJumpEnabled = not antiJumpEnabled
	local jumpscare, scary = getBoolValues()

	if antiJumpEnabled then
		origJump, origScary = jumpscare.Value, scary.Value
		jumpscare.Value = false
		scary.Value = false

		antiJumpConn = RunService.Heartbeat:Connect(function()
			jumpscare.Value = false
			scary.Value = false
		end)

		antiJumpBtn.Text = "DESATIVAR ANTI JUMPSCARE"
	else
		if antiJumpConn then antiJumpConn:Disconnect() antiJumpConn = nil end
		jumpscare.Value = origJump
		scary.Value = origScary
		antiJumpBtn.Text = "ATIVAR ANTI JUMPSCARE"
	end
end)

--------------------------------------------------
-- ================= ANTI NEXTBOT TP (CORRIGIDO) =================
--------------------------------------------------
local antiBotEnabled = false
local antiBotConn
local lastTeleport = 0
local lastCheck = 0

local CONFIG = {
	DetectDistance = 26,
	AlertDistance = 30,
	PredictionTime = 0.6,
	TeleportCooldown = 0.01,
	SpeedThreat = 30,
	HeadingThreshold = 0.85,
	CheckInterval = 0.01,
}

local SafePositions = {
	CFrame.new(204.66, 20.89, 825.06),
	CFrame.new(-70.41, 37.14, 366.63),
	CFrame.new(-96.56, 19.04, -12.55),
	CFrame.new(96.42, 103.54, 330.09),
	CFrame.new(-299.98, 36.64, 58.24),
}

local function getHRP()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function teleportSafe()
	if tick() - lastTeleport < CONFIG.TeleportCooldown then return end
	local hrp = getHRP()
	if not hrp then return end
	lastTeleport = tick()
	hrp.CFrame = SafePositions[math.random(#SafePositions)] + Vector3.new(0,5,0)
end

local function detectBots()
	local now = tick()
	if now - lastCheck < CONFIG.CheckInterval then return end
	lastCheck = now

	local hrp = getHRP()
	if not hrp then return end
	local playerPos = hrp.Position

	for _,bot in ipairs(botsFolder:GetChildren()) do
		local bhrp = bot:FindFirstChild("HumanoidRootPart")
		if bhrp then
			local dist = (bhrp.Position - playerPos).Magnitude
			if dist <= CONFIG.DetectDistance then
				teleportSafe()
				return
			end
		end
	end
end

antiBotBtn.MouseButton1Click:Connect(function()
	antiBotEnabled = not antiBotEnabled

	if antiBotEnabled then
		antiBotBtn.Text = "DESATIVAR ANTI NEXTBOT TP"

		antiBotConn = RunService.Heartbeat:Connect(function()
			detectBots()
		end)

	else
		if antiBotConn then
			antiBotConn:Disconnect()
			antiBotConn = nil
		end

		antiBotBtn.Text = "ATIVAR ANTI NEXTBOT TP"
	end
end)

-- NOTIFICAÇÃO
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "Made by Old Scripts";
    Text = "Script loaded";
    Icon = "rbxassetid://288817482"; -- icone de virus so pra dar um pouco de susto kkkk
    Duration = 6;
    Button1 = "OK";
    Callback = callback;
})

-- Somzinho de carregado
task.spawn(function()
    local s = Instance.new("Sound")
    s.SoundId = "rbxassetid://3023237993"
    s.Volume = 0.4
    s.Parent = game:GetService("SoundService")
    s:Play()
    task.delay(3, function() s:Destroy() end)
end)

print("[loaded]")
