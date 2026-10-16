--!strict
-- HUDClient: shows round status, HP bars, meter, round pips, queue list, and win counters.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local remotes = RemoteSetup.Get()
local state = remotes.State
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SFHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local function bar(x)
    local frame = Instance.new("Frame")
    frame.Name = x == 1 and "P1Container" or "P2Container"
    frame.Size = UDim2.new(0.38, 0, 0, 34)
    frame.Position = x == 1 and UDim2.new(0.02, 0, 0, 30) or UDim2.new(0.6, 0, 0, 30)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.fromScale(1, 1)
    fill.Position = UDim2.new(0, 0, 0, 0)
    fill.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
    fill.BorderSizePixel = 0
    fill.Parent = frame
    local name = Instance.new("TextLabel")
    name.Name = "FighterName"
    name.Size = UDim2.fromScale(1, 1)
    name.BackgroundTransparency = 1
    name.Font = Enum.Font.GothamBold
    name.TextColor3 = Color3.new(1, 1, 1)
    name.TextScaled = true
    name.Parent = frame
    local meterBg = Instance.new("Frame")
    meterBg.Name = "MeterBg"
    meterBg.Size = UDim2.new(1, 0, 0, 8)
    meterBg.Position = UDim2.new(0, 0, 1, 4)
    meterBg.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    meterBg.BorderSizePixel = 0
    meterBg.Parent = frame
    local meterFill = Instance.new("Frame")
    meterFill.Name = "MeterFill"
    meterFill.Size = UDim2.fromScale(0, 1)
    meterFill.BackgroundColor3 = Color3.fromRGB(70, 200, 255)
    meterFill.BorderSizePixel = 0
    meterFill.Parent = meterBg
    return {
        container = frame,
        fill = fill,
        name = name,
        meterFill = meterFill,
    }
end

local p1ui = bar(1)
local p2ui = bar(2)

local centerLabel = Instance.new("TextLabel")
centerLabel.Name = "CenterLabel"
centerLabel.Size = UDim2.new(0.4, 0, 0, 44)
centerLabel.Position = UDim2.new(0.3, 0, 0, 84)
centerLabel.BackgroundTransparency = 1
centerLabel.Font = Enum.Font.GothamBlack
centerLabel.Text = ""
centerLabel.TextColor3 = Color3.new(1, 1, 1)
centerLabel.TextStrokeTransparency = 0.4
centerLabel.TextScaled = true
centerLabel.Parent = gui

local countdownLabel = Instance.new("TextLabel")
countdownLabel.Name = "CountdownLabel"
countdownLabel.Size = UDim2.new(0.2, 0, 0, 40)
countdownLabel.Position = UDim2.new(0.4, 0, 0, 130)
countdownLabel.BackgroundTransparency = 1
countdownLabel.Font = Enum.Font.GothamBlack
countdownLabel.Text = ""
countdownLabel.TextColor3 = Color3.fromRGB(255, 230, 100)
countdownLabel.TextStrokeTransparency = 0.3
countdownLabel.TextScaled = true
countdownLabel.Parent = gui

local queueLabel = Instance.new("TextLabel")
queueLabel.Name = "QueueLabel"
queueLabel.Size = UDim2.new(0.24, 0, 0, 30)
queueLabel.Position = UDim2.new(0.02, 0, 1, -40)
queueLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
queueLabel.BackgroundTransparency = 0.35
queueLabel.Font = Enum.Font.Gotham
queueLabel.Text = "Queue:"
queueLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
queueLabel.TextSize = 14
queueLabel.Parent = gui

-- Meter gauge label under center: shows your own meter + SPECIAL READY flash
local meterLabel = Instance.new("TextLabel")
meterLabel.Name = "MeterLabel"
meterLabel.Size = UDim2.new(0.3, 0, 0, 26)
meterLabel.Position = UDim2.new(0.35, 0, 1, -66)
meterLabel.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
meterLabel.BackgroundTransparency = 0.35
meterLabel.Font = Enum.Font.GothamBlack
meterLabel.Text = "ENERGY 0%"
meterLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
meterLabel.TextSize = 18
meterLabel.Parent = gui

