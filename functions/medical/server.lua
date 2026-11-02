-- Injuries and death, revive and respawn hooks across death scripts. Loading the module registers every tracker, so
-- qb-ambulancejob's client-synced limbs reach getInjuries once any code in the resource has touched Z.medical
--
-- A death script zyke_lib has no wiring for can fire these local server events:
-- "zyke_lib:playerDied" (plyId, weapon?) and "zyke_lib:playerRevived" (plyId, reviverId?), where no reviverId is a respawn.
-- For wasabi_ambulance_v2, add them to its listeners in wasabi_ambulance_v2/bridge/listeners/server.lua:
--
-- function listeners.onDeath(source, deathData)
--     TriggerEvent("zyke_lib:playerDied", source, deathData and deathData.cause)
-- end
--
-- function listeners.onRevive(source, reviver, method)
--     TriggerEvent("zyke_lib:playerRevived", source, method == "player" and reviver or nil)
-- end

---@alias BodyPart "head" | "neck" | "chest" | "abdomen" | "back" | "pelvis" | "leftArm" | "rightArm" | "leftLeg" | "rightLeg"

---@class MedicalInjury
---@field part BodyPart
---@field severity integer @ 1 to 4
---@field kind? "gunshot" | "laceration" | "fracture" | "burn" | "blunt" | "other" @ Only when the script names it
---@field weapon? integer @ Weapon hash that caused it, only when the script tracks it per body part

---@class MedicalInjuries
---@field system string @ DeathSystem, or "ped" without one
---@field injuries MedicalInjury[]
---@field weapons integer[] @ Weapon hashes that caused damage, signed or unsigned as the script gives them
---@field bleeding? number @ The script's bleed level, 0 to 4 for qb-ambulancejob, qbx_medical and osp_ambulance

Functions.medical = {}

-- The limbs of qb-ambulancejob and qbx_medical
local qbBodyParts = {
    HEAD = "head", NECK = "neck", SPINE = "back", UPPER_BODY = "chest", LOWER_BODY = "abdomen",
    LARM = "leftArm", LHAND = "leftArm", LFINGER = "leftArm", LLEG = "leftLeg", LFOOT = "leftLeg",
    RARM = "rightArm", RHAND = "rightArm", RFINGER = "rightArm", RLEG = "rightLeg", RFOOT = "rightLeg",
}

-- Keys of wasabi_ambulance_v2's getPlayerInjuryTotals
local wasabiKinds = {cut = "laceration", brokenbone = "fracture", blunt = "blunt", gunshot = "gunshot", fist = "blunt", taser = "other", burn = "burn"}

-- The body parts of osp_ambulance
local ospBodyParts = {Head = "head", Torso = "chest", Larm = "leftArm", Rarm = "rightArm", Lleg = "leftLeg", Rleg = "rightLeg"}

-- osp_ambulance's wounds (Config.Wounds) as a kind and a severity of 1 to 4
---@type table<string, {kind: string, severity: integer}>
local ospWounds = {
    abrasion = {kind = "laceration", severity = 1},
    contusion = {kind = "blunt", severity = 1},
    cut = {kind = "laceration", severity = 2},
    laceration = {kind = "laceration", severity = 2},
    avulsion = {kind = "laceration", severity = 3},
    puncturewound = {kind = "laceration", severity = 3},
    crush = {kind = "blunt", severity = 3},
    lowvelocitywound = {kind = "gunshot", severity = 2},
    mediumvelocitywound = {kind = "gunshot", severity = 3},
    highvelocitywound = {kind = "gunshot", severity = 4},
    -- Shotguns and explosives
    velocitywound = {kind = "gunshot", severity = 3},
    burn = {kind = "burn", severity = 3},
}

-- Blood lost per second by one body part that makes its injuries a step worse
local ospSevereBleeding = 0.3

-- qbx_medical's DEAD death state
local qbxDead = 3

---@type {death: fun(plyId: PlayerId, weapon?: integer)[], revive: fun(plyId: PlayerId, reviverId: PlayerId)[], respawn: fun(plyId: PlayerId)[]}
local handlers = {death = {}, revive = {}, respawn = {}}

-- What the death scripts sent per player
---@type table<PlayerId, {dead?: boolean, weapon?: integer, limbs?: table, bleeding?: number, wounds?: table}>
local reported = {}

---@param plyId PlayerId
---@return {dead?: boolean, weapon?: integer, limbs?: table, bleeding?: number, wounds?: table} entry
local function getReported(plyId)
    local entry = reported[plyId] or {}

    reported[plyId] = entry

    return entry
end

