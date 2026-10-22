Functions.vehicleKeys = {}

---@param identifier string | Vehicle @ Vehicle handle or canonical provider plate
---@return Vehicle? vehicle @ Existing entity resolved from the handle, native plate, or synced plate state
local function resolveVehicle(identifier)
    if (type(identifier) == "number") then
        if (DoesEntityExist(identifier) and GetEntityType(identifier) == 2) then return identifier end

        return nil
    end

    if (type(identifier) ~= "string") then return nil end

    local vehicle = Z.getVehicleByPlate(identifier)
    if (vehicle) then return vehicle end

    -- Synced state preserves the provider plate when the visible native plate is spoofed
    local plate = identifier:match("^%s*(.-)%s*$"):upper()
    local vehicles = GetGamePool("CVehicle")
    for i = 1, #vehicles do
        local statePlate = Entity(vehicles[i]).state.plate
        if (type(statePlate) == "string" and statePlate:match("^%s*(.-)%s*$"):upper() == plate) then return vehicles[i] end
    end

    return nil
end

---@param identifier string | Vehicle
---@return string? plate
local function resolvePlate(identifier)
    if (type(identifier) == "string") then
        local plate = identifier:match("^%s*(.-)%s*$"):upper()

        return plate ~= "" and #plate <= 12 and plate or nil
    end

    local vehicle = resolveVehicle(identifier)
    if (not vehicle) then return nil end

    -- Send providers the canonical state plate rather than a visible fake plate
    local statePlate = Entity(vehicle).state.plate
    local plate = type(statePlate) == "string" and statePlate or GetVehicleNumberPlateText(vehicle)

    return plate:match("^%s*(.-)%s*$"):upper()
end

---@param identifier string | Vehicle
---@return string? model
local function resolveModel(identifier)
    local vehicle = resolveVehicle(identifier)
    if (not vehicle) then return nil end

    return GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
end

