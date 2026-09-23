Config = {}

Config.Locale = 'en' -- 'en' | 'es'

Config.IntervalMinutes = 5
Config.Warnings = { 60, 30, 10 }

-- A vehicle is kept if ANY of these apply
Config.RecentUseSeconds = 180       -- someone was inside it recently
Config.GraceSeconds = 120           -- it was spawned recently
Config.NearbyPlayerDistance = 30.0  -- a player is this close, same routing bucket (0 = off)
Config.OwnerDistance = 100.0        -- its owner is online and this close, same routing bucket (0 = off)

-- State bag keys checked to find a vehicle's owner (citizenid / identifier / license)
Config.OwnerStateKeys = { 'ownercid', 'owner', 'citizenid' }

-- Models that are never removed
Config.IgnoreModels = {
    -- 'police',
    -- 'ambulance',
}

Config.Notify = {
    chat = true,
    oxlib = true, -- only used if ox_lib is started
}

-- Restricted with ACE: add_ace group.admin command.<name> allow
Config.Commands = {
    clean = 'cleanvehicles',
    protect = 'protectvehicle',
    info = 'cleanupinfo',
}

Config.TrackSeconds = 10
