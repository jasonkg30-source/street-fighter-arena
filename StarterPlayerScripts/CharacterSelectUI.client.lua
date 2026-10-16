--!strict
-- CharacterSelectUI: 8-character grid chooser — shows during Selecting phase, buttons fire SelectFighter remote.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FighterDefs = require(ReplicatedStorage:WaitForChild("FighterDefs"))
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local remotes = RemoteSetup.Get()
local selectFighter = remotes.SelectFighter
local state = remotes.State
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SFCharSelect"
gui.ResetOnSpawn = false
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 640, 0, 300)
panel.Position = UDim2.new(0.5, -320, 0.5, -150)
panel.BackgroundColor3 = Color3.fromRGB(24, 22, 34)
panel.BackgroundTransparency = 0.08
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = panel

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "CHOOSE YOUR FIGHTER"
title.TextColor3 = Color3.fromRGB(255, 220, 90)
title.TextSize = 26
title.Parent = panel

local grid = Instance.new("Frame")
grid.Size = UDim2.new(1, -24, 1, -60)
grid.Position = UDim2.new(0, 12, 0, 48)
grid.BackgroundTransparency = 1
grid.Parent = panel

local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.new(0, 140, 0, 108)
layout.CellPadding = UDim2.new(0, 10, 0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = grid

local function makeCard(def, order)
    local card = Instance.new("TextButton")
    card.Name = def.id
    card.LayoutOrder = order
    card.BackgroundColor3 = def.bodyColor
    card.BorderSizePixel = 0
    card.Font = Enum.Font.GothamBold
    card.Text = ""
    card.AutoButtonColor = true
    card.Parent = grid

    local c2 = Instance.new("UICorner")
    c2.CornerRadius = UDim.new(0, 10)
    c2.Parent = card

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 10)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = def.accentColor
    accentBar.BorderSizePixel = 0
    accentBar.Parent = card

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -8, 0, 30)
    nameLabel.Position = UDim2.new(0, 4, 0, 18)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Font = Enum.Font.GothamBlack
    nameLabel.Text = def.name
    nameLabel.TextColor3 = Color3.fromRGB(30, 28, 40)
    nameLabel.TextSize = 18
    nameLabel.Parent = card

    local specialLabel = Instance.new("TextLabel")
    specialLabel.Size = UDim2.new(1, -8, 0, 46)
    specialLabel.Position = UDim2.new(0, 4, 0, 50)
    specialLabel.BackgroundTransparency = 1
    specialLabel.Font = Enum.Font.Gotham
    specialLabel.TextWrapped = true
    specialLabel.Text = def.moves.special.name
    specialLabel.TextColor3 = Color3.fromRGB(60, 55, 75)
    specialLabel.TextSize = 13
    specialLabel.Parent = card

    card.Activated:Connect(function()
        selectFighter:FireServer(def.id)
        panel.Visible = false
    end)
    return card
end

for order, def in ipairs(FighterDefs.list) do
    makeCard(def, order)
end

task.spawn(function()
    while true do
        task.wait(0.25)
        local status = state:GetAttribute("Status") or ""
        local side = player:GetAttribute("Side") or 0
        local isFighter = side == 1 or side == 2
        panel.Visible = (status == "Selecting") and isFighter and player:GetAttribute("FighterId") == ""
        if status == "Selecting" and isFighter then
            local mine = state:GetAttribute(("Selected%d"):format(side))
            panel.Visible = not mine
        end
    end
end)