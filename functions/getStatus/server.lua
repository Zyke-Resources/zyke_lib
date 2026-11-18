-- A player's status from the status system (systems/status.lua), normalised to 0-100. Without a status resource,
-- QBCore's and Qbox's own player metadata answers hunger, thirst and stress. Checked against the sources on 2026-11-18:
-- zyke_status server/functions.lua and statuses/registry.lua, esx_status server/main.lua in
-- esx-framework/ESX-Legacy-Addons (the esx_status:getStatus event), qb-core config.lua and qbx_core server/player.lua

-- zyke_status's status types from its statuses/registry.lua, it answers 0 for any other name
local zykeStatuses = {addiction = true, caffeine = true, cold = true, drunk = true, high = true, hunger = true, stress = true, thirst = true}

-- zyke_status keeps these per substance (high.values.thc), with no value under their own name, so the reading is the
-- highest substance's: the strongest high, and the highest addiction level rather than the satisfaction
local zykeSubstanceFields = {high = "value", addiction = "addiction"}

-- The ones QBCore and Qbox keep in player metadata, Qbox keeps the live value in the player's state bag
local frameworkStatuses = {hunger = true, thirst = true, stress = true}

---@param plyId PlayerId
---@param name string
---@return number? value
local function getZykeStatus(plyId, name)
    if (not zykeStatuses[name]) then return nil end

    local field = zykeSubstanceFields[name]
    if (not field) then return tonumber(exports["zyke_status"]:GetStatus(plyId, {name})) end

    local statuses = exports["zyke_status"]:GetAllRawStatuses(plyId)
    local substances = type(statuses) == "table" and type(statuses[name]) == "table" and statuses[name].values
    local highest = 0.0

    for _, entry in pairs(type(substances) == "table" and substances or {}) do
        local value = type(entry) == "table" and tonumber(entry[field])
        if (value and value > highest) then highest = value end
    end

    return highest
end

---@param plyId PlayerId
---@param name string
---@return number? value
local function getEsxStatus(plyId, name)
    local value = nil

    -- esx_status calls back at once, and only for a status the player has
    ---@param status {name: string, val: number, percent: number}
    TriggerEvent("esx_status:getStatus", plyId, name, function(status)
        value = tonumber(status.percent)
    end)

    return value
end

---@param plyId PlayerId
---@param name string
---@return number? value
local function getFrameworkStatus(plyId, name)
    if (Framework ~= "QB" or not frameworkStatuses[name]) then return nil end

    if (GetResourceState("qbx_core") == "started") then
        local value = tonumber(Player(plyId).state[name])
        if (value) then return value end
    end

    local player = Functions.getPlayerData(plyId)
    local metadata = player and player.PlayerData and player.PlayerData.metadata

    return type(metadata) == "table" and tonumber(metadata[name]) or nil
end

---@param plyId PlayerId
---@param name string @ Such as "hunger", "thirst", "stress" or "drunk"
---@return number? value @ 0-100, nil when the status system has no such status for the player
function Functions.getStatus(plyId, name)
    local value = nil

    if (StatusSystem == "zyke_status") then
        value = getZykeStatus(plyId, name)
    elseif (StatusSystem == "esx_status") then
        value = getEsxStatus(plyId, name)
    else
        value = getFrameworkStatus(plyId, name)
    end

    if (not value) then return nil end

    return math.max(0.0, math.min(100.0, value + 0.0))
end

return Functions.getStatus