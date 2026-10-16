local Config = {}

Config.Arena = {
    RingSize = 110,
    WallHeight = 14,
    CornerGap = 1.2,
    SpawnOffset = 16,
}

Config.Match = {
    WinsNeeded = 2,
    RoundSeconds = 60,
    IntermissionSeconds = 6,
    ResultSeconds = 4,
    MaxFighters = 2,
    MaxSpectators = 8,
    MaxInRing = 10,
}

Config.Combat = {
    WalkSpeedFighter = 18,
    WalkSpeedDefault = 14,
    JumpPower = 52,
    PunchDamage = 8,
    KickDamage = 12,
    ThrowDamage = 18,
    SpecialDamage = 22,
    PunchCooldown = 0.42,
    KickCooldown = 0.62,
    ThrowCooldown = 1.30,
    SpecialCooldown = 2.40,
    PunchRange = 7,
    KickRange = 8,
    ThrowRange = 6,
    MeterPerHit = 25,
    MeterOnTake = 15,
    MeterMax = 100,
    StunOnThrow = 0.55,
    KnockbackThrow = 34,
    KnockbackKick = 16,
    HitStun = 0.24,
}

Config.Colors = {
    Floor = Color3.fromRGB(72, 68, 78),
    FloorRing = Color3.fromRGB(196, 164, 62),
    Wall = Color3.fromRGB(46, 42, 54),
    Pillar = Color3.fromRGB(88, 74, 108),
    Sky = Color3.fromRGB(150, 120, 90),
    P1Ring = Color3.fromRGB(255, 92, 92),
    P2Ring = Color3.fromRGB(92, 160, 255),
    Spectator = Color3.fromRGB(220, 210, 190),
}

Config.CharSelectSeconds = 10

return Config