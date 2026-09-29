local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local toggleQueue = remotes:WaitForChild("ToggleRoundQueue")

local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("PlayRoundUI")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "PlayRoundUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Position = UDim2.fromOffset(18, 18)
frame.Size = UDim2.fromOffset(210, 88)
frame.BackgroundColor3 = Color3.fromRGB(28, 29, 38)
frame.BackgroundTransparency = 0.08
frame.Parent = gui

local frameCorner = Instance.new("UICorner")
frameCorner.CornerRadius = UDim.new(0, 14)
frameCorner.Parent = frame

local button = Instance.new("TextButton")
button.Position = UDim2.fromOffset(8, 8)
button.Size = UDim2.new(1, -16, 0, 48)
button.TextColor3 = Color3.new(1, 1, 1)
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.Parent = frame

local buttonCorner = Instance.new("UICorner")
buttonCorner.CornerRadius = UDim.new(0, 12)
buttonCorner.Parent = button

local info = Instance.new("TextLabel")
info.BackgroundTransparency = 1
info.Position = UDim2.fromOffset(8, 58)
info.Size = UDim2.new(1, -16, 0, 22)
info.TextColor3 = Color3.fromRGB(210, 210, 220)
info.TextSize = 14
info.Font = Enum.Font.Gotham
info.Parent = frame

local function update()
	local inRound = player:GetAttribute("InRound") == true
	local queued = player:GetAttribute("WantToPlay") == true
	local isAFK = player:GetAttribute("IsAFK") == true

	if inRound then
		button.Text = "🔥 PLAYING"
		button.BackgroundColor3 = Color3.fromRGB(220, 90, 45)
		button.Active = false
		info.Text = "Boa sorte!"
	elseif isAFK then
		button.Text = "💤 AFK"
		button.BackgroundColor3 = Color3.fromRGB(80, 82, 95)
		button.Active = false
		info.Text = "Sai da AFK Zone para jogar"
	elseif queued then
		button.Text = "✓ JOINED"
		button.BackgroundColor3 = Color3.fromRGB(70, 160, 90)
		button.Active = true
		info.Text = "Clique para cancelar"
	else
		button.Text = "▶ PLAY"
		button.BackgroundColor3 = Color3.fromRGB(255, 125, 40)
		button.Active = true
		info.Text = "Entrar na próxima ronda"
	end
end

button.Activated:Connect(function()
	if not button.Active then
		return
	end

	button.Active = false

	local response = toggleQueue:InvokeServer()

	if response and not response.Success then
		info.Text = response.Message or "Não foi possível alterar."
	end

	task.wait()
	update()
end)

for _, attribute in {"InRound", "WantToPlay", "IsAFK"} do
	player:GetAttributeChangedSignal(attribute):Connect(update)
end

update()
