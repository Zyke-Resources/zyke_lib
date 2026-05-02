---@param plyId PlayerId
---@param slot integer
---@param durability number
---@return boolean
function Functions.setItemDurability(plyId, slot, durability)
    if (not slot) then return false end

    local item = Functions.getInventorySlot(plyId, slot)
    if (not item) then return false end

    local metadata = {}
    if (item.metadata) then
        for k, v in pairs(item.metadata) do
            metadata[k] = v
        end
    end

    metadata.durability = math.max(0, math.min(100, tonumber(durability) or 100))

    local result = Functions.setItemMetadata(plyId, slot, metadata)
    if (result == false) then return false end

    return true
end

return Functions.setItemDurability