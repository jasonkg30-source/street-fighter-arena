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

-- Touch: action buttons clustered AROUND the jump button in one UIListLayout container.
-- Arc: BLOCK / THROW / SPECIAL on a raised row, PUNCH / KICK below-right beside the jump button (no overlap with it).
if UserInputService.TouchEnabled then
    local gui = Instance.new("ScreenGui")
    gui.Name = "SFTouchControls"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 10
    gui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

    -- top row (raised above the jump button): THROW / SPECIAL / BLOCK
    local top = Instance.new("Frame")
    top.Name = "SFActionsTop"
    top.AnchorPoint = Vector2.new(1, 1)
    top.Position = UDim2.new(1, -30, 1, -230)
    top.Size = UDim2.fromOffset(3 * 72 + 2 * 10, 52)
    top.BackgroundTransparency = 1
    top.Parent = gui

    local topLayout = Instance.new("UIListLayout")
    topLayout.FillDirection = Enum.FillDirection.Horizontal
    topLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    topLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    topLayout.Padding = UDim.new(0, 10)
    topLayout.SortOrder = Enum.SortOrder.LayoutOrder
    topLayout.Parent = top

    -- bottom row (left of the jump button): PUNCH / KICK
    local bottom = Instance.new("Frame")
    bottom.Name = "SFActionsBottom"
    bottom.AnchorPoint = Vector2.new(1, 1)
    bottom.Position = UDim2.new(1, -30, 1, -170)  -- jump button zone starts ~x 1,-110
    bottom.Size = UDim2.fromOffset(2 * 72 + 10, 52)
    bottom.BackgroundTransparency = 1
    bottom.Parent = gui

    local botLayout = Instance.new("UIListLayout")
    botLayout.FillDirection = Enum.FillDirection.Horizontal
    botLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    botLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    botLayout.Padding = UDim.new(0, 10)
    botLayout.SortOrder = Enum.SortOrder.LayoutOrder
    botLayout.Parent = bottom

    local topRow = {{"THROW", "throw"}, {"SPECIAL", "special"}, {"BLOCK", "block"}}
    for i, pair in ipairs(topRow) do
        local b = Instance.new("TextButton")
        b.Name = pair[1] .. "Btn"
        b.Text = pair[1]
        b.TextScaled = true
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1, 1, 1)
        b.BackgroundColor3 = pair[1] == "BLOCK" and Color3.fromRGB(80, 80, 60) or Color3.fromRGB(60, 60, 80)
        b.BackgroundTransparency = 0.3
        b.Size = UDim2.fromOffset(72, 52)
        b.LayoutOrder = i
        b.Parent = top
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = b
        if pair[1] == "BLOCK" then
            b.MouseButton1Down:Connect(function() Players.LocalPlayer:SetAttribute("Blocking", true) end)
            b.MouseButton1Up:Connect(function() Players.LocalPlayer:SetAttribute("Blocking", false) end)
            b.MouseLeave:Connect(function() Players.LocalPlayer:SetAttribute("Blocking", false) end)
        else
            b.Activated:Connect(function() send(pair[2]) end)
        end
    end

    local botRow = {{"PUNCH", "punch"}, {"KICK", "kick"}}
    for i, pair in ipairs(botRow) do
        local b = Instance.new("TextButton")
        b.Name = pair[1] .. "Btn"
        b.Text = pair[1]
        b.TextScaled = true
        b.Font = Enum.Font.GothamBold
        b.TextColor3 = Color3.new(1, 1, 1)
        b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
        b.BackgroundTransparency = 0.3
        b.Size = UDim2.fromOffset(72, 52)
        b.LayoutOrder = i
        b.Parent = bottom
        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(0, 10)
        c.Parent = b
        b.Activated:Connect(function() send(pair[2]) end)
    end
end