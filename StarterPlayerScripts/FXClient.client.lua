--!strict
-- FXClient: listens MovePlayed (skill name popup over fighter) + HitFX (hit spark + sounds).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local remotes = RemoteSetup.Get()
local movePlayed = remotes.MovePlayed
local hitFX = remotes.HitFX
local player = Players.LocalPlayer

local gui = Instance.new("ScreenGui")
gui.Name = "SFFXPopups"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- skill name popups: use BillboardGui over the fighter's head (server broadcasts player name)
movePlayed.OnClientEvent:Connect(function(playerName, moveKind, moveName, color)
    -- find the character model by player name
    local target = nil
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name == playerName and p.Character then target = p.Character break end
    end
    if not target then return end
    local head = target:FindFirstChild("Head")
    if not head then return end
    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 180, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Adornee = head
    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.GothamBlack
    label.Text = (typeof(color) == "Color3" and moveKind == "special") and ("★ " .. moveName .. " ★") or moveName
    label.TextColor3 = typeof(color) == "Color3" and color or Color3.new(1, 1, 1)
    label.TextStrokeTransparency = 0.3
    label.TextScaled = true
    label.Parent = billboard
    billboard.Parent = workspace
    Debris:AddItem(billboard, 1.2)
    -- simple synth feedback for your own special: beep via Sound instance
    if playerName == player.Name then
        local s = Instance.new("Sound")
        s.SoundId = "rbxasset://sounds/electronicpingshort.wav"
        s.Volume = 0.6
        s.Parent = workspace
        s:Play()
        Debris:AddItem(s, 2)
    end
end)

hitFX.OnClientEvent:Connect(function(position, kind)
    -- hit spark
    local spark = Instance.new("Part")
    spark.Shape = Enum.PartType.Ball
    spark.Material = Enum.Material.Neon
    spark.Color = Color3.fromRGB(255, 240, 120)
    spark.Size = Vector3.new(1, 1, 1)
    spark.Position = position + Vector3.new(0, 2, 0)
    spark.Anchored = true
    spark.CanCollide = false
    spark.Parent = workspace
    Debris:AddItem(spark, 0.2)
    local s = Instance.new("Sound")
    s.SoundId = "rbxasset://sounds/impact_generic.mp3"
    s.Volume = 0.35
    s.Parent = spark
    s:Play()
    Debris:AddItem(s, 2)
end)