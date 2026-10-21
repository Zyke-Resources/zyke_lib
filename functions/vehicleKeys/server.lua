Functions.vehicleKeys = {}

---@class VehicleKeyGiveContext
---@field vin? string @ Canonical vehicle identifier available to provider label templates
---@field modelLabel? string @ Display name available to provider label templates
---@field enforceLimit? boolean @ Applies the provider's replacement-key limit
---@field reconcileExisting? boolean @ Refreshes matching physical key metadata instead of issuing a duplicate

-- Add providers by checking VehicleKeysSystem inside each method and calling their API directly

---@param rawPlate any
---@return string? plate
local function normalizePlate(rawPlate)
    if (type(rawPlate) ~= "string") then return nil end

    local plate = rawPlate:match("^%s*(.-)%s*$"):upper()
    if (plate == "" or #plate > 12) then return nil end

    return plate
end

-- Provider lists vary between arrays, boolean maps, and value maps
---@param rawPlates table
---@return string[] plates
local function normalizePlates(rawPlates)
    local plates = {}
    local added = {}

    for key, value in pairs(rawPlates) do
        local rawPlate = type(key) == "number" and value or (value == true and key or value)
        local plate = normalizePlate(rawPlate)
        if (plate and not added[plate]) then
            plates[#plates + 1] = plate
            added[plate] = true
        end
    end

    return plates
end

---@param plate string
---@return Vehicle? vehicle
local function getVehicle(plate)
    local vehicle = Z.getVehicleByPlate(plate)
    if (vehicle and DoesEntityExist(vehicle) and GetEntityType(vehicle) == 2) then return vehicle end

    -- Qbox exports require an entity, while synced state may hold a plate hidden by a fake plate
    local vehicles = GetAllVehicles()
    for i = 1, #vehicles do
        local statePlate = Entity(vehicles[i]).state.plate
        if (normalizePlate(statePlate) == plate) then return vehicles[i] end
    end

    return nil
end

---@return string? providerName
function Functions.vehicleKeys.getProvider()
    return VehicleKeysSystem
end

---@return boolean available
function Functions.vehicleKeys.isAvailable()
    return VehicleKeysSystem ~= nil and GetResourceState(VehicleKeysSystem) == "started"
end

-- Reports supported operations and storage traits used to select safe adapter paths
---@return table<string, any> capabilities
function Functions.vehicleKeys.getCapabilities()
    if (not Functions.vehicleKeys.isAvailable()) then return {} end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return exports["zyke_vehiclekeys"]:GetCapabilities()
    end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        return {
            provider = VehicleKeysSystem,
            giveKey = true,
            removeKey = true,
            hasKey = true,
            listKeys = true,
            identifierAccess = true,
            serverAuthoritative = true,
        }
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        return {
            provider = VehicleKeysSystem,
            giveKey = true,
            removeKey = true,
            hasKey = true,
            listKeys = true,
            identifierAccess = true,
            requiresVehicle = true,
            serverAuthoritative = true,
        }
    end

    if (VehicleKeysSystem == "qs-vehiclekeys") then
        return {
            provider = VehicleKeysSystem,
            giveKey = true,
            removeKey = true,
            hasKey = true,
            listKeys = true,
            itemAccess = true,
            requiresVehicle = true,
            serverAuthoritative = false,
        }
    end

    if (VehicleKeysSystem == "wasabi_carlock") then
        return {
            provider = VehicleKeysSystem,
            giveKey = true,
            removeKey = true,
            hasKey = true,
            listKeys = true,
            identifierAccess = true,
            serverAuthoritative = true,
        }
    end

    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        return {
            provider = VehicleKeysSystem,
            giveKey = true,
            removeKey = true,
            hasKey = true,
            listKeys = true,
            identifierAccess = true,
            serverAuthoritative = true,
        }
    end

    return {}
end

---@param plyId PlayerId
---@param rawPlate string
---@param allowFallback? boolean @ Allows queued delivery when an inventory-backed key cannot be added
---@param context? VehicleKeyGiveContext
---@return boolean given
---@return string? reason
function Functions.vehicleKeys.give(plyId, rawPlate, allowFallback, context)
    if (not Functions.vehicleKeys.isAvailable()) then return false, "keyProviderUnavailable" end

    local plate = normalizePlate(rawPlate)
    if (not plate) then return false, "noVehicleFound" end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local given, reason = exports["zyke_vehiclekeys"]:GiveKey(plyId, plate, allowFallback, context)

        return given ~= false, reason
    end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        return exports["qb-vehiclekeys"]:GiveKeys(plyId, plate) ~= false
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = getVehicle(plate)
        if (not vehicle) then return false, "noVehicleFound" end

        return exports["qbx_vehiclekeys"]:GiveKeys(plyId, vehicle, true) ~= false
    end

    if (VehicleKeysSystem == "qs-vehiclekeys") then
        local status, given = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "give", plate)
        if (not status or status.ok ~= true) then return false, "keyProviderUnavailable" end

        return given ~= false
    end

    if (VehicleKeysSystem == "wasabi_carlock") then
        return exports["wasabi_carlock"]:GiveKey(plyId, plate) ~= false
    end

    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        return exports["Renewed-Vehiclekeys"]:addKey(plyId, plate) ~= false
    end

    return false, "keyProviderUnavailable"
end

-- zyke_vehiclekeys has temporary grants; external providers use their normal key grant
---@param plyId PlayerId
---@param rawPlate string
---@param skipCanGiveCheck? boolean @ Bypasses the provider hook that authorizes temporary grants
---@param allowFallback? boolean @ Allows queued delivery when temporary access requires a physical key
---@return boolean given
---@return string? reason
function Functions.vehicleKeys.giveTemporary(plyId, rawPlate, skipCanGiveCheck, allowFallback)
    if (not Functions.vehicleKeys.isAvailable()) then return false, "keyProviderUnavailable" end

    local plate = normalizePlate(rawPlate)
    if (not plate) then return false, "noVehicleFound" end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return exports["zyke_vehiclekeys"]:GiveTemporaryKey(plyId, plate, skipCanGiveCheck, allowFallback)
    end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        return exports["qb-vehiclekeys"]:GiveKeys(plyId, plate) ~= false
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = getVehicle(plate)
        if (not vehicle) then return false, "noVehicleFound" end

        return exports["qbx_vehiclekeys"]:GiveKeys(plyId, vehicle, true) ~= false
    end

    if (VehicleKeysSystem == "qs-vehiclekeys") then
        local status, given = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "give", plate)
        if (not status or status.ok ~= true) then return false, "keyProviderUnavailable" end

        return given ~= false
    end

    if (VehicleKeysSystem == "wasabi_carlock") then
        return exports["wasabi_carlock"]:GiveKey(plyId, plate) ~= false
    end

    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        return exports["Renewed-Vehiclekeys"]:addKey(plyId, plate) ~= false
    end

    return false, "keyProviderUnavailable"
