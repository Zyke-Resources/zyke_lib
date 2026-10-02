Functions.vehicle = {}

---@class ZykeVehicleStorageSize
---@field slots integer
---@field weight integer @ Grams

-- {slots, weight} per vehicle class, used when the inventory has no readable vehicle config
local defaultTrunkSizes = {
    [0] = {20, 100000},
    [1] = {40, 150000},
    [2] = {50, 250000},
    [3] = {30, 120000},
    [4] = {40, 160000},
    [5] = {30, 120000},
    [6] = {30, 120000},
    [7] = {20, 100000},
    [8] = {5, 20000},
    [9] = {50, 250000},
    [10] = {50, 300000},
    [11] = {40, 200000},
    [12] = {60, 300000},
    [17] = {40, 200000},
    [18] = {40, 200000},
    [19] = {40, 200000},
    [20] = {60, 500000},
}

local defaultGloveboxSize = {5, 10000}

-- ox_inventory Storage modes that remove each inventory from a model
local oxDisabledStorage = {
    trunk = {[0] = true, [1] = true},
    glovebox = {[0] = true, [2] = true},
}

local oxVehicleConfig

---@return table? config @ ox_inventory data/vehicles.lua
local function getOxVehicleConfig()
    if (oxVehicleConfig == nil) then
        local chunk = LoadResourceFile("ox_inventory", "data/vehicles.lua")
        local success, config = pcall(load(chunk or "", "@@ox_inventory/data/vehicles.lua"))

        oxVehicleConfig = success and type(config) == "table" and config or false
    end

    return oxVehicleConfig or nil
end

---@param model string | integer @ Vehicle model name or hash
---@param storage "trunk" | "glovebox"
---@return ZykeVehicleStorageSize? size @ nil when the model has no such storage
local function getStorageSize(model, storage)
    local modelHash = tonumber(model) or joaat(model)
    local vehicleClass = GetVehicleClassFromName(modelHash)
    local size

    local oxConfig = Inventory == "OX" and getOxVehicleConfig()
    if (oxConfig and oxConfig[storage]) then
        if (oxDisabledStorage[storage][oxConfig.Storage?[modelHash]]) then return nil end

        size = oxConfig[storage].models?[modelHash] or oxConfig[storage][vehicleClass]
    elseif (storage == "trunk") then
        size = defaultTrunkSizes[vehicleClass]
    else
        -- Classes without a trunk are bicycles, boats and aircraft
        size = defaultTrunkSizes[vehicleClass] and defaultGloveboxSize
    end

    if (not size) then return nil end

    return {slots = size[1], weight = size[2]}
end

---@param ply Ped
---@param veh? Vehicle @If not provided, will ues their current vehicle
function Functions.vehicle.isDriver(ply, veh)
    if (not veh) then
        veh = GetVehiclePedIsIn(ply, false)
    end

    return GetPedInVehicleSeat(veh, -1) == ply
end

---@param model string | integer @ Vehicle model name or hash
---@return ZykeVehicleStorageSize? trunkSize
function Functions.vehicle.getTrunkSize(model)
    return getStorageSize(model, "trunk")
end

---@param model string | integer @ Vehicle model name or hash
---@return ZykeVehicleStorageSize? gloveboxSize
function Functions.vehicle.getGloveboxSize(model)
    return getStorageSize(model, "glovebox")
end

return Functions.vehicle