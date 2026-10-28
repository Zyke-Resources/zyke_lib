---@class Item
---@field name string
---@field label string
---@field amount integer
---@field weight number
---@field metadata table<string, any> | nil
---@field slot integer

-- Store the id of the container the item is present in, only populate if we specifically search for it in an external container
-- This is a manual key we attach to track which container the item originated from
---@class PlayerContainerItem
---@field containerId string

-- TGIANN keeps the 0-100 durability in durabilityPercent and uses durability as the decay timestamp of decayable items
-- Resources read durability as 0-100, setItemMetadata maps it back before writing
---@param name? string
---@param info table<string, any>
---@return table<string, any> metadata
local function getTgiannMetadata(name, info)
    local metadata = {}
    for k, v in pairs(info) do
        metadata[k] = v
    end

    local decayTime = name and info.durability and exports["tgiann-inventory"]:GetItemDecayTime(name)
    if (decayTime and decayTime > 0) then
        metadata.durability = exports["tgiann-inventory"]:GetDurabilityPercent(info.durability, decayTime)
    elseif (info.durabilityPercent ~= nil) then
        metadata.durability = info.durabilityPercent
    end

    return metadata
end

---@param item? table
---@return Item? formatted
function Formatting.formatItem(item)
    if (not item) then return nil end

    local formatted = {}
    if Inventory == "TGIANN" then
        formatted = {
            name = item.name or item.item,
            label = item.label,
            amount = item.amount or item.count or item.value or 1,
            weight = item.weight,
            info = item.info or {},
            metadata = item.metadata or item.info or {},
            slot = item.slot
        }
    else
        formatted = {
            name = item.name or item.item,
            label = item.label,
            amount = item.amount or item.count or item.value or 1,
            weight = item.weight,
            metadata = item.metadata or item.info,
            slot = item.slot
        }
    end

    -- TGIANN stores both metadata & info, we need to use info here for the correct data
    -- Also check if .info exists, because if it is an internal call we may have already translated it
    if (Inventory == "TGIANN" and item.info) then
        formatted.metadata = getTgiannMetadata(formatted.name, item.info)
    end

    formatted.description = item.description

    return formatted
end

return Formatting.formatItem