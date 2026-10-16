--!strict
-- ArenaBuilder: builds the 1v1 ring + spectator stands ring.
-- Ring: circular floor of radius RingSize/2, low walls all around, 8 stands for spectators in a circle around it.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))

local ArenaBuilder = {}

local function part(parent, name, position, size, color, material, transparency)
    local p = Instance.new("Part")
    p.Name = name
    p.Anchored = true
    p.Size = size
    p.Position = position
    p.Color = color
    p.Material = material or Enum.Material.SmoothPlastic
    if transparency then p.Transparency = transparency end
    p.TopSurface = Enum.SurfaceType.Smooth
    p.BottomSurface = Enum.SurfaceType.Smooth
    p.Parent = parent
    return p
end

function ArenaBuilder:Build()
    local existing = workspace:FindFirstChild("SFArena")
    if existing then existing:Destroy() end

    local folder = Instance.new("Folder")
    folder.Name = "SFArena"
    folder.Parent = workspace

    local ring = Config.Arena.RingSize
    local r = ring / 2

    -- Floor (cylinder part)
    local floor = Instance.new("Part")
    floor.Name = "RingFloor"
    floor.Shape = Enum.PartType.Cylinder
    floor.Size = Vector3.new(2, ring, ring)
    floor.CFrame = CFrame.new(0, 0, 0) * CFrame.Angles(0, 0, math.rad(90))
    floor.Color = Config.Colors.Floor
    floor.Material = Enum.Material.Concrete
    floor.Anchored = true
    floor.Parent = folder

    -- Center ring marking (thin disc)
    local marker = Instance.new("Part")
    marker.Name = "RingMarker"
    marker.Shape = Enum.PartType.Cylinder
    marker.Size = Vector3.new(0.4, ring * 0.66, ring * 0.66)
    marker.CFrame = CFrame.new(0, 1.2, 0) * CFrame.Angles(0, 0, math.rad(90))
    marker.Color = Config.Colors.FloorRing
    marker.Material = Enum.Material.Neon
    marker.Anchored = true
    marker.CanCollide = false
    marker.Parent = folder

    -- Perimeter walls: 24 segments around circle
    local segs = 24
    for i = 1, segs do
        local angle = (i / segs) * math.pi * 2
        local cx, cz = math.cos(angle), math.sin(angle)
        local wall = part(
            folder,
            "Wall" .. i,
            Vector3.new(cx * r, Config.Arena.WallHeight / 2, cz * r),
            Vector3.new(ring * 0.148, Config.Arena.WallHeight, 2),
            Config.Colors.Wall
        )
        wall.CFrame = CFrame.new(wall.Position) * CFrame.Angles(0, -angle + math.rad(90), 0)
    end

    -- 8 spectator stands (small platforms around outside)
    for i = 1, 8 do
        local angle = (i / 8) * math.pi * 2 + math.pi / 8
        local standRadius = r + 18
        local cx, cz = math.cos(angle), math.sin(angle)
        local stand = part(
            folder,
            "Stand" .. i,
            Vector3.new(cx * standRadius, 3, cz * standRadius),
            Vector3.new(14, 1, 12),
            Config.Colors.Spectator,
            Enum.Material.Wood
        )
        stand.CFrame = CFrame.new(stand.Position) * CFrame.Angles(0, -angle + math.rad(90), 0)
        -- stand marker
        local stool = part(folder, "Stool" .. i, Vector3.new(cx * standRadius, 5.2, cz * standRadius), Vector3.new(3, 0.6, 3), Color3.fromRGB(255, 220, 130), Enum.Material.Neon)
        stool.CanCollide = false
    end

    -- Spawns: P1 and P2 on opposite sides
    local p1 = Instance.new("SpawnLocation")
    p1.Name = "P1Spawn"
    p1.Size = Vector3.new(4, 1, 4)
    p1.Position = Vector3.new(-Config.Arena.SpawnOffset, 1, 0)
    p1.Anchored = true
    p1.Neutral = true
    p1.Transparency = 1
    p1.Parent = folder
    local p2 = p1:Clone()
    p2.Name = "P2Spawn"
    p2.Position = Vector3.new(Config.Arena.SpawnOffset, 1, 0)
    p2.Parent = folder

    -- Team forcefields color rings on players: handled by FighterSpawner
    return folder
end

-- Boot: build the arena when this Script runs (ArenaBuilder is a Script in ServerScriptService).
if not workspace:FindFirstChild("SFArena") then
    local ok, err = pcall(function()
        ArenaBuilder:Build()
    end)
    if not ok then
        warn("[ArenaBuilder] build failed: " .. tostring(err))
    end
end

function ArenaBuilder:GetFighterSpawn(side)
    local folder = workspace:FindFirstChild("SFArena")
    if not folder then return Vector3.new(0, 6, 0) end
    local sp = folder:FindFirstChild(side == 1 and "P1Spawn" or "P2Spawn")
    if sp then return sp.Position + Vector3.new(0, 4, 0) end
    return Vector3.new(0, 6, 0)
end

function ArenaBuilder:GetStandPosition(i)
    local folder = workspace:FindFirstChild("SFArena")
    if not folder then return Vector3.new(0, 8, r + 18) end
    local stool = folder:FindFirstChild("Stool" .. i)
    if stool then return stool.Position + Vector3.new(0, 4, 0) end
    return Vector3.new(0, 8, 0)
end

return ArenaBuilder