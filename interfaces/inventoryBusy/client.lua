-- Keeps the player's inventory shut while resources run a task, such as a progress bar or a laptop being used. Each
-- holder is kept apart, so one lifting its own never frees the inventory under another's
---@type table<string, true> @ Holder name -> busy
local holders = {}
-- Only an invBusy placed here is lifted again, another script's stays untouched
local placedBusy = false

-- ox_inventory, and one_inventory through it, refuse opening the inventory and using items while invBusy is set
local function applyInventoryBusy()
    local busy = next(holders) ~= nil

    if (busy) then
        if (LocalPlayer.state.invBusy == true) then return end

        placedBusy = true
        LocalPlayer.state.invBusy = true

        return
    end

    if (not placedBusy) then return end

    placedBusy = false
    LocalPlayer.state.invBusy = false
end

-- For zyke_lib's own interfaces, which name their holder instead of taking the invoking resource
---@param holder string
---@param busy boolean
function SetInventoryBusyHolder(holder, busy)
    holders[holder] = busy == true or nil

    applyInventoryBusy()
end

-- Marks the inventory busy or frees it for the calling resource
---@param busy boolean
Functions.setInventoryBusy = function(busy)
    SetInventoryBusyHolder(GetInvokingResource() or ResName, busy)
end

-- Inventories clear invBusy after their own actions, which would free it while a holder still needs it
---@param bagName string @ player:<serverId>
---@param key string
---@param value any
---@diagnostic disable-next-line: param-type-mismatch
AddStateBagChangeHandler("invBusy", nil, function(bagName, key, value)
    if (value or next(holders) == nil) then return end
    if (GetPlayerFromStateBagName(bagName) ~= PlayerId()) then return end

    -- Bags can't be written from inside a change handler
    SetTimeout(0, function()
        placedBusy = false

        applyInventoryBusy()
    end)
end)

---@param resourceName string @ Stopping resource name
AddEventHandler("onClientResourceStop", function(resourceName)
    if (resourceName == ResName) then
        holders = {}
    elseif (holders[resourceName]) then
        holders[resourceName] = nil
    else
        return
    end

    applyInventoryBusy()
end)