local function findFighterBySide(side)
    for _, p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("Side") == side then return p end
    end
    return nil
end

-- ===== Mobile-first How-to-Play onboarding panel =====
-- Shows on first join; re-openable with a HELP button. English only (user-wide rule).
local helpPanel
local helpButton

local function buildOnboarding()
    -- layer under touch controls but above HUD text; phone screens are short — cap height and scale down
    helpPanel = Instance.new("Frame")
    helpPanel.Name = "HowToPlay"
    local panelH = math.min(330, math.max(0, player.ViewportSize.Y - 120))
    helpPanel.Size = UDim2.new(0, 320, 0, panelH)
    helpPanel.Position = UDim2.new(0.5, -160, 0.5, -panelH / 2)
    helpPanel.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
    helpPanel.BackgroundTransparency = 0.05
    helpPanel.BorderSizePixel = 0
    helpPanel.Visible = false
    helpPanel.Parent = gui
    local hpCorner = Instance.new("UICorner")
    hpCorner.CornerRadius = UDim.new(0, 12)
    hpCorner.Parent = helpPanel
    local hpLayout = Instance.new("UIListLayout")
    hpLayout.Padding = UDim.new(0, 5)
    hpLayout.SortOrder = Enum.SortOrder.LayoutOrder
    hpLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    hpLayout.Parent = helpPanel
    local hpPad = Instance.new("UIPadding")
    hpPad.PaddingTop = UDim.new(0, 8)
    hpPad.PaddingBottom = UDim.new(0, 8)
    hpPad.PaddingLeft = UDim.new(0, 10)
    hpPad.PaddingRight = UDim.new(0, 10)
    hpPad.Parent = helpPanel

    local function label(text, size, order, color)
        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, 0, 0, size)
        t.LayoutOrder = order
        t.BackgroundTransparency = 1
        t.Font = Enum.Font.Gotham
        t.Text = text
        t.TextColor3 = color or Color3.fromRGB(230, 230, 240)
        t.TextSize = 14
        t.TextWrapped = true
        t.Parent = helpPanel
        return t
    end

    label("HOW TO PLAY", 28, 1, Color3.fromRGB(255, 220, 90)).Font = Enum.Font.GothamBlack
    label("1v1 fighting: the first player is P1 (red side), the second is P2 (blue side). Winner stays, loser goes to the back of the queue!", 58, 2)
    label("WALK: thumbstick (left)   JUMP: jump button (right)", 20, 3)
    label("TOUCH: use the action buttons near the jump button", 20, 4)
    label("KEYBOARD: PUNCH J | KICK K | THROW L | SPECIAL H | BLOCK hold S", 30, 5)
    label("Fill ENERGY by fighting. At 100% press SPECIAL for your character's signature move!", 40, 6, Color3.fromRGB(120, 220, 255))

    -- close button pinned INSIDE the panel bottom: fixed offset from panel bottom edge,
    -- so UIListLayout overflow (short screens) can never push it off-panel/off-screen again
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseHelp"
    closeBtn.AnchorPoint = Vector2.new(0.5, 1)
    closeBtn.Position = UDim2.new(0.5, 0, 1, -10)
    closeBtn.Size = UDim2.new(1, -30, 0, 40)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 200, 60)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Text = "GOT IT, LET'S FIGHT!"
    closeBtn.TextColor3 = Color3.fromRGB(30, 28, 40)
    closeBtn.TextSize = 16
    closeBtn.Parent = helpPanel
    local cbCorner = Instance.new("UICorner")
    cbCorner.CornerRadius = UDim.new(0, 8)
    cbCorner.Parent = closeBtn
    closeBtn.Activated:Connect(function()
        helpPanel.Visible = false
    end)

    -- round HELP chip top-right (own layer, clear of P2 HP bar which starts y=30)
    helpButton = Instance.new("TextButton")
    helpButton.Name = "HelpBtn"
    helpButton.Size = UDim2.fromOffset(48, 24)
    helpButton.Position = UDim2.new(1, -58, 0, 4)
    helpButton.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    helpButton.BackgroundTransparency = 0.25
    helpButton.Font = Enum.Font.GothamBold
    helpButton.Text = "HELP?"
    helpButton.TextColor3 = Color3.new(1, 1, 1)
    helpButton.TextSize = 12
    helpButton.Parent = gui
    helpButton.Activated:Connect(function()
        helpPanel.Visible = not helpPanel.Visible
    end)
