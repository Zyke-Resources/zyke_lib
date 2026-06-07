-- This is a multi-solution to ensuring certain metadata exists for select items for all inventories and frameworks
-- If your inventory provides another solution, we encourage you to use it, to prevent needing to listen to these events & process items all the time

---@param val any
local function isFuncRef(val)
    if (type(val) ~= "table") then return false end

    return val["__cfx_functionReference"] ~= nil
end

---@type table<string, table | fun(): table>
local ensuredMetadata = {}

---@param slot integer
RegisterNetEvent("zyke_lib:MissingMetadata", function(slot)
    local item = Functions.getInventorySlot(source, slot)
    if (not item) then return end

    local newMetadata = {}
    if Inventory == "TGIANN" then
        newMetadata = item.info or {}
    else
        newMetadata = item.metadata or {}
    end
    local added = 0

    local itemName
    if (item.name) then
        _, itemName = Functions.getItem(item.name)
    end

    local desiredMetadata = ensuredMetadata[itemName or item.name]

    if (isFuncRef(desiredMetadata)) then
        desiredMetadata = desiredMetadata()
    end

    ---@diagnostic disable-next-line: param-type-mismatch
    for metaKey, metaValue in pairs(desiredMetadata) do
        local metadata = nil

        --Extra check for people using TGIANN Inventory (Consumables Hotfix, still does contain referencing errors, more indepth code modification will be needed)
        if Inventory == "TGIANN" then
            metadata = item.info[metaKey]
        else
            metadata = item.metadata[metaKey]
        end

        local newVal
        if (metadata == nil) then
            newVal = metaValue
            added += 1
        else
            newVal = metadata
        end

        newMetadata[metaKey] = newVal
    end

    if (added > 0) then
        Functions.setItemMetadata(source, item.slot, newMetadata)
        Functions.debug.internal(("Ensured missing metadata for %s."):format(item.name))
    end
end)

-- We provide a lib function to each resource
-- However, we want to sync all the metadata in our lib, as it does not need to be replicated and synced in every resource
---@param item string
---@param metadata table<string, any> | fun(): table<string, any>
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