local firstSeen = {}
local lastUsed = {}
local ignored = {}

local nextCleanupAt = os.time() + Config.IntervalMinutes * 60
local warned = {}
local lastReport

for _, model in ipairs(Config.IgnoreModels) do
    ignored[joaat(model)] = true
end

local framework, core

local function detectFramework()
    if GetResourceState('qbx_core') == 'started' then
        framework = 'qbx'
    elseif GetResourceState('qb-core') == 'started' then
        framework = 'qb'
        core = exports['qb-core']:GetCoreObject()
    elseif GetResourceState('es_extended') == 'started' then
        framework = 'esx'
        core = exports.es_extended:getSharedObject()
    end
end

local function getPlayerKeys(src)
    local keys = {}

    if not framework then detectFramework() end

    if framework == 'qbx' then
        local player = exports.qbx_core:GetPlayer(src)
        if player then keys[#keys + 1] = player.PlayerData.citizenid end
    elseif framework == 'qb' then
        local player = core.Functions.GetPlayer(src)
        if player then keys[#keys + 1] = player.PlayerData.citizenid end
    elseif framework == 'esx' then
        local player = core.GetPlayerFromId(src)
        if player then keys[#keys + 1] = player.identifier end
    end

    local license = GetPlayerIdentifierByType(src, 'license')
    if license then keys[#keys + 1] = license end

    return keys
end

local function getOwner(veh)
    local state = Entity(veh).state

    for _, key in ipairs(Config.OwnerStateKeys) do
        local value = state[key]
        if value then return value end
    end
end

local function broadcast(message, notifyType)
    if Config.Notify.chat then
        TriggerClientEvent('chat:addMessage', -1, {
            args = { ('^3[%s]^7 %s'):format(L('title'), message) },
        })
    end

    if Config.Notify.oxlib and GetResourceState('ox_lib') == 'started' then
        TriggerClientEvent('ox_lib:notify', -1, {
            title = L('title'),
            description = message,
            type = notifyType or 'inform',
            duration = 7000,
        })
    end
end

local function reply(src, message)
    if src == 0 then
        return print(message)
    end

    TriggerClientEvent('chat:addMessage', src, {
        args = { ('^3[%s]^7 %s'):format(L('title'), message) },
    })
end

local function snapshotPlayers()
    local occupied, players, owners = {}, {}, {}

    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        local ped = GetPlayerPed(src)

        if ped ~= 0 and DoesEntityExist(ped) then
            local veh = GetVehiclePedIsIn(ped, false)
            if veh ~= 0 then occupied[veh] = true end

            local info = { coords = GetEntityCoords(ped), bucket = GetPlayerRoutingBucket(src) }
            players[#players + 1] = info

            for _, key in ipairs(getPlayerKeys(src)) do
                owners[key] = info
            end
        end
    end

    return occupied, players, owners
end

CreateThread(function()
    while true do
        local now = os.time()
        local occupied = snapshotPlayers()
        local alive = {}

        for _, veh in ipairs(GetAllVehicles()) do
            alive[veh] = true
            firstSeen[veh] = firstSeen[veh] or now
            if occupied[veh] then lastUsed[veh] = now end
        end

        for veh in pairs(firstSeen) do
            if not alive[veh] then
                firstSeen[veh] = nil
                lastUsed[veh] = nil
            end
        end

        Wait(Config.TrackSeconds * 1000)
    end
end)

local function isNear(info, coords, bucket, distance)
    return info.bucket == bucket and #(info.coords - coords) <= distance
end

local function keepReason(veh, now, occupied, players, owners)
    if occupied[veh] then return 'occupied' end
    if Entity(veh).state.cleanupProtected then return 'protected' end
    if ignored[GetEntityModel(veh)] then return 'ignored' end
    if now - (firstSeen[veh] or now) < Config.GraceSeconds then return 'fresh' end
    if lastUsed[veh] and now - lastUsed[veh] < Config.RecentUseSeconds then return 'recent' end

    local coords = GetEntityCoords(veh)
    local bucket = GetEntityRoutingBucket(veh)

    if Config.OwnerDistance > 0 then
        local owner = getOwner(veh)
        local info = owner and owners[owner]
        if info and isNear(info, coords, bucket, Config.OwnerDistance) then return 'owner' end
    end

    if Config.NearbyPlayerDistance > 0 then
        for i = 1, #players do
            if isNear(players[i], coords, bucket, Config.NearbyPlayerDistance) then return 'nearby' end
        end
    end
end

local function cleanup()
    local now = os.time()
    local occupied, players, owners = snapshotPlayers()
    local report = { at = now, removed = 0, kept = 0, reasons = {} }

    for _, veh in ipairs(GetAllVehicles()) do
        if DoesEntityExist(veh) then
            local reason = keepReason(veh, now, occupied, players, owners)

            if reason then
                report.kept = report.kept + 1
                report.reasons[reason] = (report.reasons[reason] or 0) + 1
            else
                local ok, err = pcall(TriggerEvent, 'mkl_cleanup:beforeDelete', veh, {
                    model = GetEntityModel(veh),
                    plate = GetVehicleNumberPlateText(veh),
                    owner = getOwner(veh),
                    bucket = GetEntityRoutingBucket(veh),
                })

                if not ok then
                    print(('^1[mkl_cleanup] beforeDelete handler error: %s^7'):format(err))
                end

                DeleteEntity(veh)
                firstSeen[veh] = nil
                lastUsed[veh] = nil
                report.removed = report.removed + 1
            end
        end
    end

    lastReport = report

    local parts = {}
    for reason, count in pairs(report.reasons) do
        parts[#parts + 1] = ('%s=%s'):format(reason, count)
    end
    table.sort(parts)

    print(('[mkl_cleanup] removed %s, kept %s (%s)'):format(report.removed, report.kept, table.concat(parts, ', ')))

    if report.removed > 0 then
        broadcast(L('done', report.removed, Config.IntervalMinutes), 'success')
    else
        broadcast(L('nothing', Config.IntervalMinutes), 'inform')
    end

    TriggerEvent('mkl_cleanup:finished', report)
end

local function schedule(seconds)
    nextCleanupAt = os.time() + seconds
    warned = {}

    for _, s in ipairs(Config.Warnings) do
        if s > seconds then warned[s] = true end
    end
end

CreateThread(function()
    while true do
        Wait(1000)

        local remaining = nextCleanupAt - os.time()

        for _, seconds in ipairs(Config.Warnings) do
            if remaining <= seconds and remaining > 0 and not warned[seconds] then
                warned[seconds] = true
                broadcast(L('warning', seconds), seconds <= 10 and 'warning' or 'inform')
                break
            end
        end

        if remaining <= 0 then
            local ok, err = pcall(cleanup)
            if not ok then print(('^1[mkl_cleanup] cleanup failed: %s^7'):format(err)) end

            schedule(Config.IntervalMinutes * 60)
        end
    end
end)

RegisterCommand(Config.Commands.clean, function(source, args)
    local seconds = math.floor(tonumber(args[1]) or 30)
    seconds = math.max(5, math.min(600, seconds))

    schedule(seconds)
    broadcast(L('forced', seconds), 'warning')
    reply(source, L('forced_admin', seconds))
end, true)

RegisterCommand(Config.Commands.protect, function(source)
    if source == 0 then return end

    local veh = GetVehiclePedIsIn(GetPlayerPed(source), false)
    if veh == 0 then return reply(source, L('not_in_vehicle')) end

    local state = Entity(veh).state
    local protect = not state.cleanupProtected
    state:set('cleanupProtected', protect, false)

    reply(source, L(protect and 'protected' or 'unprotected'))
end, true)

RegisterCommand(Config.Commands.info, function(source)
    local remaining = math.max(0, nextCleanupAt - os.time())
    reply(source, L('next', remaining // 60, remaining % 60))

    if lastReport then
        reply(source, L('last', (os.time() - lastReport.at) // 60, lastReport.removed, lastReport.kept))
    else
        reply(source, L('no_last'))
    end
end, true)

exports('SetProtected', function(veh, state)
    if DoesEntityExist(veh) then
        Entity(veh).state:set('cleanupProtected', state and true or false, false)
    end
end)

exports('IsProtected', function(veh)
    return DoesEntityExist(veh) and Entity(veh).state.cleanupProtected == true
end)

exports('ForceCleanup', function(seconds)
    schedule(math.max(0, math.floor(tonumber(seconds) or 0)))
end)

exports('GetNextCleanup', function()
    return nextCleanupAt
end)
