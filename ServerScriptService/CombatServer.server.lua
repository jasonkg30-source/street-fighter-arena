--!strict
-- CombatServer: receives player move inputs, resolves hitboxes/projectiles against the opposing fighter,
-- applies damage, knockback, hit-stun, meter, and reports to MatchServer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local FighterDefs = require(ReplicatedStorage:WaitForChild("FighterDefs"))
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local CombatServer = {}
CombatServer.cooldowns = {}
CombatServer.meter = {}
CombatServer.stunnedUntil = {}
CombatServer.projectiles = {}

local remotes = RemoteSetup.Get()
local reportMove = remotes.ReportMove

local function getFighterPair()
    local fighters = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local side = p:GetAttribute("Side") or 0
        if side == 1 or side == 2 then
            table.insert(fighters, p)
        end
    end
    return fighters
end

local function findOpponent(player)
    for _, p in ipairs(getFighterPair()) do
        if p ~= player then return p end
    end
    return nil
end

local function alive(player)
    local c = player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if h and r and h.Health > 0 then return h, r end
    return nil, nil
end

local function dealDamage(attacker, victim, amount, knockback, stun)
    local vh, vr = alive(victim)
    if not vh or not vr then return false end
    -- victim blocking reduces damage (client sets Blocking attr)
    local blocking = victim:GetAttribute("Blocking") == true
    local dmg = blocking and amount * 0.25 or amount
    vh:TakeDamage(dmg)
    -- knockback: push away from attacker
    local a_root = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart")
    if a_root and knockback > 0 then
        local dir = (vr.Position - a_root.Position)
        dir = Vector3.new(dir.X, 0, dir.Z)
        if dir.Magnitude < 0.5 then dir = a_root.CFrame.LookVector end
        dir = dir.Unit
        local kb = blocking and knockback * 0.4 or knockback
        vr.AssemblyLinearVelocity = vr.AssemblyLinearVelocity + dir * kb + Vector3.new(0, kb * 0.35, 0)
    end
    if stun and stun > 0 then
        CombatServer.stunnedUntil[victim] = os.clock() + stun
    end
    -- meter gains
    local m1 = CombatServer.meter[attacker] or 0
    CombatServer.meter[attacker] = math.min(Config.Combat.MeterMax, m1 + Config.Combat.MeterPerHit)
    local m2 = CombatServer.meter[victim] or 0
    CombatServer.meter[victim] = math.min(Config.Combat.MeterMax, m2 + Config.Combat.MeterOnTake)
    return true
end

local function flashBetween(p1, p2, color, seconds, radius)
    -- visual tracer between two points
    local dist = (p2 - p1).Magnitude
    local beam = Instance.new("Part")
    beam.Name = "Trail"
    beam.Anchored = true
    beam.CanCollide = false
    beam.Material = Enum.Material.Neon
    beam.Color = color
    beam.Size = Vector3.new(0.6, 0.6, dist)
    beam.CFrame = CFrame.new((p1 + p2) / 2, p2)
    beam.Parent = workspace
    Debris:AddItem(beam, seconds or 0.12)
    local _ = radius
end

local function ballFx(pos, color, radius, seconds)
    local fx = Instance.new("Part")
    fx.Shape = Enum.PartType.Ball
    fx.Material = Enum.Material.Neon
    fx.Color = color
    fx.Size = Vector3.one * (radius or 2)
    fx.Position = pos
    fx.Anchored = true
    fx.CanCollide = false
    fx.Parent = workspace
    Debris:AddItem(fx, seconds or 0.25)
    return fx
end

-- ===== Special move implementations (SF2 homage) =====
local function specialHadouken(attacker, def, root, move)
    local color = def.accentColor
    local proj = Instance.new("Part")
    proj.Shape = Enum.PartType.Ball
    proj.Size = Vector3.new(3, 3, 3)
    proj.Material = Enum.Material.Neon
    proj.Color = color
    proj.CFrame = root.CFrame * CFrame.new(0, 0.5, -3)
    proj.Anchored = true
    proj.CanCollide = false
    proj:SetAttribute("Owner", attacker.UserId)
    proj:SetAttribute("Damage", move.damage)
    proj:SetAttribute("Knockback", move.knockback)
    proj.Parent = workspace
    table.insert(CombatServer.projectiles, {part = proj, dir = root.CFrame.LookVector, speed = move.speed or 60, owner = attacker, life = 1.6})
end

