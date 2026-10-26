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

    -- Runs only for TGIANN Inventory users.
    if (Inventory == "TGIANN") then
        
        -- Handles durability in Metadata as durabilityPercent, 
        -- this ensures the values are mirrored & updated accordingly.
        if (formatted.info.durability) then
            formatted.info.durabilityPercent = formatted.info.durability
        end
        
        -- Can be improved if moved into config.lua or skipped if the metadata is stored with imageformat extension 
        -- like "image.png" rather than just "image".
        local imageFormat = ".png" -- Can be ".png" or ".webp". 
        
        -- Handles item images for dynamically updating based on item durability or any other cases.
        if (formatted.info.image) then
            formatted.info.imageurl = "nui://inventory_images/images/" .. formatted.info.image .. imageFormat
        end
    
        -- TGIANN Inv stores both metadata & info, we need to use info here for the correct data in Zyke scripts. 
        -- Metadata is taken into factor for internal calls.
        if (item.info) then
            formatted.metadata = item.info
        end
    
    end

    formatted.description = item.description

    return formatted
end

return Formatting.formatItem