end

---@param plyId PlayerId
---@param rawPlate string
---@return boolean hasKey
function Functions.vehicleKeys.has(plyId, rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    local plate = normalizePlate(rawPlate)
    if (not plate) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then return exports["zyke_vehiclekeys"]:HasKey(plyId, plate) == true end
    if (VehicleKeysSystem == "qb-vehiclekeys") then return exports["qb-vehiclekeys"]:HasKeys(plyId, plate) == true end
    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = getVehicle(plate)
        if (not vehicle) then return false end

        return exports["qbx_vehiclekeys"]:HasKeys(plyId, vehicle) == true
    end
    if (VehicleKeysSystem == "qs-vehiclekeys") then
        local status, hasKey = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "has", plate)

        return status and status.ok == true and hasKey == true
    end
    if (VehicleKeysSystem == "wasabi_carlock") then return exports["wasabi_carlock"]:HasKey(plyId, plate) == true end
    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then return exports["Renewed-Vehiclekeys"]:hasKey(plyId, plate) == true end

    return false
end

---@param plyId PlayerId
---@param rawPlate string
---@return integer removed
function Functions.vehicleKeys.remove(plyId, rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return 0 end

    local plate = normalizePlate(rawPlate)
    if (not plate or not Functions.vehicleKeys.has(plyId, plate)) then return 0 end

    local removed
    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        removed = exports["zyke_vehiclekeys"]:RemoveKey(plyId, plate)
    elseif (VehicleKeysSystem == "qb-vehiclekeys") then
        removed = exports["qb-vehiclekeys"]:RemoveKeys(plyId, plate)
    elseif (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = getVehicle(plate)
        if (not vehicle) then return 0 end

        removed = exports["qbx_vehiclekeys"]:RemoveKeys(plyId, vehicle, true)
    elseif (VehicleKeysSystem == "qs-vehiclekeys") then
        local status
        status, removed = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "remove", plate)
        if (not status or status.ok ~= true) then return 0 end
    elseif (VehicleKeysSystem == "wasabi_carlock") then
        removed = exports["wasabi_carlock"]:RemoveKey(plyId, plate)
    elseif (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        removed = exports["Renewed-Vehiclekeys"]:removeKey(plyId, plate)
    else
        return 0
    end

    if (removed == false) then return 0 end

    return type(removed) == "number" and math.max(0, math.floor(removed)) or 1
end

-- Removes every matching grant when supported; otherwise uses the provider's normal remove operation
---@param plyId PlayerId
---@param rawPlate string
---@return integer removed
function Functions.vehicleKeys.removeAll(plyId, rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return 0 end

    local plate = normalizePlate(rawPlate)
    if (not plate or not Functions.vehicleKeys.has(plyId, plate)) then return 0 end

    local removed
    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        removed = exports["zyke_vehiclekeys"]:RemoveAllKeys(plyId, plate)
    elseif (VehicleKeysSystem == "qb-vehiclekeys") then
        removed = exports["qb-vehiclekeys"]:RemoveKeys(plyId, plate)
    elseif (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = getVehicle(plate)
        if (not vehicle) then return 0 end

        removed = exports["qbx_vehiclekeys"]:RemoveKeys(plyId, vehicle, true)
    elseif (VehicleKeysSystem == "qs-vehiclekeys") then
        local status
        status, removed = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "remove", plate)
        if (not status or status.ok ~= true) then return 0 end
    elseif (VehicleKeysSystem == "wasabi_carlock") then
        removed = exports["wasabi_carlock"]:RemoveKey(plyId, plate)
    elseif (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        removed = exports["Renewed-Vehiclekeys"]:removeKey(plyId, plate)
    else
        return 0
    end

    if (removed == false) then return 0 end

    return type(removed) == "number" and math.max(0, math.floor(removed)) or 1
end

-- Invalidates player-issued permanent keys while preserving garage-managed access
---@param rawPlate string
---@return boolean rotated
function Functions.vehicleKeys.rotate(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:RotateKeys(plate) == true
    end

    return false
end

-- Moves provider state so aliases and physical key metadata continue to resolve after a plate change
---@param rawOldPlate string
---@param rawNewPlate string
---@return boolean renamed
function Functions.vehicleKeys.renamePlate(rawOldPlate, rawNewPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local oldPlate = normalizePlate(rawOldPlate)
        local newPlate = normalizePlate(rawNewPlate)
        if (not oldPlate or not newPlate) then return false end

        return exports["zyke_vehiclekeys"]:RenamePlate(oldPlate, newPlate) == true
    end

    return false
end

-- Retires provider state so old keys cannot become valid if the plate is reused
---@param rawPlate string
---@return boolean deleted
function Functions.vehicleKeys.deleteVehicle(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:DeleteVehicle(plate) == true
    end

    return false
end

-- Replaces persistent garage-managed identifier access without modifying player-issued keys
---@param rawPlate string
---@param access table<string, boolean>
---@return boolean synced
function Functions.vehicleKeys.setAccess(rawPlate, access)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate or type(access) ~= "table") then return false end

        return exports["zyke_vehiclekeys"]:SetAccess(plate, access) == true
    end

    return false
end

-- Replaces runtime-only identifier access used for temporary garage grants
---@param rawPlate string
---@param access table<string, boolean>
---@return boolean synced
function Functions.vehicleKeys.setTemporaryAccess(rawPlate, access)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate or type(access) ~= "table") then return false end

        return exports["zyke_vehiclekeys"]:SetTemporaryAccess(plate, access) == true
    end

    return false
end

-- Seeds legacy frequency, counter, and garage access without replacing existing provider state
---@param rawPlate string
---@param state table<string, any>
---@return boolean imported
function Functions.vehicleKeys.importVehicleState(rawPlate, state)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate or type(state) ~= "table") then return false end

        return exports["zyke_vehiclekeys"]:ImportVehicleState(plate, state) == true
    end

    return false
end

-- Counts active permanent keys for provider replacement-limit accounting
---@param rawPlate string
---@return integer count @ Issued-key count, excluding garage-managed and temporary access
function Functions.vehicleKeys.getKeyCounter(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return 0 end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return 0 end

        return math.max(0, math.floor(tonumber(exports["zyke_vehiclekeys"]:GetKeyCounter(plate)) or 0))
    end

    return 0
end

-- Physical keys store this generation in metadata; rotation advances it so older items stop granting access
---@param rawPlate string
---@return integer frequency @ Current physical-key generation
function Functions.vehicleKeys.getKeyFrequency(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return 0 end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return 0 end

        return math.max(0, math.floor(tonumber(exports["zyke_vehiclekeys"]:GetKeyFrequency(plate)) or 0))
    end

    return 0
end

-- Adds to replacement-limit accounting without issuing a key
---@param rawPlate string
---@return boolean incremented
function Functions.vehicleKeys.incrementKeyCounter(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:IncrementKeyCounter(plate) == true
    end

    return false
end

-- Reduces replacement-limit accounting without removing a key
---@param rawPlate string
---@param amount? integer
---@return boolean decremented
function Functions.vehicleKeys.decrementKeyCounter(rawPlate, amount)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:DecrementKeyCounter(plate, amount) == true
    end

    return false
end

-- Clears replacement-limit accounting without changing current access
---@param rawPlate string
---@return boolean reset
function Functions.vehicleKeys.resetKeyCounter(rawPlate)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = normalizePlate(rawPlate)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:ResetKeyCounter(plate) == true
    end

    return false
end

-- Returns every normalized plate currently authorized by the provider, regardless of storage mode
---@param plyId PlayerId
---@return string[] plates
function Functions.vehicleKeys.getAccessiblePlates(plyId)
    if (not Functions.vehicleKeys.isAvailable()) then return {} end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plates = exports["zyke_vehiclekeys"]:GetAccessiblePlates(plyId)
        if (type(plates) ~= "table") then return {} end

        return normalizePlates(plates)
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        local player = Player(plyId)
        if (not player) then return {} end

        -- Qbox stores keys by session ID, so streamed vehicle state resolves them back to plates
        local keys = player.state.keysList or {}
        local plates = {}
        local vehicles = GetAllVehicles()

        for i = 1, #vehicles do
            local state = Entity(vehicles[i]).state
            local sessionId = state.sessionId
            if (sessionId and (keys[sessionId] == true or keys[tostring(sessionId)] == true)) then
                plates[#plates + 1] = state.plate or GetVehicleNumberPlateText(vehicles[i])
            end
        end

        return normalizePlates(plates)
    end

    if (VehicleKeysSystem == "qs-vehiclekeys") then
        -- Quasar stores the provider plate in vehiclekeys item metadata
        local plates = {}
        local items = Z.getPlayerItems(plyId, "vehiclekeys")

        for i = 1, #items do
            plates[#plates + 1] = items[i].metadata and items[i].metadata.plate
        end

        return normalizePlates(plates)
    end

    if (VehicleKeysSystem == "qb-vehiclekeys" or VehicleKeysSystem == "wasabi_carlock" or VehicleKeysSystem == "Renewed-Vehiclekeys") then
        local status, plates = Z.callback.request(plyId, ("%s:VehicleKeysProviderAction"):format(ResName), {
            timeout = 3000,
            status = true,
        }, VehicleKeysSystem, "list")
        if (not status or status.ok ~= true or type(plates) ~= "table") then return {} end

        plates = normalizePlates(plates)
        local verified = {}

        -- Client lists are discovery only; server HasKey verifies every plate before granting access
        for i = 1, #plates do
            if (Functions.vehicleKeys.has(plyId, plates[i])) then verified[#verified + 1] = plates[i] end
        end

        return verified
    end

    return {}
end

-- Sends post-action feedback such as provider sounds without authorizing or changing vehicle state
---@param plyId PlayerId
---@param netId NetId
---@param action string
---@param desiredState boolean
---@return boolean notified
function Functions.vehicleKeys.notifyVehicleAction(plyId, netId, action, desiredState)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return exports["zyke_vehiclekeys"]:NotifyVehicleAction(plyId, netId, action, desiredState) == true
    end

    return false
end

return Functions.vehicleKeys