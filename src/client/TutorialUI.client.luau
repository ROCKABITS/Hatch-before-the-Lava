local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local completeTutorial = remotes:WaitForChild("CompleteTutorial")

local slides = {
	{
		icon = "🌋",
		title = "THE LAVA IS RISING!",
		text = "Climb as high as you can before the lava catches you.",
	},
	{
		icon = "🪙",
		title = "EARN COINS",
		text = "The higher you reach, the more Coins you earn.",
	},
	{
		icon = "🐶",
		title = "HATCH PETS",
		text = "Use your Coins to open Eggs. Pets multiply the Coins you earn while playing.",
	},
	{
		icon = "🏆",
		title = "EARN WINS",
		text = "Reach the Finish to earn a Win. Wins will unlock new zones as the game expands.",
	},
}

local function waitForData()
	if player:GetAttribute("DataLoaded") == true then
		return
	end

	repeat
		player:GetAttributeChangedSignal("DataLoaded"):Wait()
	until player:GetAttribute("DataLoaded") == true
end

waitForData()

if player:GetAttribute("TutorialSeen") == true then
	return
end

task.wait(1)

if player:GetAttribute("TutorialSeen") == true then
	return
end

local oldGui = playerGui:FindFirstChild("TutorialUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "TutorialUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100
gui.Parent = playerGui

local dim = Instance.new("Frame")
dim.Name = "Dim"
dim.Size = UDim2.fromScale(1, 1)
dim.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
dim.BackgroundTransparency = 0.38
dim.BorderSizePixel = 0
dim.Parent = gui

local card = Instance.new("Frame")
card.AnchorPoint = Vector2.new(0.5, 0.5)
card.Position = UDim2.fromScale(0.5, 0.5)
card.Size = UDim2.fromOffset(520, 330)
card.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
card.Parent = gui

local cardCorner = Instance.new("UICorner")
cardCorner.CornerRadius = UDim.new(0, 20)
cardCorner.Parent = card

local icon = Instance.new("TextLabel")
icon.BackgroundTransparency = 1
icon.AnchorPoint = Vector2.new(0.5, 0)
icon.Position = UDim2.new(0.5, 0, 0, 24)
icon.Size = UDim2.fromOffset(90, 70)
icon.TextScaled = true
icon.Font = Enum.Font.GothamBold
icon.Parent = card

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(24, 100)
title.Size = UDim2.new(1, -48, 0, 42)
title.TextColor3 = Color3.new(1, 1, 1)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.Parent = card

local body = Instance.new("TextLabel")
body.BackgroundTransparency = 1
body.Position = UDim2.fromOffset(42, 150)
body.Size = UDim2.new(1, -84, 0, 72)
body.TextColor3 = Color3.fromRGB(220, 220, 230)
body.TextSize = 21
body.TextWrapped = true
body.Font = Enum.Font.Gotham
body.Parent = card

local progress = Instance.new("TextLabel")
progress.BackgroundTransparency = 1
progress.Position = UDim2.fromOffset(24, 226)
progress.Size = UDim2.new(1, -48, 0, 28)
progress.TextColor3 = Color3.fromRGB(160, 163, 180)
progress.TextSize = 16
progress.Font = Enum.Font.GothamBold
progress.Parent = card

local skip = Instance.new("TextButton")
skip.Position = UDim2.fromOffset(24, 267)
skip.Size = UDim2.fromOffset(120, 44)
skip.BackgroundColor3 = Color3.fromRGB(60, 62, 78)
skip.TextColor3 = Color3.new(1, 1, 1)
skip.Text = "SKIP"
skip.TextSize = 18
skip.Font = Enum.Font.GothamBold
skip.Parent = card

local skipCorner = Instance.new("UICorner")
skipCorner.CornerRadius = UDim.new(0, 12)
skipCorner.Parent = skip

local nextButton = Instance.new("TextButton")
nextButton.AnchorPoint = Vector2.new(1, 0)
nextButton.Position = UDim2.new(1, -24, 0, 267)
nextButton.Size = UDim2.fromOffset(170, 44)
nextButton.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
nextButton.TextColor3 = Color3.new(1, 1, 1)
nextButton.TextSize = 18
nextButton.Font = Enum.Font.GothamBold
nextButton.Parent = card

local nextCorner = Instance.new("UICorner")
nextCorner.CornerRadius = UDim.new(0, 12)
nextCorner.Parent = nextButton

local currentSlide = 1
local finished = false

local function renderSlide()
	local slide = slides[currentSlide]

	icon.Text = slide.icon
	title.Text = slide.title
	body.Text = slide.text
	progress.Text = string.format("%d / %d", currentSlide, #slides)

	if currentSlide == #slides then
		nextButton.Text = "LET'S GO!"
	else
		nextButton.Text = "NEXT"
	end
end

local function finishTutorial()
	if finished then
		return
	end

	finished = true
	completeTutorial:FireServer()
	gui:Destroy()
end

skip.Activated:Connect(finishTutorial)

nextButton.Activated:Connect(function()
	if currentSlide >= #slides then
		finishTutorial()
		return
	end

	currentSlide += 1
	renderSlide()
end)

renderSlide()
