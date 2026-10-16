local RemoteSetup = {}

local RS = game:GetService("ReplicatedStorage")

local NAMES = {
    "SFRemotes",
    "SelectFighter",
    "ReportMove",
    "FightState",
    "MovePlayed",
    "HitFX",
}

function RemoteSetup.Get()
    local folder = RS:FindFirstChild(NAMES[1]) or Instance.new("Folder")
    folder.Name = NAMES[1]
    local function ensure(className, name)
        local inst = folder:FindFirstChild(name) or Instance.new(className)
        inst.Name = name
        inst.Parent = folder
        return inst
    end
    local selectFighter = ensure("RemoteEvent", NAMES[2])
    local report = ensure("RemoteEvent", NAMES[3])
    local stateValue = ensure("Folder", NAMES[4])
    local movePlayed = ensure("RemoteEvent", NAMES[5])
    local hitFX = ensure("RemoteEvent", NAMES[6])
    local events = {
        SelectFighter = selectFighter,
        ReportMove = report,
        State = stateValue,
        MovePlayed = movePlayed,
        HitFX = hitFX,
        Folder = folder,
    }
    return events
end

return RemoteSetup