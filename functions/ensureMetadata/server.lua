---@param item string
---@param metadata table<string, any>
function Functions.ensureMetadata(item, metadata)
    local _, itemName = Functions.getItem(item)
    item = itemName or item

    exports[LibName]:EnsureMetadata(item, metadata)
end

return Functions.ensureMetadata