-- A saved inventory that holds the searched text: kind "stash" covers ox_inventory's stashes, trunks and gloveboxes,
-- "player" an offline character's inventory
---@class SavedInventoryMatch
---@field kind "stash" | "player"
---@field owner? string @ The character identifier or the owner column of the stash
---@field name? string @ The stash's name

-- Inventory tables searched when they exist: the table, its JSON column and the column naming its owner
local inventoryTables = {
    {table = "ox_inventory", column = "data", owner = "owner", name = "name", kind = "stash"},
    {table = "users", column = "inventory", owner = "identifier", kind = "player"},
    {table = "players", column = "inventory", owner = "citizenid", kind = "player"},
}

---@type {table: string, column: string, owner: string, name?: string, kind: "stash" | "player"}[]?
local presentTables

---@return {table: string, column: string, owner: string, name?: string, kind: "stash" | "player"}[] tables
local function getPresentTables()
    if (presentTables) then return presentTables end

    presentTables = {}

    for _, entry in ipairs(inventoryTables) do
        if (Functions.hasDatabaseColumn(entry.table, entry.column)) then presentTables[#presentTables + 1] = entry end
    end

    return presentTables
end

-- Saved inventories whose stored data contains the text, such as an item's serial. Reads whole tables, so keep it to
-- rare staff searches. Needs the calling resource to load @oxmysql/lib/MySQL.lua
---@param text string @ Matched as a substring, LIKE wildcards in it are not escaped
---@param limit integer @ Most rows per table
---@return SavedInventoryMatch[] matches
function Functions.searchSavedInventories(text, limit)
    local matches = {}
    local pattern = "%" .. text .. "%"

    for _, entry in ipairs(getPresentTables()) do
        local nameColumn = entry.name and (", `%s` AS `name`"):format(entry.name) or ""
        local query = ("SELECT `%s` AS `owner`%s FROM `%s` WHERE `%s` LIKE ? LIMIT ?"):format(entry.owner, nameColumn, entry.table, entry.column)

        for _, row in ipairs(MySQL.query.await(query, {pattern, limit}) or {}) do
            matches[#matches + 1] = {kind = entry.kind, owner = row.owner and tostring(row.owner) or nil, name = row.name}
        end
    end

    return matches
end

return Functions.searchSavedInventories