local function specialShoryuken(attacker, def, root, move)
    -- rising uppercut: invuln rise + hit in front above
    local h, _r = alive(attacker)
    if not h then return end
    local rise = Instance.new("BodyVelocity")
    rise.MaxForce = Vector3.one * 1e6
    rise.Velocity = root.CFrame.LookVector * 6 + Vector3.new(0, 78, 0)
    rise.Parent = root
    Debris:AddItem(rise, 0.18)
    local opp = findOpponent(attacker)
    if opp then
        local oh, orr = alive(opp)
        if oh and orr then
            local rel = (orr.Position - root.Position)
            if rel.Magnitude <= move.range and rel.Y > -2 and math.abs(rel.X) + math.abs(rel.Z) <= move.range then
                dealDamage(attacker, opp, move.damage, move.knockback, 0.4)
            end
        end
    end
    ballFx(root.Position + root.CFrame.LookVector * 3 + Vector3.new(0, 3, 0), def.accentColor, 4, 0.3)
    local _ = def
end

local function specialElectricThunder(attacker, def, root, move)
    -- Blanka: multihit around self
    local opp = findOpponent(attacker)
    if not opp then return end
    local oh, orr = alive(opp)
    if not oh or not orr then return end
    if (orr.Position - root.Position).Magnitude <= move.range then
        local hits = move.hits or 5
        for i = 1, hits do
            task.delay((i - 1) * 0.14, function()
                local h2, r2 = alive(opp)
                if h2 and r2 and (r2.Position - root.Position).Magnitude <= move.range + 2 then
                    dealDamage(attacker, opp, move.damage / hits, move.knockback / hits, 0.08)
                    ballFx(r2.Position + Vector3.new(0, 2, 0), Color3.fromRGB(250, 240, 120), 3, 0.14)
                end
            end)
        end
    end
    local _ = def
end

local function specialHyakuretsu(attacker, def, root, move)
    -- Honda/ChunLi-style multihit: rapid short-range strikes
    local opp = findOpponent(attacker)
    if not opp then return end
    local hits = move.hits or 6
    for i = 1, hits do
        task.delay((i - 1) * 0.11, function()
            local h1, r1 = alive(attacker)
            local h2, r2 = alive(opp)
            if h1 and h2 and r1 and r2 and (r1.Position - r2.Position).Magnitude <= move.range then
                dealDamage(attacker, opp, move.damage / hits, move.knockback / hits, 0.05)
                flashBetween(r1.Position, r2.Position, def.accentColor, 0.08)
            end
        end)
    end
end

local function specialRollingAttack(attacker, def, root, move)
    -- Blanka/Honda dash-attack: dash forward, damage on contact
    local opp = findOpponent(attacker)
    local dash = Instance.new("BodyVelocity")
    dash.MaxForce = Vector3.one * 1e6
    dash.Velocity = root.CFrame.LookVector * (move.speed or 44)
    dash.Parent = root
    Debris:AddItem(dash, 0.5)
    if opp then
        local connector
        connector = RunService.Heartbeat:Connect(function()
            local h2, r2 = alive(opp)
            local h1, r1 = alive(attacker)
            if not h1 or not h2 or not r1 or not r2 or not connector then
                if connector then connector:Disconnect() end
                return
            end
            if (r1.Position - r2.Position).Magnitude <= 7 then
                dealDamage(attacker, opp, move.damage, move.knockback, 0.3)
                connector:Disconnect()
            end
        end)
        Debris:AddItem(connector, 0.6)
        ballFx(root.Position, def.accentColor, 2.4, 0.4)
    end
end

local function specialZangiefPiledriver(attacker, def, root, move)
    -- Zangief: grabs opponent in front and jumps (throw-class: single resolution here, meleeHit not called)
    local opp = findOpponent(attacker)
    if not opp then return end
    local oh, orr = alive(opp)
    local h, r = alive(attacker)
    if not oh or not h or not orr or not r then return end
    if (orr.Position - root.Position).Magnitude <= move.range then
        dealDamage(attacker, opp, move.damage, 6, 0.6)
        -- lift both, slam down
        local bv = Instance.new("BodyVelocity")
        bv.MaxForce = Vector3.one * 1e6
        bv.Velocity = Vector3.new(0, 70, 0)
        bv.Parent = orr
        Debris:AddItem(bv, 0.25)
        task.delay(0.3, function()
            local h2 = alive(opp)
            if h2 then
                dealDamage(attacker, opp, move.damage * 0.6, move.knockback, 0.7)
                ballFx(orr.Position, def.accentColor, 5, 0.3)
            end
        end)
    end
end

local function specialYogaFlame(attacker, def, root, move)
    -- Dhalsim: close-range fire burst
    local opp = findOpponent(attacker)
    local h, _r = alive(attacker)
    if not h or not opp then return end
    local oh, orr = alive(opp)
    if oh and orr and (orr.Position - root.Position).Magnitude <= move.range then
        dealDamage(attacker, opp, move.damage, move.knockback, 0.4)
        for i = 1, 6 do
            task.delay(i * 0.05, function()
                ballFx(orr.Position + Vector3.new(math.random(-2,2), math.random(0,4), math.random(-2,2)), def.accentColor, 2.6, 0.8)
            end)
        end
    end
end

