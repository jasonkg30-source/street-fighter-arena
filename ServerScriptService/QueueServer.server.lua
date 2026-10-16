--!strict
-- QueueServer: manages entrance order, fighter selection, and the winner-stays challenge queue.
-- Up to 10 players in the arena: 2 fighters + up to 8 spectators standing on the stands.
-- When a match ends, the winner stays; the next queued player (in arrival order) challenges.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local FighterDefs = require(ReplicatedStorage:WaitForChild("FighterDefs"))
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))
local ArenaBuilder = require(script.Parent:WaitForChild("ArenaBuilder"))
local FighterSpawner = require(script.Parent:WaitForChild("FighterSpawner"))
local MatchServer = require(script.Parent:WaitForChild("MatchServer"))

local remotes = RemoteSetup.Get()
local stateFolder = remotes.State
local selectFighter = remotes.SelectFighter

local QueueServer = {}
QueueServer.queue = {}          -- array of {player=Player, chosenId=string or nil}
QueueServer.champ = nil         -- current champion (winner of last match)
QueueServer.selecting = {}      -- [player] = true while choosing character

local function totalPlayers() return #Players:GetPlayers() end

local function syncQueueState()
    local names = {}
    for i, entry in ipairs(QueueServer.queue) do
        names[i] = entry.player.Name
        if i >= 12 then break end
    end
    stateFolder:SetAttribute("Queue", table.concat(names, ","))
    stateFolder:SetAttribute("QueueCount", #QueueServer.queue)
    stateFolder:SetAttribute("TotalInArena", totalPlayers())
end

local function spectatorCount()
    local n = 0
    for _, p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("Spectator") then n += 1 end
    end
    return n
end

local function freeStandIndex()
    local used = {}
    for _, p in ipairs(Players:GetPlayers()) do
        local idx = p:GetAttribute("StandIndex")
        if idx then used[idx] = true end
    end
    for i = 1, Config.Match.MaxSpectators do
        if not used[i] then return i end
    end
    return nil
end

-- Player arrival: 1st joins as Fighter 1 (goes to character select), 2nd as Fighter 2 (character select),
-- others queue up as spectators on stands.
Players.PlayerAdded:Connect(function(player)
    player:SetAttribute("Side", 0)
    player:SetAttribute("Spectator", false)
    player:SetAttribute("FighterId", "")
    player:SetAttribute("StandIndex", 0)
    syncQueueState()
end)

Players.PlayerRemoving:Connect(function(player)
    -- remove from queue
    for i, entry in ipairs(QueueServer.queue) do
        if entry.player == player then
            table.remove(QueueServer.queue, i)
            break
        end
    end
    if QueueServer.champ == player then QueueServer.champ = nil end
    -- free stand index
    syncQueueState()
end)

-- local helpers to read current fighters
local function MatchServerF1()
    for _, p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("Side") == 1 then return p end
    end
    return nil
end
local function MatchServerF2()
    for _, p in ipairs(Players:GetPlayers()) do
        if p:GetAttribute("Side") == 2 then return p end
    end
    return nil
end

-- Character select: client sends fighter id
selectFighter.OnServerEvent:Connect(function(player, fighterId)
    if typeof(fighterId) ~= "string" then return end
    local def = FighterDefs.get(fighterId)
    if not def then return end
    local side = player:GetAttribute("Side") or 0
    if side == 1 or side == 2 then
        -- re-selection before match start only
        if stateFolder:GetAttribute("Status") ~= "Fighting" and stateFolder:GetAttribute("Status") ~= "Selecting" then
            -- allow
        elseif stateFolder:GetAttribute("Status") == "Selecting" then
            -- allow
        end
        QueueServer.selecting[player] = fighterId
        player:SetAttribute("FighterId", fighterId)
        stateFolder:SetAttribute(("Selected%d"):format(side), fighterId)
    end
end)

-- Main loop
task.spawn(function()
    -- Wait for arena to exist
    while not workspace:FindFirstChild("SFArena") do task.wait(0.5) end

    while true do
        -- IDLE: wait until we have at least one player
        if totalPlayers() == 0 then
            stateFolder:SetAttribute("Status", "Idle")
            task.wait(1)
            continue
        end

        -- PHASE 1: fill fighter seats
        local f1 = MatchServerF1()
        local f2 = MatchServerF2()

        if not f1 or not f2 then
            stateFolder:SetAttribute("Status", "Waiting")
            -- pop from queue or grab any spectator
            if not f1 then
                if #QueueServer.queue > 0 then
                    local entry = table.remove(QueueServer.queue, 1)
                    f1 = entry.player
                    f1:SetAttribute("Side", 1)
                    f1:SetAttribute("Spectator", false)
                else
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p:GetAttribute("Spectator") or (p:GetAttribute("Side") or 0) == 0 then
                            f1 = p
                            f1:SetAttribute("Side", 1)
                            f1:SetAttribute("Spectator", false)
                            break
                        end
                    end
                end
            end
            if f1 and not f2 then
                if #QueueServer.queue > 0 then
                    local entry = table.remove(QueueServer.queue, 1)
                    f2 = entry.player
                    f2:SetAttribute("Side", 2)
                    f2:SetAttribute("Spectator", false)
                else
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p ~= f1 and p:GetAttribute("Spectator") then
                            f2 = p
                            f2:SetAttribute("Side", 2)
                            f2:SetAttribute("Spectator", false)
                            break
                        end
                    end
                end
            end
            -- spawn stand seats for remaining spectators
            local standIdx = 0
            for _, p in ipairs(Players:GetPlayers()) do
                if p ~= f1 and p ~= f2 and p:GetAttribute("Spectator") then
                    standIdx += 1
                    if standIdx <= Config.Match.MaxSpectators then
                        p:SetAttribute("StandIndex", standIdx)
                        FighterSpawner.SpawnSpectator(p, standIdx)
                    end
                end
            end
            syncQueueState()

            if f1 and f2 then
                stateFolder:SetAttribute("Status", "Selecting")
                stateFolder:SetAttribute("Selected1", "")
                stateFolder:SetAttribute("Selected2", "")
                -- character select countdown
                local deadline = os.clock() + Config.CharSelectSeconds
                while os.clock() < deadline do
                    local s1 = QueueServer.selecting[f1]
                    local s2 = QueueServer.selecting[f2]
                    if s1 and s2 then break end
                    stateFolder:SetAttribute("SelectCountdown", math.ceil(deadline - os.clock()))
                    task.wait(0.3)
                end
                -- default to Ryu if not selected
                local id1 = QueueServer.selecting[f1] or "RYU"
                local id2 = QueueServer.selecting[f2] or "KEN"
                QueueServer.selecting[f1] = nil
                QueueServer.selecting[f2] = nil
                local d1 = FighterDefs.get(id1) or FighterDefs.get("RYU")
                local d2 = FighterDefs.get(id2) or FighterDefs.get("KEN")
                f1:SetAttribute("FighterId", d1.id)
                f2:SetAttribute("FighterId", d2.id)
                FighterSpawner.SpawnFighter(f1, d1, 1)
                FighterSpawner.SpawnFighter(f2, d2, 2)
                task.wait(1)

                -- run the match (best of 3)
                local winner = MatchServer.StartMatch(f1, f2)

                -- winner stays; loser exits to queue tail
                local loser = winner == f1 and f2 or f1
                loser:SetAttribute("Side", 0)
                -- Loser goes to back of queue
                table.insert(QueueServer.queue, {player = loser})
                loser:SetAttribute("Spectator", true)
                QueueServer.champ = winner
                winner:SetAttribute("Spectator", false)
                -- champion stays spawned (FighterSpawner keeps character)
                local standIdx = freeStandIndex()
                if standIdx then
                    loser:SetAttribute("StandIndex", standIdx)
                    FighterSpawner.SpawnSpectator(loser, standIdx)
                end
                MatchServer.StopAll()
                -- intermission before next challenger
                stateFolder:SetAttribute("Status", "Intermission")
                task.wait(Config.Match.IntermissionSeconds)

                -- next challenger: head of queue
                local challenger
                if #QueueServer.queue > 0 then
                    local e = table.remove(QueueServer.queue, 1)
                    challenger = e.player
                    challenger:SetAttribute("Spectator", false)
                end
                if challenger and QueueServer.champ then
                    -- champion stays side 1, challenger takes side 2
                    QueueServer.champ:SetAttribute("Side", 1)
                    championToSideOne(QueueServer.champ)
                    challenger:SetAttribute("Side", 2)
                    stateFolder:SetAttribute("Status", "Selecting")
                    stateFolder:SetAttribute("Selected2", "")
                    local ddl = os.clock() + Config.CharSelectSeconds
                    while os.clock() < ddl do
                        if QueueServer.selecting[challenger] then break end
                        stateFolder:SetAttribute("SelectCountdown", math.ceil(ddl - os.clock()))
                        task.wait(0.3)
                    end
                    local cid = QueueServer.selecting[challenger] or "RYU"
                    QueueServer.selecting[challenger] = nil
                    local cdef = FighterDefs.get(cid) or FighterDefs.get("RYU")
                    challenger:SetAttribute("FighterId", cdef.id)
                    FighterSpawner.SpawnFighter(challenger, cdef, 2)
                    task.wait(1)
                    local newWinner = MatchServer.StartMatch(QueueServer.champ, challenger)
                    local newLoser = newWinner == QueueServer.champ and challenger or QueueServer.champ
                    newLoser:SetAttribute("Side", 0)
                    table.insert(QueueServer.queue, {player = newLoser})
                    newLoser:SetAttribute("Spectator", true)
                    local idx2 = freeStandIndex()
                    if idx2 then
                        newLoser:SetAttribute("StandIndex", idx2)
                        FighterSpawner.SpawnSpectator(newLoser, idx2)
                    end
                    QueueServer.champ = newWinner
                    MatchServer.StopAll()
                    stateFolder:SetAttribute("Status", "Intermission")
                    task.wait(Config.Match.IntermissionSeconds)
                end
            end
            task.wait(0.5)
        else
            -- both fighters exist but no match running (e.g. after player leaving weirdness): start match directly
            local d1 = FighterDefs.get(f1:GetAttribute("FighterId") or "RYU")
            local d2 = FighterDefs.get(f2:GetAttribute("FighterId") or "KEN")
            FighterSpawner.SpawnFighter(f1, d1, 1)
            FighterSpawner.SpawnFighter(f2, d2, 2)
            local winner = MatchServer.StartMatch(f1, f2)
            local loser = winner == f1 and f2 or f1
            loser:SetAttribute("Side", 0)
            table.insert(QueueServer.queue, {player = loser})
            loser:SetAttribute("Spectator", true)
            QueueServer.champ = winner
            MatchServer.StopAll()
            task.wait(Config.Match.IntermissionSeconds)
        end
        syncQueueState()
    end
end)

-- helper: reposition champion to side 1 spawn (fresh character with kept FighterId)
function championToSideOne(champion)
    local def = FighterDefs.get(champion:GetAttribute("FighterId") or "RYU")
    FighterSpawner.SpawnFighter(champion, def, 1)
end

return QueueServer