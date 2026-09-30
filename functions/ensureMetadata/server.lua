---@param item string
---@param metadata table<string, any> | fun(current?: table<string, any>): table<string, any> @ A function receives the item's current metadata, so defaults can follow what it already holds
function Functions.ensureMetadata(item, metadata)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    exports[LibName]:EnsureMetadata(item, metadata)
end

return Functions.ensureMetadata