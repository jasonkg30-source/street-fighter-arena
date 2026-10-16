--!strict
-- FighterSpawner: builds SF2-style block fighter models, assigns to fighters, teleports spectators to stands.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local FighterDefs = require(ReplicatedStorage:WaitForChild("FighterDefs"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))

local FighterSpawner = {}

local HEAD = Vector3.new(2, 2, 2)
local TORSO = Vector3.new(3, 3, 1.6)
local LIMB = Vector3.new(1, 2.6, 1)
local FIST = Vector3.new(1.4, 1.4, 1.4)
local FOOT = Vector3.new(1.5, 1, 2.2)

local function part(parent, name, size, color, cframe)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.CFrame = cframe
    p.Anchored = false
    p.CanCollide = false
    p.Material = Enum.Material.SmoothPlastic
    p.Parent = parent
    return p
end

function FighterSpawner.BuildModel(def, side)
    local model = Instance.new("Model")
    model.Name = def.id

    local body = def.bodyColor
    local accent = def.accentColor

    local root = part(model, "HumanoidRootPart", Vector3.new(2, 2, 1), body, CFrame.new(0, 60, 0))
    root.Transparency = 1
    root.CanCollide = false

    local torso = part(model, "Torso", TORSO, body, root.CFrame * CFrame.new(0, 0, 0))
    local belt = part(model, "Belt", Vector3.new(3.2, 0.6, 1.8), accent, torso.CFrame * CFrame.new(0, -1.2, 0))
    local head = part(model, "Head", HEAD, body, root.CFrame * CFrame.new(0, 2.4, 0))
    local hair = part(model, "Hair", Vector3.new(2.2, 0.6, 2.2), accent, head.CFrame * CFrame.new(0, 1, 0))
    local face = Instance.new("Decal")
    face.Name = "Face"
    face.Texture = "rbxassetid://0" -- plain eyes via texture id 0: keep blank, use Part eyes
    face.Parent = head

    -- simple eyes
    local eyeL = part(model, "EyeL", Vector3.new(0.35, 0.35, 0.1), Color3.new(0.1, 0.1, 0.1), head.CFrame * CFrame.new(-0.5, 0.2, -1))
    local eyeR = part(model, "EyeR", Vector3.new(0.35, 0.35, 0.1), Color3.new(0.1, 0.1, 0.1), head.CFrame * CFrame.new(0.5, 0.2, -1))
    local _ = eyeL, eyeR, belt, hair

    local armL = part(model, "LeftArm", LIMB, body, root.CFrame * CFrame.new(-2.2, -0.2, 0))
    local armR = part(model, "RightArm", LIMB, body, root.CFrame * CFrame.new(2.2, -0.2, 0))
    local legL = part(model, "LeftLeg", LIMB, accent, root.CFrame * CFrame.new(-0.9, -3, 0))
    local legR = part(model, "RightLeg", LIMB, accent, root.CFrame * CFrame.new(0.9, -3, 0))

    local fistL = part(model, "FistL", FIST, accent, armL.CFrame * CFrame.new(0, -1.6, 0))
    local fistR = part(model, "FistR", FIST, accent, armR.CFrame * CFrame.new(0, -1.6, 0))
    local footL = part(model, "FootL", FOOT, accent, legL.CFrame * CFrame.new(0, -1.6, 0.4))
    local footR = part(model, "FootR", FOOT, accent, legR.CFrame * CFrame.new(0, -1.6, 0.4))
    local _f1, _f2, _ft1, _ft2 = fistL, fistR, footL, footR

    -- Motor6D welds: root -> torso/head/arms/legs
    local function weld(p0, p1, c0)
        local m = Instance.new("Motor6D")
        m.Part0 = p0
        m.Part1 = p1
        m.C0 = c0
        m.Parent = p0
    end
    weld(root, torso, CFrame.new(0, 0, 0))
    weld(torso, head, CFrame.new(0, 2.4, 0))
    weld(torso, armL, CFrame.new(-2.2, -0.2, 0))
    weld(torso, armR, CFrame.new(2.2, -0.2, 0))
    weld(torso, legL, CFrame.new(-0.9, -3, 0))
    weld(torso, legR, CFrame.new(0.9, -3, 0))
    weld(armL, fistL, CFrame.new(0, -1.6, 0))
    weld(armR, fistR, CFrame.new(0, -1.6, 0))
    weld(legL, footL, CFrame.new(0, -1.6, 0.4))
    weld(legR, footR, CFrame.new(0, -1.6, 0.4))

    local humanoid = Instance.new("Humanoid")
    humanoid.Health = 100 * def.healthMult
    humanoid.MaxHealth = 100 * def.healthMult
    humanoid.WalkSpeed = Config.Combat.WalkSpeedFighter * def.speedMult
    humanoid.JumpPower = Config.Combat.JumpPower
    humanoid.RequiresNeck = false
    humanoid.Parent = model

    model.PrimaryPart = root
    return model
end

function FighterSpawner.SpawnFighter(player, def, side)
    -- remove old character
    if player.Character then player.Character:Destroy() end
    local model = FighterSpawner.BuildModel(def, side)
    player.Character = model
    model.Parent = workspace
    local root = model:FindFirstChild("HumanoidRootPart")
    local spawnPos = ArenaBuilder:GetFighterSpawn(side)
    if root then
        root.CFrame = CFrame.new(spawnPos) * CFrame.Angles(0, side == 1 and math.rad(90) or math.rad(-90), 0)
    end
    player:SetAttribute("FighterId", def.id)
    player:SetAttribute("Side", side)
    return model
end

function FighterSpawner.SpawnSpectator(player, standIndex)
    if player.Character then player.Character:Destroy() end
    local model = Instance.new("Model")
    model.Name = "Spectator"
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 2, 1)
    root.Transparency = 1
    root.CanCollide = false
    root.Parent = model
    local hum = Instance.new("Humanoid")
    hum.WalkSpeed = Config.Combat.WalkSpeedDefault
    hum.RequiresNeck = false
    hum.Parent = model
    model.PrimaryPart = root
    player.Character = model
    model.Parent = workspace
    local pos = ArenaBuilder:GetStandPosition(standIndex)
    root.CFrame = CFrame.new(pos)
    player:SetAttribute("Side", 0)
    player:SetAttribute("Spectator", true)
    return model
end

function FighterSpawner.ClearRole(player)
    player:SetAttribute("Spectator", false)
    player:SetAttribute("Side", 0)
    player:SetAttribute("FighterId", "")
end

return FighterSpawner