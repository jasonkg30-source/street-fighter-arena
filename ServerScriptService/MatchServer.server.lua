--!strict
-- MatchServer: best-of-3 rounds between the two fighters; declares match winner; hands off to QueueServer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("GameConfig"))
local RemoteSetup = require(ReplicatedStorage:WaitForChild("RemoteSetup"))

local MatchServer = {}
MatchServer.wins = {p1 = 0, p2 = 0}
MatchServer.roundActive = false
MatchServer.matchActive = false

local remotes = RemoteSetup.Get()
local stateFolder = remotes.State

local function setState(attrs)
    for k, v in pairs(attrs) do
        stateFolder:SetAttribute(k, v)
    end
end

local function fighterPlayers()
    local one, two
    for _, p in ipairs(Players:GetPlayers()) do
        local side = p:GetAttribute("Side") or 0
        if side == 1 then one = p elseif side == 2 then two = p end
    end
    return one, two
end

local function alive(player)
    local c = player and player.Character
    local h = c and c:FindFirstChildOfClass("Humanoid")
    return h and h.Health > 0
end

function MatchServer.StartMatch(p1, p2)
    MatchServer.wins = {p1 = 0, p2 = 0}
    MatchServer.matchActive = true
    setState({Status = "Intro", MatchFighter1 = p1.DisplayName, MatchFighter2 = p2.DisplayName, RoundNumber = 0})
    task.wait(2)
    while MatchServer.wins.p1 < Config.Match.WinsNeeded and MatchServer.wins.p2 < Config.Match.WinsNeeded do
        local roundNumber = MatchServer.wins.p1 + MatchServer.wins.p2 + 1
        setState({Status = "FightingIntro", RoundNumber = roundNumber})
        task.wait(1)  -- FIGHT! intro beat
        setState({Status = "Fighting", RoundNumber = roundNumber})
        -- reset round-local states
        local t0 = os.clock()
        MatchServer.roundActive = true
        -- wait until a fighter dies or time out
        local winner
        while os.clock() - t0 < Config.Match.RoundSeconds and MatchServer.roundActive do
            stateFolder:SetAttribute("TimeLeft", math.ceil(Config.Match.RoundSeconds - (os.clock() - t0)))
            local a1, a2 = alive(p1), alive(p2)
            if not a1 then winner = p2 break end
            if not a2 then winner = p1 break end
            task.wait(0.2)
        end
        MatchServer.roundActive = false
        if not winner then
            -- timeout: higher HP% wins
            local h1 = alive(p1)
            local h2 = alive(p2)
            local hp1 = h1 and p1.Character:FindFirstChildOfClass("Humanoid").Health or 0
            local hp2 = h2 and p2.Character:FindFirstChildOfClass("Humanoid").Health or 0
            winner = hp1 >= hp2 and p1 or p2
        end
        if winner == p1 then MatchServer.wins.p1 += 1 else MatchServer.wins.p2 += 1 end
        setState({Status = "RoundOver", RoundWinner = winner.DisplayName, WinsP1 = MatchServer.wins.p1, WinsP2 = MatchServer.wins.p2})
        task.wait(Config.Match.ResultSeconds)
        -- respawn both for next round
        if MatchServer.wins.p1 < Config.Match.WinsNeeded and MatchServer.wins.p2 < Config.Match.WinsNeeded then
            setState({Status = "Respawn"})
            task.wait(1)
            local FighterSpawner = require(script.Parent:WaitForChild("FighterSpawner"))
            local d1 = FighterDefs.get(p1:GetAttribute("FighterId"))
            local d2 = FighterDefs.get(p2:GetAttribute("FighterId"))
            if d1 then FighterSpawner.SpawnFighter(p1, d1, 1) end
            if d2 then FighterSpawner.SpawnFighter(p2, d2, 2) end
            task.wait(0.6)
        end
    end
    local matchWinner = MatchServer.wins.p1 >= Config.Match.WinsNeeded and p1 or p2
    MatchServer.matchActive = false
    setState({Status = "MatchOver", MatchWinner = matchWinner.DisplayName})
    return matchWinner
end

function MatchServer.StopAll()
    MatchServer.roundActive = false
    MatchServer.matchActive = false
    setState({Status = "Idle"})
end

return MatchServer