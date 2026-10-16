-- Meter time-fill: meters also passively fill over 60s round so specials actually come out.
-- Appended as a separate script portion inside CombatServer flow: we add a Heartbeat filler.

local Players = game:GetService("Players")
local Config = require(game:GetService("ReplicatedStorage"):WaitForChild("GameConfig"))

-- MeterPerSecond fill so a full meter takes ~24s of active fighting (also gains from hits)
local METER_PER_SECOND = 4.2

task.spawn(function()
    while true do
        local dt = task.wait(0.2)
        for _, p in ipairs(Players:GetPlayers()) do
            local side = p:GetAttribute("Side") or 0
            if side == 1 or side == 2 then
                local cur = p:GetAttribute("Meter") or 0
                if cur < Config.Combat.MeterMax then
                    p:SetAttribute("Meter", math.min(Config.Combat.MeterMax, cur + METER_PER_SECOND * dt))
                end
            end
        end
    end
end)