end

buildOnboarding()
if helpPanel then
    helpPanel.Visible = true  -- show once on join
end

task.spawn(function()
    while true do
        task.wait(0.2)
        -- status text
        local status = state:GetAttribute("Status") or ""
        local s1 = state:GetAttribute("Selected1")
        local s2 = state:GetAttribute("Selected2")
        if status == "Selecting" then
            local cd = state:GetAttribute("SelectCountdown") or 0
            centerLabel.Text = "CHOOSE YOUR FIGHTER!"
            countdownLabel.Text = tostring(cd)
        elseif status == "Fighting" then
            centerLabel.Text = ("ROUND %d"):format(state:GetAttribute("RoundNumber") or 1)
            local tleft = state:GetAttribute("TimeLeft") or 0
            countdownLabel.Text = tleft > 0 and ("%d"):format(math.ceil(tleft)) or ""
        elseif status == "FightingIntro" then
            centerLabel.Text = "FIGHT!"
            countdownLabel.Text = ""
        elseif status == "RoundOver" then
            centerLabel.Text = ("%s WINS THE ROUND!"):format(state:GetAttribute("RoundWinner") or "")
            countdownLabel.Text = ""
        elseif status == "MatchOver" then
            centerLabel.Text = ("%s WINS THE MATCH!"):format(state:GetAttribute("MatchWinner") or "")
            countdownLabel.Text = ""
        elseif status == "Intermission" then
            centerLabel.Text = "Next challenger get ready!"
            countdownLabel.Text = ""
        end
        -- HP bars: read live humanoid health from real players side 1 and 2
        for side, ui in ipairs({p1ui, p2ui}) do
            local f = findFighterBySide(side)
            if f and f.Character and f.Character:FindFirstChildOfClass("Humanoid") then
                local h = f.Character:FindFirstChildOfClass("Humanoid")
                ui.fill.Size = UDim2.fromScale(math.clamp(h.Health / h.MaxHealth, 0, 1), 1)
                ui.name.Text = ("%s [%s]"):format(f.DisplayName, f:GetAttribute("FighterId") or "?")
                local meter = f:GetAttribute("Meter") or 0
                ui.meterFill.Size = UDim2.fromScale(math.clamp(meter / 100, 0, 1), 1)
            else
                ui.fill.Size = UDim2.fromScale(0, 1)
                ui.name.Text = ""
                ui.meterFill.Size = UDim2.fromScale(0, 1)
            end
        end
        local q = state:GetAttribute("Queue") or ""
        local qc = state:GetAttribute("QueueCount") or 0
        queueLabel.Text = ("Queue (%d): %s"):format(qc, q)
        -- own meter gauge
        local m = player:GetAttribute("Meter") or 0
        if m >= 100 then
            meterLabel.Text = "SPECIAL READY! Press H"
            meterLabel.TextColor3 = Color3.fromRGB(255, 240, 90)
        else
            meterLabel.Text = ("ENERGY %d%%"):format(math.floor(m))
            meterLabel.TextColor3 = Color3.fromRGB(120, 220, 255)
        end
    end
end)