--!strict
-- FighterClient: input handling — WASD moves (default Roblox controls), J/U punch, K/I kick, L/O throw, Space jump,
-- G/H special, S crouch-block (hold S+no move = block). Touch controls too. Sends ReportMove to server.
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local remotes = RemoteSetup.Get()
local reportMove = remotes.ReportMove

local BLOCK_COOLDOWN = 0.1
local lastSent = {}

local function send(kind)
    local now = os.clock()
    if now - (lastSent[kind] or 0) < BLOCK_COOLDOWN then return end
    lastSent[kind] = now
    reportMove:FireServer(kind)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    local player = Players.LocalPlayer
    local side = player:GetAttribute("Side") or 0
    if side ~= 1 and side ~= 2 then return end
    local kc = input.KeyCode
    if kc == Enum.KeyCode.J then send("punch")
    elseif kc == Enum.KeyCode.K then send("kick")
    elseif kc == Enum.KeyCode.L then send("throw")
    elseif kc == Enum.KeyCode.H then send("special")
    elseif kc == Enum.KeyCode.S then
        player:SetAttribute("Blocking", true)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    local kc = input.KeyCode
    if kc == Enum.KeyCode.S then
        Players.LocalPlayer:SetAttribute("Blocking", false)
    end
end)

-- Touch: add HUD buttons via HUDClient? Keep here: build 4 buttons bottom-right (P/K/T/SPECIAL)
if UserInputService.TouchEnabled then
    local gui = Instance.new("ScreenGui")
    gui.Name = "SFTouchControls"
    gui.ResetOnSpawn = false
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    local labels = {{"PUNCH", "punch"}, {"KICK", "kick"}, {"THROW", "throw"}, {"SPECIAL", "special"}}
    for i, pair in ipairs(labels) do
        local b = Instance.new("TextButton")
        b.Name = pair[1] .. "Btn"
        b.Text = pair[1]
        b.TextScaled = true
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1, 1, 1)
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        b.BackgroundTransparency = 0.3
        b.Size = UDim2.fromOffset(72, 52)
        b.Position = UDim2.new(1, -(i * 84) - 20, 1, -70)
        b.Parent = gui
        b.Activated:Connect(function() send(pair[2]) end)
    end
    local blockBtn = Instance.new("TextButton")
    blockBtn.Name = "BlockBtn"
    blockBtn.Text = "BLOCK"
    blockBtn.TextScaled = true
    blockBtn.Font = Enum.Font.GothamBold
    blockBtn.TextColor3 = Color3.new(1, 1, 1)
    blockBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 60)
    blockBtn.BackgroundTransparency = 0.3
    blockBtn.Size = UDim2.fromOffset(72, 52)
    blockBtn.Position = UDim2.new(1, -20 - 84 * 4 - 8, 1, -70)
    blockBtn.Parent = gui
    blockBtn.MouseButton1Down:Connect(function() Players.LocalPlayer:SetAttribute("Blocking", true) end)
    blockBtn.MouseButton1Up:Connect(function() Players.LocalPlayer:SetAttribute("Blocking", false) end)
end