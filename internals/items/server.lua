-- This is a multi-solution to ensuring certain metadata exists for select items for all inventories and frameworks
-- If your inventory provides another solution, we encourage you to use it, to prevent needing to listen to these events & process items all the time

---@param val any
local function isFuncRef(val)
    if (type(val) ~= "table") then return false end

    return val["__cfx_functionReference"] ~= nil
end

---@type table<string, table | fun(): table>
local ensuredMetadata = {}

-- The slot can hold another item by the time this arrives, such as after the player moved or used it
---@param slot integer
---@param expectedName string @ Item the client saw in the slot
RegisterNetEvent("zyke_lib:MissingMetadata", function(slot, expectedName)
    if (type(expectedName) ~= "string") then return end

    local item = Functions.getInventorySlot(source, slot)
    if (not item or not item.name) then return end

    -- formatItem's metadata on every inventory, setItemMetadata maps it back to what the inventory stores
    local newMetadata = item.metadata or {}
    local added = 0

    local _, itemName = Functions.getItem(item.name)
    itemName = itemName or item.name

    local _, expectedItemName = Functions.getItem(expectedName)
    if ((expectedItemName or expectedName) ~= itemName) then return end

    local desiredMetadata = ensuredMetadata[itemName]
    if (not desiredMetadata) then return end

    -- The item's current metadata is passed in, so defaults can follow what the item already holds
    if (isFuncRef(desiredMetadata)) then
        desiredMetadata = desiredMetadata(newMetadata)
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    for metaKey, metaValue in pairs(desiredMetadata) do
        if (newMetadata[metaKey] == nil) then
            newMetadata[metaKey] = metaValue
            added += 1
        end
    end

    if (added > 0) then
        Functions.setItemMetadata(source, item.slot, newMetadata)
        Functions.debug.internal(("Ensured missing metadata for %s."):format(item.name))
    end
end)

-- We provide a lib function to each resource
-- However, we want to sync all the metadata in our lib, as it does not need to be replicated and synced in every resource
-- A function receives the item's current metadata when filling it in, and nothing when only its keys are read
---@param item string
---@param metadata table<string, any> | fun(current?: table<string, any>): table<string, any>
exports("EnsureMetadata", function(item, metadata)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    ensuredMetadata[item] = metadata

    if (isFuncRef(metadata)) then
        metadata = metadata()
    end

    ---@type table<string, boolean>
    local clientData = {}
    ---@diagnostic disable-next-line: param-type-mismatch
    for k in pairs(metadata) do
        clientData[k] = true
    end

    TriggerClientEvent("zyke_lib:EnsureSingleMetadata", -1, item, clientData)
end)

---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("z:hasLoaded", nil, function(bagName)
    local plyId = GetPlayerFromStateBagName(bagName)
    if (not plyId) then return end

    TriggerClientEvent("zyke_lib:EnsuredMetadata", plyId, ensuredMetadata)
end)