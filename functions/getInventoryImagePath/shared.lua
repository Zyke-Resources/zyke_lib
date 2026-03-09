local inventoryResources = {
    ["OX"] = "ox_inventory",
    ["QS"] = "qs-inventory",
    ["TGIANN"] = "tgiann-inventory",
    ["CODEM"] = "codem-inventory",
    ["C8RE"] = "core_inventory",
}

local frameworkFallbacks = {
    ["QB"] = "qb-inventory",
}

---@param itemName string
---@return string
function Functions.getInventoryImagePath(itemName)
    local resourceName = inventoryResources[Inventory]

    if (not resourceName) then
        resourceName = frameworkFallbacks[Framework]

        -- qb-inventory uses html/images/ instead of web/images/
        if (resourceName == "qb-inventory") then
            return ("nui://%s/html/images/%s.png"):format(resourceName, itemName)
        end
    end

    if (not resourceName) then
        Functions.debug.internal("^1getInventoryImagePath: Could not determine inventory resource^7")
        return ""
    end

    return ("nui://%s/web/images/%s.png"):format(resourceName, itemName)
end

return Functions.getInventoryImagePath
