local inventoryResources = {
    ["OX"] = "ox_inventory",
    ["QS"] = "qs-inventory",
    ["CODEM"] = "codem-inventory",
    ["C8RE"] = "core_inventory",
}

local frameworkFallbacks = {
    ["QB"] = "qb-inventory",
}

local oneImageExtensions = {"png", "webp", "jpg", "jpeg", "gif"}

---@param itemName string
---@param metadata? table<string, any>
---@return string
local function getOneImagePath(itemName, metadata)
    local candidates = {}
    local metadataImage = metadata and (metadata.image or metadata.imageurl)
    local definitionImage = Items[itemName] and Items[itemName].image

    if (type(metadataImage) == "string") then candidates[#candidates+1] = metadataImage end
    if (type(definitionImage) == "string") then candidates[#candidates+1] = definitionImage end

    candidates[#candidates+1] = itemName

    for i = 1, #candidates do
        if (candidates[i]:match("^https?://")) then return candidates[i] end

        local extension = candidates[i]:match("%.([^./]+)$")

        if (extension) then
            for j = 1, #oneImageExtensions do
                if (extension:lower() == oneImageExtensions[j]) then
                    local path = "web/images/" .. candidates[i]

                    if (LoadResourceFile("one_inventory", path)) then
                        return "nui://one_inventory/" .. path
                    end

                    break
                end
            end
        else
            for j = 1, #oneImageExtensions do
                local path = ("web/images/%s.%s"):format(candidates[i], oneImageExtensions[j])

                if (LoadResourceFile("one_inventory", path)) then
                    return "nui://one_inventory/" .. path
                end
            end
        end
    end

    return ("nui://one_inventory/web/images/%s.png"):format(itemName)
end

-- TGIANN serves every image from inventory_images, an image without an extension defaults to .webp like TGIANN's own
---@param itemName string
---@param metadata? table<string, any>
---@return string
local function getTgiannImagePath(itemName, metadata)
    local image = metadata and metadata.image
    if (type(image) ~= "string") then image = Items[itemName] and Items[itemName].image end
    if (type(image) ~= "string") then image = itemName end
    if (image:match("^https?://") or image:match("^nui://")) then return image end
    if (not image:match("%.[^./]+$")) then image = image .. ".webp" end

    return "nui://inventory_images/images/" .. image
end

---@param itemName string
---@param metadata? table<string, any>
---@return string
function Functions.getInventoryImagePath(itemName, metadata)
    local _, normalizedName = Functions.getItem(itemName)
    itemName = normalizedName or itemName

    if (Inventory == "ONE") then return getOneImagePath(itemName, metadata) end
    if (Inventory == "TGIANN") then return getTgiannImagePath(itemName, metadata) end

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