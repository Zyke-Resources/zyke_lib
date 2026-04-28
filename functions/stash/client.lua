Functions.stash = {}

---@class StashOpenOptions
---@field slots? integer @ Number of slots (default: 20)
---@field maxweight? integer @ Maximum weight in grams (default: 4000)

---@type integer | nil
local qbInvMajor = nil

--- Returns the major version of qb-inventory if it can be determined, otherwise nil.
--- Result is cached after the first lookup.
---@return integer | nil
local function getQbInvMajor()
    if (qbInvMajor == nil) then
        local version = GetResourceMetadata("qb-inventory", "version", 0)
        local major = version and version:match("(%d+)")

        qbInvMajor = major and math.tointeger(major) or nil
    end

    return qbInvMajor
end

---@param invId string @ Unique stash identifier
---@param other? StashOpenOptions @ Stash configuration (ignored by some inventories)
---@diagnostic disable-next-line: duplicate-set-field
function Functions.stash.open(invId, other)
    local slots = other?.slots or 20
    local weight = other?.maxweight or 4000

    if (Inventory == "OX") then
        return exports["ox_inventory"]:openInventory("stash", invId)
    elseif (Inventory == "QS") then
        -- QS RegisterStash only creates the stash
        -- Opening uses the QB-style event pattern
        exports["qs-inventory"]:RegisterStash(invId, slots, weight)

        TriggerServerEvent("inventory:server:OpenInventory", "stash", invId, {
            maxweight = weight,
            slots = slots,
        })

        TriggerEvent("inventory:client:SetCurrentStash", invId)
    elseif (Inventory == "TGIANN") then
        return exports["tgiann-inventory"]:OpenInventory("stash", invId, {
            maxweight = weight,
            slots = slots,
        })
    elseif (Inventory == "CODEM") then
        return TriggerServerEvent("codem-inventory:server:openstash", invId, slots, weight, invId)
    elseif (Inventory == "C8RE") then
        return TriggerServerEvent("core_inventory:server:openInventory", invId, "stash")
    elseif (Framework == "QB") then
        local major = getQbInvMajor()

        -- qb-inventory v2.x removed inventory:server:OpenInventory in favour of an export,
        -- so route those calls through our own internal server handler.
        if (major and major >= 2) then
            return TriggerServerEvent(ResName .. ":server:openStash", invId, slots, weight)
        end

        TriggerServerEvent("inventory:server:OpenInventory", "stash", invId, {
            maxweight = weight,
            slots = slots,
        })

        TriggerEvent("inventory:client:SetCurrentStash", invId)
    end
end

return Functions.stash