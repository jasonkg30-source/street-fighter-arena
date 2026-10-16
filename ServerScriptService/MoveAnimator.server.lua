--!strict
-- MoveAnimator (ModuleScript under ReplicatedStorage? NO — server-side): poses fighter limbs for each move via Motor6D CFrames.
-- Motor6D.Transform is applied every frame by the engine; setting .Transform on a Motor6D works for one frame when called
-- during Heartbeat — simplest reliable approach here: directly set Motor6D.C0 offsets briefly (C0 is the joint offset).
local MoveAnimator = {}

local TWEENS = {}

-- move definitions: {duration, keyframes: {t -> {joint = CFrame offset}}}
-- joints: Torso joint names in our block model: RootJoint(HumanoidRootPart->Torso), NeckTorso? we welded: torso->head "Torso",
-- arms "LeftArm"/"RightArm", legs "LeftLeg"/"RightLeg", fists, feet.
-- We animate by setting C0 of the Motor6D parented in arm/leg.

local POSES = {
    punch = {
        duration = 0.28,
        frames = {
            [0.0]  = {RightArm = CFrame.Angles(math.rad(90), 0, 0)},
            [0.10] = {RightArm = CFrame.Angles(math.rad(95), 0, 0), RightFist = CFrame.new(0, -0.4, -2.4)},
            [0.18] = {RightArm = CFrame.Angles(math.rad(40), 0, 0), RightFist = CFrame.new(0, -0.2, -2.0)},
            [0.28] = {},
        },
    },
    kick = {
        duration = 0.5,
        frames = {
            [0.0]  = {RightLeg = CFrame.Angles(math.rad(45), 0, 0)},
            [0.15] = {RightLeg = CFrame.Angles(math.rad(95), 0, 0), RightFoot = CFrame.new(0, 0, -1.2)},
            [0.30] = {RightLeg = CFrame.Angles(math.rad(100), 0, 0)},
            [0.50] = {},
        },
    },
    throw = {
        duration = 0.6,
        frames = {
            [0.0]  = {LeftArm = CFrame.Angles(math.rad(70), 0, 0), RightArm = CFrame.Angles(math.rad(70), 0, 0)},
            [0.2]  = {LeftArm = CFrame.Angles(math.rad(120), 0, 0), RightArm = CFrame.Angles(math.rad(120), 0, 0)},
            [0.4]  = {LeftArm = CFrame.Angles(math.rad(160), 0, 0), RightArm = CFrame.Angles(math.rad(160), 0, 0)},
            [0.6]  = {},
        },
    },
    special = {
        duration = 0.9,
        frames = {
            [0.0]  = {LeftArm = CFrame.Angles(math.rad(100), 0, 0), RightArm = CFrame.Angles(math.rad(100), 0, 0)},
            [0.25] = {LeftArm = CFrame.Angles(math.rad(130), 0, 0), RightArm = CFrame.Angles(math.rad(130), 0, 0)},
            [0.55] = {LeftArm = CFrame.Angles(math.rad(60), 0, 0), RightArm = CFrame.Angles(math.rad(60), 0, 0)},
            [0.9]  = {},
        },
    },
    hit = {
        duration = 0.3,
        frames = {
            [0.0]  = {Torso = CFrame.Angles(math.rad(-12), 0, 0)},
            [0.3]  = {},
        },
    },
}

function MoveAnimator.Play(model, moveName)
    local pose = POSES[moveName]
    if not pose or not model then return end
    local joints = {}
    local function grabJ(partName)
        local p = model:FindFirstChild(partName)
        if p then
            local m = p:FindFirstChildOfClass("Motor6D")
            if m then joints[partName] = {motor = m, c0 = m.C0} end
        end
    end
    grabJ("Torso"); grabJ("LeftArm"); grabJ("RightArm"); grabJ("LeftLeg"); grabJ("RightLeg")
    grabJ("FistL"); grabJ("FistR"); grabJ("FootL"); grabJ("FootR")
    -- Fists/feet were welded from arm/leg with C0 offsets; our weld names: motor parented in armL etc with names default.
    -- Map: FistL motor parent = LeftArm; find by Part1 name instead:
    for _, p in ipairs(model:GetDescendants()) do
        if p:IsA("Motor6D") then
            local p1name = p.Part1 and p.Part1.Name
            if p1name == "FistL" or p1name == "FistR" or p1name == "FootL" or p1name == "FootR" then
                joints[p1name] = {motor = p, c0 = p.C0}
            end
        end
    end

    task.spawn(function()
        local started = os.clock()
        local frameKeys = {}
        for t, _ in pairs(pose.frames) do table.insert(frameKeys, t) end
        table.sort(frameKeys)
        local duration = pose.duration
        while true do
            local elapsed = os.clock() - started
            if elapsed >= duration then break end
            -- find current keyframe (last frame <= elapsed) and next frame
            local curT, nextT = nil, nil
            for i, t in ipairs(frameKeys) do
                if t <= elapsed then curT = t else nextT = t break end
            end
            if curT == nil then curT = 0 end
            if nextT == nil then nextT = duration end
            local span = nextT - curT
            local alpha = span > 0 and (elapsed - curT) / span or 1
            local cur = pose.frames[curT] or {}
            local nxt = pose.frames[nextT] or {}
            -- apply to every joint we have: interpolate between cur[n] and nxt[n] (or rest)
            for jointName, j in pairs(joints) do
                local a = cur[jointName] or CFrame.identity
                local b = nxt[jointName] or j.c0 -- "empty" final frame means back to rest C0
                if nxt == {} then b = j.c0 end
                -- lerp CFrame -> CFrame
                j.motor.Transform = a:Lerp(b == j.c0 and CFrame.identity or b, alpha)
            end
            task.wait()
        end
        for _, j in pairs(joints) do
            j.motor.Transform = CFrame.identity
        end
    end)
    return true
end

return MoveAnimator