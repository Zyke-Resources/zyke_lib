-- Players txAdmin authenticated as admins in game, which Z.hasPermission lets through when txAdminAdmins is enabled
-- txAdmin keeps its admins in its own admins.json and tells resources only through txAdmin:events:adminAuth, with no permission list

---@type table<PlayerId, true>
local admins = {}

---@param plyId PlayerId
---@return boolean isAdmin
exports("IsTxAdmin", function(plyId)
    return admins[tonumber(plyId)] == true
end)

if (LibConfig.txAdminAdmins ~= true) then return end

-- netid -1 revokes every admin while txAdmin makes them authenticate again
---@param data {netid: integer, isAdmin: boolean, username?: string}
AddEventHandler("txAdmin:events:adminAuth", function(data)
    if (data.netid == -1) then
        admins = {}

        return
    end

    admins[data.netid] = data.isAdmin == true or nil
end)

AddEventHandler("playerDropped", function()
    admins[source] = nil
end)

-- Admins authenticated before this start are unknown, txcl:reAuth is txAdmin's own event that makes a client authenticate again
if (GetResourceState("monitor") == "started") then TriggerClientEvent("txcl:reAuth", -1) end