local SPECIAL_IMPL = {
    Hadouken = specialHadouken,
    ShinkuHadouken = specialHadouken,
    SonicBoom = specialHadouken,
    SonicTempest = specialHadouken,
    YogaFire = specialHadouken,
    YogaBlast = specialHadouken,
    Shoryuken = specialShoryuken,
    Shoryureppa = specialShoryuken,
    FlashKick = specialShoryuken,
    VerticalRoll = specialShoryuken,
    ElectricThunder = specialElectricThunder,
    Senretsukyaku = specialHyakuretsu,
    Hyakuretsukyaku = specialHyakuretsu,
    RenkoHa = specialHyakuretsu,
    HyakuretsuHundred = specialHyakuretsu,
    RollingAttack = specialRollingAttack,
    SuperZutsuki = specialRollingAttack,
    SpinningPiledriver = specialZangiefPiledriver,
    FinalAtomicBuster = specialZangiefPiledriver,
    ScrewPiledriver = specialZangiefPiledriver,
    YogaFlame = specialYogaFlame,
}

-- ===== Melee resolution =====
local function meleeHit(attacker, move)
    local opp = findOpponent(attacker)
    if not opp then return end
    local h1, r1 = alive(attacker)
    local h2, r2 = alive(opp)
    if not h1 or not h2 or not r1 or not r2 then return end
    local dist = (r1.Position - r2.Position).Magnitude
    if dist <= move.range then
        dealDamage(attacker, opp, move.damage, move.knockback, Config.Combat.HitStun)
        flashBetween(r1.Position, r2.Position, Color3.fromRGB(255, 240, 160), 0.1)
        remotes.HitFX:FireAllClients(r2.Position, "hit")
    end
end

reportMove.OnServerEvent:Connect(function(player, moveKind)
    local side = player:GetAttribute("Side") or 0
    if side ~= 1 and side ~= 2 then return end
    local fighterId = player:GetAttribute("FighterId")
    if not fighterId then return end
    local def = FighterDefs.get(fighterId)
    if not def then return end
    local move = def.moves[moveKind]
    if not move then return end
    -- stun check
    if CombatServer.stunnedUntil[player] and os.clock() < CombatServer.stunnedUntil[player] then return end
    -- cooldown check
    local now = os.clock()
    local key = player.UserId .. ":" .. moveKind
    if now - (CombatServer.cooldowns[key] or 0) < move.cooldown then return end
    CombatServer.cooldowns[key] = now
    -- special requires meter
    if moveKind == "special" then
        local m = CombatServer.meter[player] or 0
        if m < Config.Combat.MeterMax then return end
        CombatServer.meter[player] = 0
    end
    local h, r = alive(player)
    if not h or not r then return end
    local impl = SPECIAL_IMPL[move.id]
    if impl then
        impl(player, def, r, move)
    else
        meleeHit(player, move)
    end
    -- animate + broadcast visuals
    task.spawn(function()
        local okAnim, MoveAnimator = pcall(function() return require(script.Parent:WaitForChild("MoveAnimator")) end)
        if okAnim and MoveAnimator then MoveAnimator.Play(player.Character, moveKind == "special" and "special" or moveKind) end
        remotes.MovePlayed:FireAllClients(player.Name, moveKind, move.name, def.accentColor)
    end)
end)

-- ===== projectile updater =====
RunService.Heartbeat:Connect(function(dt)
    for i = #CombatServer.projectiles, 1, -1 do
        local proj = CombatServer.projectiles[i]
        if not proj.part or not proj.part.Parent then
            table.remove(CombatServer.projectiles, i)
        else
            local delta = proj.dir * proj.speed * dt
            proj.part.CFrame = proj.part.CFrame + delta
            proj.life -= dt
            -- check hit vs opponent
            local owner = proj.owner
            local opp = findOpponent(owner)
            if opp then
                local oh, orr = alive(opp)
                if oh and orr then
                    local dist = (orr.Position - proj.part.Position).Magnitude
                    if dist <= 6 then
                        dealDamage(owner, opp, proj.part:GetAttribute("Damage"), proj.part:GetAttribute("Knockback"), 0.18)
                        ballFx(proj.part.Position, proj.part.Color, 4, 0.3)
                        proj.part:Destroy()
                        table.remove(CombatServer.projectiles, i)
                    end
                end
            end
            if proj.life <= 0 and proj.part and proj.part.Parent then
                proj.part:Destroy()
                table.remove(CombatServer.projectiles, i)
            end
        end
    end
end)

-- meter decay attribute sync (HUD reads attribute)
task.spawn(function()
    while true do
        for _, p in ipairs(Players:GetPlayers()) do
            p:SetAttribute("Meter", CombatServer.meter[p] or 0)
        end
        task.wait(0.15)
    end
end)

Players.PlayerRemoving:Connect(function(p)
    CombatServer.cooldowns[p.UserId] = nil
    CombatServer.meter[p] = nil
    CombatServer.stunnedUntil[p] = nil
end)

return CombatServer