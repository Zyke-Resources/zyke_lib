Functions.licenses = {}

-- Names of the QBCore and Qbox licences in players.metadata.licences
local qbLicenseLabels = {
    driver = "Driver's licence",
    weapon = "Weapon licence",
    business = "Business licence",
}

---@class CharacterLicense
---@field id string
---@field label string
---@field active boolean @ The character holds it

-- Every licence the framework knows, with whether the character holds it, also while offline
---@param identifier CharacterIdentifier
---@return CharacterLicense[]? licenses @ Nil when there is no licence system
function Functions.licenses.get(identifier)
    if (Framework == "ESX") then
        if (GetResourceState("esx_license") ~= "started") then return nil end

        local rows = MySQL.query.await([[
            SELECT l.`type`, l.`label`, EXISTS(SELECT 1 FROM `user_licenses` u WHERE u.`type` = l.`type` AND u.`owner` = ?) AS `active`
            FROM `licenses` l ORDER BY l.`label`
        ]], {identifier}) or {}

        local licenses = {}

        for i = 1, #rows do
            licenses[i] = {id = rows[i].type, label = rows[i].label or rows[i].type, active = rows[i].active == 1 or rows[i].active == true}
        end

        return licenses
    end

    if (Framework ~= "QB") then return nil end

    local player = Functions.getPlayerData(identifier)
    local held = player and player.PlayerData.metadata.licences

    if (not held) then
        local stored = MySQL.scalar.await("SELECT JSON_EXTRACT(`metadata`, '$.licences') FROM `players` WHERE `citizenid` = ?", {identifier})

        held = type(stored) == "string" and json.decode(stored) or nil
    end

    if (type(held) ~= "table") then held = {} end

    local licenses = {}

    for id, label in pairs(qbLicenseLabels) do
        licenses[#licenses + 1] = {id = id, label = label, active = held[id] == true}
    end

    for id, active in pairs(held) do
        if (not qbLicenseLabels[id]) then licenses[#licenses + 1] = {id = id, label = id, active = active == true} end
    end

    table.sort(licenses, function(a, b)
        return a.label < b.label
    end)

    return licenses
end

-- Takes a licence away, also from an offline character
---@param identifier CharacterIdentifier
---@param id string @ Letters, digits and underscores only, as it is a JSON path key on QB
---@return boolean removed
function Functions.licenses.remove(identifier, id)
    if (type(id) ~= "string" or not id:match("^[%w_]+$")) then return false end

    if (Framework == "ESX") then
        if (GetResourceState("esx_license") ~= "started") then return false end

        return (tonumber(MySQL.update.await("DELETE FROM `user_licenses` WHERE `type` = ? AND `owner` = ?", {id, identifier})) or 0) > 0
    end

    if (Framework ~= "QB") then return false end

    local player = Functions.getPlayerData(identifier)

    if (player) then
        local licences = player.PlayerData.metadata.licences or {}

        licences[id] = false

        player.Functions.SetMetaData("licences", licences)

        return true
    end

    return (tonumber(MySQL.update.await("UPDATE `players` SET `metadata` = JSON_SET(`metadata`, ?, CAST('false' AS JSON)) WHERE `citizenid` = ?", {"$.licences." .. id, identifier})) or 0) > 0
end

return Functions.licenses