---@param value any
---@return integer? hash
local function toHash(value)
    return math.tointeger(tonumber(value))
end

-- Death scripts send packets as a character unloads, which must not report for it, so only a loaded character counts
---@param plyId PlayerId
---@param weapon? integer
local function died(plyId, weapon)
    if (not Functions.getPlayerData(plyId)) then return end

    local entry = getReported(plyId)

    entry.dead = true
    entry.weapon = weapon

    for i = 1, #handlers.death do
        handlers.death[i](plyId, weapon)
    end
end

---@param plyId PlayerId
---@param reviverId? PlayerId @ nil when they respawned or were revived without a player
local function revived(plyId, reviverId)
    if (not Functions.getPlayerData(plyId)) then return end

    local entry = getReported(plyId)

    entry.dead = nil
    entry.weapon = nil

    if (reviverId) then
        for i = 1, #handlers.revive do
            handlers.revive[i](plyId, reviverId)
        end

        return
    end

    for i = 1, #handlers.respawn do
        handlers.respawn[i](plyId)
    end
end

-- Adds an injury, keeping one per body part at its highest severity
---@param injuries MedicalInjury[]
---@param injury MedicalInjury
local function addInjury(injuries, injury)
    for i = 1, #injuries do
        local existing = injuries[i]

        if (existing.part == injury.part) then
            if (injury.severity > existing.severity) then injuries[i] = injury end

            return
        end
    end

    injuries[#injuries + 1] = injury
end

---@param weapons integer[]
---@param hash? integer
local function addWeapon(weapons, hash)
    if (not hash) then return end

    for i = 1, #weapons do
        if (weapons[i] == hash) then return end
    end

    weapons[#weapons + 1] = hash
end

---@param plyId PlayerId
---@param reading MedicalInjuries
local function readWasabi(plyId, reading)
    local totals = exports["wasabi_ambulance_v2"]:getPlayerInjuryTotals(plyId) or {}

    -- Its totals count injuries by type without limbs, so they all go on the chest
    for key, count in pairs(totals) do
        local amount = math.tointeger(tonumber(count)) or 0

        if (wasabiKinds[key] and amount > 0) then reading.injuries[#reading.injuries + 1] = {part = "chest", kind = wasabiKinds[key], severity = math.min(4, amount)} end
    end
end

-- qbx_medical keeps each injured limb as {severity, weaponHash} in a replicated state bag
---@param plyId PlayerId
---@param reading MedicalInjuries
local function readQbx(plyId, reading)
    local state = Player(plyId).state

    for key, part in pairs(qbBodyParts) do
        local injury = state["qbx_medical:injuries:" .. key]

        if (type(injury) == "table") then
            local weapon = toHash(injury.weaponHash)

            addInjury(reading.injuries, {part = part, severity = math.max(1, math.min(4, math.tointeger(tonumber(injury.severity)) or 1)), weapon = weapon})
            addWeapon(reading.weapons, weapon)
        end
    end

    reading.bleeding = tonumber(state["qbx_medical:bleedLevel"])
end

-- qb-ambulancejob: the limbs and weapon wounds its client syncs to the server
---@param plyId PlayerId
---@param reading MedicalInjuries
local function readQb(plyId, reading)
    local entry = getReported(plyId)
    local limbs = type(entry.limbs) == "table" and entry.limbs or {}

    for key, limb in pairs(limbs) do
        if (qbBodyParts[key] and type(limb) == "table" and limb.isDamaged) then
            addInjury(reading.injuries, {part = qbBodyParts[key], severity = math.max(1, math.min(4, math.tointeger(tonumber(limb.severity)) or 1))})
        end
    end

    for _, hash in pairs(type(entry.wounds) == "table" and entry.wounds or {}) do
        addWeapon(reading.weapons, toHash(hash))
    end

    reading.bleeding = entry.bleeding
end

-- osp_ambulance keeps each body part's wound names, fracture and blood lost per second in its replicated BodyDamage
-- state bag. It names no weapon per part, the death gives one
---@param plyId PlayerId
---@param reading MedicalInjuries
local function readOsp(plyId, reading)
    local body = Player(plyId).state.BodyDamage
    local damage = type(body) == "table" and type(body.BodyPartDamage) == "table" and body.BodyPartDamage or {}
    local wounds = type(damage.Wounds) == "table" and damage.Wounds or {}
    local fractures = type(damage.Fractures) == "table" and damage.Fractures or {}
    local bleeding = type(damage.Bleeding) == "table" and damage.Bleeding or {}
    local totalBleeding = 0.0

    for key, part in pairs(ospBodyParts) do
        local partBleeding = tonumber(bleeding[key]) or 0.0
        local bleedStep = partBleeding >= ospSevereBleeding and 1 or 0

        totalBleeding += partBleeding

        for _, name in pairs(type(wounds[key]) == "table" and wounds[key] or {}) do
            local wound = ospWounds[name]

            if (wound) then addInjury(reading.injuries, {part = part, kind = wound.kind, severity = math.min(4, wound.severity + bleedStep)}) end
        end

        -- "xrayed" is a fracture a medic has found, still broken
        if (fractures[key] == true or fractures[key] == "xrayed") then
            addInjury(reading.injuries, {part = part, kind = "fracture", severity = math.min(4, 3 + bleedStep)})
        end
    end

    reading.bleeding = totalBleeding >= 1.0 and 4 or totalBleeding >= 0.6 and 3 or totalBleeding >= ospSevereBleeding and 2 or totalBleeding > 0.0 and 1 or 0
end

-- The player's injuries now. esx_ambulancejob and scripts without an adapter only give the weapon of their last death
---@param plyId PlayerId
---@return MedicalInjuries reading
function Functions.medical.getInjuries(plyId)
    ---@type MedicalInjuries
    local reading = {system = DeathSystem or "ped", injuries = {}, weapons = {}}

    if (DeathSystem == "wasabi_ambulance_v2") then
        readWasabi(plyId, reading)
    elseif (DeathSystem == "qbx_medical") then
        readQbx(plyId, reading)
    elseif (DeathSystem == "qb-ambulancejob") then
        readQb(plyId, reading)
    elseif (DeathSystem == "osp_ambulance") then
        readOsp(plyId, reading)
    end

    local entry = reported[plyId]

    addWeapon(reading.weapons, entry and entry.weapon)

    return reading
end

---@param fn fun(plyId: PlayerId, weapon?: integer) @ weapon is the hash that killed them, when the script names it
function Functions.medical.onDeath(fn)
    handlers.death[#handlers.death + 1] = fn
end

---@param fn fun(plyId: PlayerId, reviverId: PlayerId) @ Revived by another player
function Functions.medical.onRevive(fn)
    handlers.revive[#handlers.revive + 1] = fn
end

---@param fn fun(plyId: PlayerId) @ Respawned, or revived without a player
function Functions.medical.onRespawn(fn)
    handlers.respawn[#handlers.respawn + 1] = fn
end

-- QBCore and Qbox keep it in players.metadata.bloodtype, ESX has none
---@param identifier CharacterIdentifier
---@return string? bloodType @ Such as "O+"
function Functions.medical.getBloodType(identifier)
    if (Framework ~= "QB") then return nil end

    local player = Functions.getPlayerData(identifier)
    if (player) then return player.PlayerData.metadata.bloodtype end

    return MySQL.scalar.await("SELECT JSON_UNQUOTE(JSON_EXTRACT(`metadata`, '$.bloodtype')) FROM `players` WHERE `citizenid` = ?", {identifier})
end

---@param plyId PlayerId
---@param weapon? integer
AddEventHandler("zyke_lib:playerDied", function(plyId, weapon)
    local id = math.tointeger(tonumber(plyId))
    if (not id) then return end

    died(id, toHash(weapon))
end)

---@param plyId PlayerId
---@param reviverId? PlayerId @ The player who revived them, nil for a respawn
AddEventHandler("zyke_lib:playerRevived", function(plyId, reviverId)
    local id = math.tointeger(tonumber(plyId))
    if (not id) then return end

    revived(id, math.tointeger(tonumber(reviverId)))
end)

-- esx_ambulancejob: esx:onPlayerDeath comes from the dying player's client with the weapon that killed them, the revive
-- from the medic's client, so only a death heard here counts for a revive
if (DeathSystem == "esx_ambulancejob") then
    ---@param data {deathCause?: integer}
    RegisterNetEvent("esx:onPlayerDeath", function(data)
        died(source, type(data) == "table" and toHash(data.deathCause) or nil)
    end)

    ---@param targetId integer @ The player the medic revives
    RegisterNetEvent("esx_ambulancejob:revive", function(targetId)
        local reviverId = source
        local patientId = math.tointeger(tonumber(targetId))
        if (not patientId or patientId == reviverId) then return end
        if (not (reported[patientId] and reported[patientId].dead)) then return end

        revived(patientId, reviverId)
    end)

    RegisterNetEvent("esx:onPlayerSpawn", function()
        local plyId = source
        if (not (reported[plyId] and reported[plyId].dead)) then return end

        revived(plyId)
    end)
end

-- qb-ambulancejob: its client sends the limbs, weapon wounds and death state, the revive comes from the medic's client
if (DeathSystem == "qb-ambulancejob") then
    ---@param data {limbs?: table, isBleeding?: number}
    RegisterNetEvent("hospital:server:SyncInjuries", function(data)
        if (type(data) ~= "table") then return end

        local entry = getReported(source)

        entry.limbs = data.limbs
        entry.bleeding = tonumber(data.isBleeding)
    end)

    ---@param data integer[] @ Weapon hashes, the latest last
    RegisterNetEvent("hospital:server:SetWeaponDamage", function(data)
        if (type(data) == "table") then getReported(source).wounds = data end
    end)

    RegisterNetEvent("hospital:server:RestoreWeaponDamage", function()
        getReported(source).wounds = nil
    end)

    ---@param dead boolean
    RegisterNetEvent("hospital:server:SetDeathStatus", function(dead)
        local plyId = source
        local entry = getReported(plyId)

        if (dead == true) then
            local wounds = type(entry.wounds) == "table" and entry.wounds or {}

            return died(plyId, toHash(wounds[#wounds]))
        end

        if (entry.dead) then revived(plyId) end
    end)

    ---@param targetId integer @ The player the medic revives
    ---@param isOldMan? boolean @ Revived by the NPC doctor
    RegisterNetEvent("hospital:server:RevivePlayer", function(targetId, isOldMan)
        local reviverId = source
        local patientId = math.tointeger(tonumber(targetId))
        if (not patientId or patientId == reviverId) then return end

        -- A medic may revive from last stand, which sends no death
        if (not (reported[patientId] and reported[patientId].dead) and not Functions.isPlayerDead(patientId)) then return end

        revived(patientId, not isOldMan and reviverId or nil)
    end)
end

-- qbx_medical sets its death state in a replicated state bag and fires no revive with the reviver, a revive script can
-- fire zyke_lib:playerRevived for that
if (DeathSystem == "qbx_medical") then
    ---@param bagName string
    ---@param value integer @ 1 alive, 2 last stand, 3 dead
    AddStateBagChangeHandler("qbx_medical:deathState", "", function(bagName, _, value)
        if (value ~= qbxDead) then return end

        local plyId = GetPlayerFromStateBagName(bagName)
        if (not plyId or plyId == 0) then return end

        -- The weapon of the worst injury stands in for the cause, qbx_medical keeps none
        local reading = {system = DeathSystem, injuries = {}, weapons = {}}

        readQbx(plyId, reading)

        local worst = nil

        for i = 1, #reading.injuries do
            local injury = reading.injuries[i]

            if (injury.weapon and (not worst or injury.severity > worst.severity)) then worst = injury end
        end

        died(plyId, worst and worst.weapon)
    end)

    ---@param plyId PlayerId
    AddEventHandler("qbx_medical:server:playerRespawned", function(plyId)
        revived(plyId)
    end)
end

-- osp_ambulance keeps isDead in its replicated BodyDamage state bag, and its client sends hospital:server:SetDeathStatus
-- on QBCore. It fires no revive with the reviver, a revive script can fire zyke_lib:playerRevived for that
if (DeathSystem == "osp_ambulance") then
    ---@param plyId PlayerId
    local function ospDied(plyId)
        if (reported[plyId] and reported[plyId].dead) then return end

        local ped = GetPlayerPed(plyId)
        local hash = ped ~= 0 and GetPedCauseOfDeath(ped) or 0

        died(plyId, hash ~= 0 and hash or nil)
    end

    -- Only a death counts here, osp_ambulance also sends false when a dead character unloads
    ---@param dead boolean
    RegisterNetEvent("hospital:server:SetDeathStatus", function(dead)
        if (dead == true) then ospDied(source) end
    end)

    -- The revives and respawns in osp_ambulance's open code end by replicating BodyDamage, so recoveries come from here
    ---@param bagName string
    ---@param value? {isDead?: boolean}
    AddStateBagChangeHandler("BodyDamage", "", function(bagName, _, value)
        if (type(value) ~= "table") then return end

        local plyId = GetPlayerFromStateBagName(bagName)
        if (not plyId or plyId == 0) then return end
        if (value.isDead == true) then return ospDied(plyId) end

        if (reported[plyId] and reported[plyId].dead) then revived(plyId) end
    end)
end

-- Also fired when a player drops. The next character starts clean, a dead one loads its death again from its script
---@param plyId PlayerId
AddEventHandler("zyke_lib:OnCharacterLogout", function(plyId)
    reported[plyId] = nil
end)

return Functions.medical