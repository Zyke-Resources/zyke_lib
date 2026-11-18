-- Metadata an inventory draws a draining condition bar from, so the bar moves on its own with no writes
---@param expiresAt integer @ Unix time the bar reaches 0
---@param minutes number @ Minutes the bar takes to drain from full
---@return table<string, any>? metadata @ Nil when the inventory has no such bar
---@return string[]? keys @ Every key the bar uses, a key left out of metadata is to be removed from the item
function Functions.getDecayBarMetadata(expiresAt, minutes)
    local now = IsDuplicityVersion() and os.time() or GetCloudTimeAsInt()

    if (Inventory == "OX") then
        -- ox_inventory empties a run-out time in the past on its next save, so a spent bar is written as 0 at once
        if (expiresAt <= now) then return {durability = 0}, {"durability", "degrade"} end

        return {durability = expiresAt, degrade = minutes}, {"durability", "degrade"}
    end

    return nil
end

return Functions.getDecayBarMetadata