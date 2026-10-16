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