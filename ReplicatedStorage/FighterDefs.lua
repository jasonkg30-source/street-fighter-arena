 --!strict
-- FighterDefs: 8 SF2-inspired fighters (original names/looks, homage mechanics).
-- Each: color theme, stat multipliers, and 4 moves (punch/kick/throw/special).
-- Special moves are implemented server-side in CombatServer via specialId switch.

export type MoveDef = {
    id: string,
    name: string,
    cooldown: number,
    damage: number,
    range: number,
    knockback: number,
    projectile: boolean,
    speed: number?,
    vertical: boolean?,
    invuln: number?,
    hits: number?,
}

export type FighterDef = {
    id: string,
    name: string,
    title: string,
    theme: {Color3},
    bodyColor: Color3,
    accentColor: Color3,
    healthMult: number,
    speedMult: number,
    moves: {[string]: MoveDef},
}

local FightDefs: {[string]: FighterDef} = {}

local defs: {FighterDef} = {
    {
        id = "RYU",
        name = "Ryu",
        title = "The Wandering Warrior",
        theme = {Color3.fromRGB(240,240,240), Color3.fromRGB(200,40,40)},
        bodyColor = Color3.fromRGB(240,240,240),
        accentColor = Color3.fromRGB(200,40,40),
        healthMult = 1.0,
        speedMult = 1.0,
        moves = {
            punch  = {id="Hadouken", name="Hadouken", cooldown=2.2, damage=16, range=70, knockback=20, projectile=true, speed=60},
            kick   = {id="Shoryuken", name="Shoryuken", cooldown=1.6, damage=22, range=7, knockback=28, projectile=false, vertical=true},
            throw  = {id="SeoiNage", name=" Shoulder Throw", cooldown=1.4, damage=18, range=6, knockback=30, projectile=false},
            special= {id="ShinkuHadouken", name="Shinku Hadouken", cooldown=6, damage=40, range=90, knockback=45, projectile=true, speed=78},
        },
    },
    {
        id = "KEN",
        name = "Ken",
        title = "The Blazing Fist",
        theme = {Color3.fromRGB(240,240,240), Color3.fromRGB(240,150,40)},
        bodyColor = Color3.fromRGB(240,240,240),
        accentColor = Color3.fromRGB(240,150,40),
        healthMult = 1.0,
        speedMult = 1.05,
        moves = {
            punch  = {id="Hadouken", name="Hadouken", cooldown=2.2, damage=16, range=70, knockback=20, projectile=true, speed=60},
            kick   = {id="Shoryuken", name="Shoryuken (Flame)", cooldown=1.6, damage=24, range=7, knockback=30, projectile=false, vertical=true},
            throw  = {id="SeoiNage", name=" Shoulder Throw", cooldown=1.4, damage=18, range=6, knockback=30, projectile=false},
            special= {id="Shoryureppa", name="Shoryureppa", cooldown=6, damage=36, range=9, knockback=30, projectile=false, vertical=true, hits=3},
        },
    },
    {
        id = "CHUNLI",
        name = "Chun-Li",
        title = "The Interpol Agent",
        theme = {Color3.fromRGB(70,140,220), Color3.fromRGB(240,220,120)},
        bodyColor = Color3.fromRGB(70,140,220),
        accentColor = Color3.fromRGB(240,220,120),
        healthMult = 0.92,
        speedMult = 1.18,
        moves = {
            punch  = {id="RenkoHa", name="Lightning Fists", cooldown=2.0, damage=14, range=6, knockback=10, projectile=false, hits=3},
            kick   = {id="Hyakuretsukyaku", name="Hundred Fists Kick", cooldown=2.4, damage=8, range=24, knockback=14, projectile=false, hits=6},
            throw  = {id="Koshuto", name="Hip Toss", cooldown=1.3, damage=17, range=6, knockback=28, projectile=false},
            special= {id="Senretsukyaku", name="Senretsu Kyaku", cooldown=6, damage=34, range=30, knockback=24, projectile=false, hits=8},
        },
    },
    {
        id = "BLANKA",
        name = "Blanka",
        title = "The Jungle Beast",
        theme = {Color3.fromRGB(90,200,80), Color3.fromRGB(250,220,60)},
        bodyColor = Color3.fromRGB(90,200,80),
        accentColor = Color3.fromRGB(250,220,60),
        healthMult = 1.08,
        speedMult = 1.05,
        moves = {
            punch  = {id="RollingAttack", name="Rolling Attack", cooldown=2.6, damage=18, range=40, knockback=26, projectile=false, speed=44},
            kick   = {id="VerticalRoll", name="Vertical Roll", cooldown=1.8, damage=20, range=8, knockback=24, projectile=false, vertical=true},
            throw  = {id="BackstepThrow", name="Beast Toss", cooldown=1.4, damage=19, range=6, knockback=30, projectile=false},
            special= {id="ElectricThunder", name="Electric Thunder", cooldown=5, damage=30, range=8, knockback=18, projectile=false, hits=5},
        },
    },
    {
        id = "EHONDA",
        name = "E. Honda",
        title = "The Sumo Champion",
        theme = {Color3.fromRGB(250,200,220), Color3.fromRGB(60,90,160)},
        bodyColor = Color3.fromRGB(250,200,220),
        accentColor = Color3.fromRGB(60,90,160),
        healthMult = 1.18,
        speedMult = 0.9,
        moves = {
            punch  = {id="HyakuretsuHundred", name="Hyakuretsu Hundred Hands", cooldown=2.1, damage=6, range=7, knockback=8, projectile=false, hits=8},
            kick   = {id="SumoSmash", name="Sumo Crush", cooldown=1.7, damage=22, range=8, knockback=26, projectile=false},
            throw  = {id="OichoThrow", name="Oicho Throw", cooldown=1.3, damage=20, range=6, knockback=30, projectile=false},
            special= {id="SuperZutsuki", name="Super Headbutt", cooldown=6, damage=36, range=34, knockback=32, projectile=false, speed=40},
        },
    },
    {
        id = "ZANGIEF",
        name = "Zangief",
        title = "The Red Cyclone",
        theme = {Color3.fromRGB(220,80,80), Color3.fromRGB(60,60,70)},
        bodyColor = Color3.fromRGB(220,80,80),
        accentColor = Color3.fromRGB(60,60,70),
        healthMult = 1.22,
        speedMult = 0.86,
        moves = {
            punch  = {id="SpinningPiledriver", name="Spinning Piledriver", cooldown=1.8, damage=24, range=7, knockback=10, projectile=false, hitstun2=true},
            kick   = {id="DoubleLariat", name="Double Lariat", cooldown=1.7, damage=20, range=9, knockback=22, projectile=false},
            throw  = {id="ScrewPiledriver", name="Screw Piledriver", cooldown=1.3, damage=26, range=6, knockback=32, projectile=false},
            special= {id="FinalAtomicBuster", name="Final Atomic Buster", cooldown=6, damage=42, range=7, knockback=10, projectile=false, hitstun2=true},
        },
    },
    {
        id = "GUILE",
        name = "Guile",
        title = "The Air Force Hero",
        theme = {Color3.fromRGB(70,190,110), Color3.fromRGB(240,240,240)},
        bodyColor = Color3.fromRGB(70,190,110),
        accentColor = Color3.fromRGB(240,240,240),
        healthMult = 1.0,
        speedMult = 1.0,
        moves = {
            punch  = {id="SonicBoom", name="Sonic Boom", cooldown=2.4, damage=14, range=64, knockback=18, projectile=true, speed=55},
            kick   = {id="FlashKick", name="Flash Kick", cooldown=1.8, damage=22, range=8, knockback=26, projectile=false, vertical=true},
            throw  = {id="JudoThrow", name="Judo Throw", cooldown=1.4, damage=18, range=6, knockback=28, projectile=false},
            special= {id="SonicTempest", name="Sonic Tempest", cooldown=6.5, damage=38, range=84, knockback=40, projectile=true, speed=80, hits=2},
        },
    },
    {
        id = "DHAISIM",
        name = "Dhalsim",
        title = "The Yoga Master",
        theme = {Color3.fromRGB(230,180,120), Color3.fromRGB(240,90,60)},
        bodyColor = Color3.fromRGB(230,180,120),
        accentColor = Color3.fromRGB(240,90,60),
        healthMult = 0.9,
        speedMult = 0.96,
        moves = {
            punch  = {id="YogaFire", name="Yoga Fire", cooldown=2.2, damage=15, range=66, knockback=18, projectile=true, speed=48},
            kick   = {id="YogaFlame", name="Yoga Flame", cooldown=2.0, damage=20, range=10, knockback=22, projectile=false},
            throw  = {id="YogaTeleportThrow", name="Yoga Teleport Throw", cooldown=1.4, damage=17, range=7, knockback=30, projectile=false},
            special= {id="YogaBlast", name="Yoga Blast", cooldown=6, damage=34, range=80, knockback=36, projectile=true, speed=70, hits=3},
        },
    },
}

for _, def in ipairs(defs) do
    FightDefs[def.id] = def
end

local FighterDefs = {}
FighterDefs.list = defs
FighterDefs.byId = FightDefs
FighterDefs.ids = (function()
    local t = {}
    for _, d in ipairs(defs) do table.insert(t, d.id) end
    return t
end)()

function FighterDefs.get(id)
    return FightDefs[id]
end

return FighterDefs