-- Provider lists vary between arrays, boolean maps, and value maps
---@param rawPlates table
---@return string[] plates
local function normalizePlates(rawPlates)
    local plates = {}
    local added = {}

    for key, value in pairs(rawPlates) do
        local rawPlate = type(key) == "number" and value or (value == true and key or value)
        local plate = resolvePlate(rawPlate)
        if (plate and not added[plate]) then
            plates[#plates + 1] = plate
            added[plate] = true
        end
    end

    return plates
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
            hasKey = true,
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

---@param identifier string | Vehicle
---@return boolean hasKey
function Functions.vehicleKeys.has(identifier)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local plate = resolvePlate(identifier)
        if (not plate) then return false end

        return exports["zyke_vehiclekeys"]:HasKey(plate) == true
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then
        local vehicle = resolveVehicle(identifier)
        if (not vehicle) then return false end

        return exports["qbx_vehiclekeys"]:HasKeys(vehicle) == true
    end

    local plate = resolvePlate(identifier)
    if (not plate) then return false end

    if (VehicleKeysSystem == "qb-vehiclekeys") then return exports["qb-vehiclekeys"]:HasKeys(plate) == true end
    if (VehicleKeysSystem == "qs-vehiclekeys") then return exports["qs-vehiclekeys"]:GetKey(plate) == true end
    if (VehicleKeysSystem == "wasabi_carlock") then return exports["wasabi_carlock"]:HasKey(plate) == true end
    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then return exports["Renewed-Vehiclekeys"]:hasKey(plate) == true end

    return false
end

---@param identifier string | Vehicle
---@return boolean given
function Functions.vehicleKeys.give(identifier)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    local plate = resolvePlate(identifier)
    if (not plate) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then return exports["zyke_vehiclekeys"]:GiveKey(plate) ~= false end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        TriggerEvent("vehiclekeys:client:SetOwner", plate)

        return true
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then return false end
    if (VehicleKeysSystem == "qs-vehiclekeys") then
        local model = resolveModel(identifier)
        if (not model) then return false end

        return exports["qs-vehiclekeys"]:GiveKeys(plate, model, true) ~= false
    end
    if (VehicleKeysSystem == "wasabi_carlock") then return exports["wasabi_carlock"]:GiveKey(plate) ~= false end
    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then return exports["Renewed-Vehiclekeys"]:addKey(plate) ~= false end

    return false
end

---@param identifier string | Vehicle
---@return boolean removed
function Functions.vehicleKeys.remove(identifier)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    local plate = resolvePlate(identifier)
    if (not plate) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then return exports["zyke_vehiclekeys"]:RemoveKey(plate) ~= false end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        TriggerEvent("qb-vehiclekeys:client:RemoveKeys", plate)

        return true
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys") then return false end
    if (VehicleKeysSystem == "qs-vehiclekeys") then
        local model = resolveModel(identifier)
        if (not model) then return false end

        return exports["qs-vehiclekeys"]:RemoveKeys(plate, model) ~= false
    end
    if (VehicleKeysSystem == "wasabi_carlock") then return exports["wasabi_carlock"]:RemoveKey(plate) ~= false end
    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then return exports["Renewed-Vehiclekeys"]:removeKey(plate) ~= false end

    return false
end

-- Returns every normalized plate currently authorized for the local player
---@return string[] plates
function Functions.vehicleKeys.getAccessiblePlates()
    if (not Functions.vehicleKeys.isAvailable()) then return {} end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return normalizePlates(Z.callback.request("zyke_vehiclekeys:GetAccessiblePlates", nil) or {})
    end

    if (VehicleKeysSystem == "qb-vehiclekeys") then
        -- QB exposes its full key list through a framework callback rather than an export
        local core = exports["qb-core"]:GetCoreObject()
        local response = promise.new()
        core.Functions.TriggerCallback("qb-vehiclekeys:server:GetVehicleKeys", function(plates)
            response:resolve(plates or {})
        end)

        return normalizePlates(Citizen.Await(response))
    end

    if (VehicleKeysSystem == "qbx_vehiclekeys" or VehicleKeysSystem == "qs-vehiclekeys" or VehicleKeysSystem == "Renewed-Vehiclekeys") then return {} end
    if (VehicleKeysSystem == "wasabi_carlock") then return normalizePlates(exports["wasabi_carlock"]:GetAllKeys() or {}) end

    return {}
end

---@param vehicle Vehicle
---@param locked boolean
---@return boolean changed
function Functions.vehicleKeys.setLockState(vehicle, locked)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        if (not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2) then return false end

        return exports["zyke_vehiclekeys"]:SetLockState(vehicle, locked) == true
    end

    if (VehicleKeysSystem == "Renewed-Vehiclekeys") then
        if (not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2) then return false end
        -- We map the Boolean value to the numbers that the system expects.
        local lockState = locked and 2 or 1
        -- For each entity, we check the status of its lock.
        Entity(vehicle).state:set('vehicleLock', {
            lock = lockState, -- 1 | unlocked | 2 locked
            sound = true, -- true | false
        }, true)
        return true
    end

    return false
end

---@param vehicle Vehicle
---@param enabled boolean
---@return boolean changed
function Functions.vehicleKeys.setEngineState(vehicle, enabled)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        if (not DoesEntityExist(vehicle) or GetEntityType(vehicle) ~= 2) then return false end

        return exports["zyke_vehiclekeys"]:SetEngineState(vehicle, enabled) == true
    end

    return false
end

-- Describes the provider's physical-key label template and customization limits
---@return {base: string, allowCustom: boolean, maxCharacters: integer}? settings
function Functions.vehicleKeys.getItemLabelSettings()
    if (not Functions.vehicleKeys.isAvailable()) then return nil end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local settings = exports["zyke_vehiclekeys"]:GetItemLabelSettings()

        return type(settings) == "table" and settings or nil
    end

    return nil
end

-- Returns the local template used when the provider creates future physical key items
---@return string? label
function Functions.vehicleKeys.getSavedItemLabel()
    if (not Functions.vehicleKeys.isAvailable()) then return nil end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local label = exports["zyke_vehiclekeys"]:GetSavedItemLabel()

        return type(label) == "string" and label or nil
    end

    return nil
end

-- Persists the local template and lets the provider sync it for future physical key items
---@param label string
---@return boolean saved
function Functions.vehicleKeys.setSavedItemLabel(label)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        if (type(label) ~= "string") then return false end

        return exports["zyke_vehiclekeys"]:SetSavedItemLabel(label) == true
    end

    return false
end

-- Returns provider-owned UI definitions separately from the local player's current values
---@return table[] definitions
---@return table<string, boolean> values
function Functions.vehicleKeys.getPersonalSettings()
    if (not Functions.vehicleKeys.isAvailable()) then return {}, {} end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local definitions, values = exports["zyke_vehiclekeys"]:GetPersonalSettings()
        if (type(definitions) ~= "table" or type(values) ~= "table") then return {}, {} end

        return definitions, values
    end

    return {}, {}
end

-- Lets the provider reject forced settings and persist accepted values in its client storage
---@param name string
---@param value boolean
---@return boolean updated
function Functions.vehicleKeys.setPersonalSetting(name, value)
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return exports["zyke_vehiclekeys"]:SetPersonalSetting(name, value) == true
    end

    return false
end

-- Requests the provider's configured key-fob beep on the local player
---@return boolean played
function Functions.vehicleKeys.playKeyFobSound()
    if (not Functions.vehicleKeys.isAvailable()) then return false end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        return exports["zyke_vehiclekeys"]:PlayKeyFobSound() == true
    end

    return false
end

-- Returns localized action names with the player's current control labels for help UIs
---@return table[] keybinds
function Functions.vehicleKeys.getKeybinds()
    if (not Functions.vehicleKeys.isAvailable()) then return {} end

    if (VehicleKeysSystem == "zyke_vehiclekeys") then
        local keybinds = exports["zyke_vehiclekeys"]:GetKeybinds()

        return type(keybinds) == "table" and keybinds or {}
    end

    return {}
end

-- Callback names follow the importing resource so replies return to its request table
---@param providerName string
---@param action "give" | "has" | "remove" | "list"
---@param plate? string
---@return boolean | string[] result
local function handleProviderAction(providerName, action, plate)
    if (providerName ~= VehicleKeysSystem) then return false end
    if (action == "list") then return Functions.vehicleKeys.getAccessiblePlates() end
    if (action == "give") then return Functions.vehicleKeys.give(plate) end
    if (action == "has") then return Functions.vehicleKeys.has(plate) end
    if (action == "remove") then return Functions.vehicleKeys.remove(plate) end

    return false
end

Z.callback.register(("%s:VehicleKeysProviderAction"):format(ResName), handleProviderAction)

return Functions.vehicleKeys