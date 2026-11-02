Functions.fuelCan = {}

---@class FuelCan
---@field slot integer
---@field name string
---@field litres number
---@field capacity number @ Litres when full
---@field fuelType string @ "fuel" for every can, none of these fuel systems has fuel types

---@class FuelCanFormat
---@field items string[]
---@field keys string[] @ Metadata keys the fuel may be kept in, the first one the can has is used
---@field mirror? string @ Key kept equal to the fuel when the can has it
---@field full number @ Value of a full can
---@field litres? number @ Litres a full can holds, nil for Renewed-Fuel, whose litres are read on every use
---@field step number @ Smallest change the value is kept in
---@field fuelType? string @ Fuel type of every can, for a fuel system with fuel types that keeps none on the can

-- Add a fuel system by adding the format of its can, read from the item metadata

local untypedFuel = "fuel"

-- US gallon
local litresPerGallon = 3.785411784

-- ox_inventory keeps a petrol can's durability and ammo equal at 0-100, whichever script fills it
---@type FuelCanFormat
local petrolCanPercent = {items = {"WEAPON_PETROLCAN"}, keys = {"durability"}, mirror = "ammo", full = 100.0, litres = 25.0, step = 0.1}

---@type table<string, FuelCanFormat>
local formats = {
    OX = petrolCanPercent,
    -- LegacyFuel keeps the can's fuel as weapon ammo on the client, only an ox_inventory can is readable here
    LegacyFuel = petrolCanPercent,
    -- Litres in ammo, which lc_fuel floors; ox_inventory copies it to durability
    LCFuel = {items = {"WEAPON_PETROLCAN", "weapon_petrolcan"}, keys = {"ammo"}, mirror = "durability", full = 100.0, litres = 100.0, step = 1.0},
    -- Litres in cdn_fuel with ox_inventory and in gasamount with qb inventories
    CDNFuel = {items = {"jerrycan"}, keys = {"cdn_fuel", "gasamount"}, full = 50.0, litres = 50.0, step = 0.01},
    -- ox_inventory floors a Renewed-Fuel can's durability and copies it to ammo, and its cans hold its default fuel type
    ["Renewed-Fuel"] = {items = {"WEAPON_PETROLCAN"}, keys = {"durability"}, mirror = "ammo", full = 100.0, step = 1.0, fuelType = "86"},
}

-- Renewed-Fuel's petrol can config sets a full can's gallons, and a restart may change it
---@return FuelCanFormat? format
local function getFormat()
    local format = formats[FuelSystem]
    if (FuelSystem ~= "Renewed-Fuel" or not format) then return format end
    if (GetResourceState("Renewed-Fuel") ~= "started") then return nil end

    local gallons = tonumber(exports["Renewed-Fuel"]:DurabilityToGallons(format.full))
    if (not gallons or gallons <= 0.0) then return nil end

    format.litres = gallons * litresPerGallon

    return format
end

---@return boolean supported
function Functions.fuelCan.isSupported()
    return formats[FuelSystem] ~= nil
end

---@param format FuelCanFormat
---@param metadata table<string, any>
---@return string key
---@return number value
local function readValue(format, metadata)
    for i = 1, #format.keys do
        local value = tonumber(metadata[format.keys[i]])
        if (value) then return format.keys[i], math.max(0.0, math.min(format.full, value)) end
    end

    return format.keys[1], 0.0
end

---@param format FuelCanFormat
---@param item Item
---@return FuelCan can
local function formatCan(format, item)
    local _, value = readValue(format, item.metadata or {})

    return {slot = item.slot, name = item.name, litres = value / format.full * format.litres, capacity = format.litres, fuelType = format.fuelType or untypedFuel}
end

-- Every jerry can of the fuel system in the player's inventory, empty ones included
---@param plyId PlayerId
---@return FuelCan[] cans
function Functions.fuelCan.getCans(plyId)
    local cans = {}
    local format = getFormat()
    if (not format) then return cans end

    local items = Functions.getPlayerItems(plyId, format.items) or {}

    for i = 1, #items do
        if (items[i].slot) then cans[#cans + 1] = formatCan(format, items[i]) end
    end

    return cans
end

---@param plyId PlayerId
---@param slot integer
---@return FuelCan? can
function Functions.fuelCan.getCan(plyId, slot)
    local cans = Functions.fuelCan.getCans(plyId)

    for i = 1, #cans do
        if (cans[i].slot == slot) then return cans[i] end
    end

    return nil
end

---@param format FuelCanFormat
---@param plyId PlayerId
---@param slot integer
---@param litres number
---@return number? drained
local function drainMetadata(format, plyId, slot, litres)
    local item = Functions.getInventorySlot(plyId, slot)
    if (not item or not item.metadata) then return nil end

    local isCan = false

    for i = 1, #format.items do
        if (format.items[i] == item.name) then isCan = true end
    end

    if (not isCan) then return nil end

    local key, value = readValue(format, item.metadata)
    -- The value is kept in steps, rounded up so no more than litres is drained, and only what it leaves counts
    local left = math.ceil((value - litres / format.litres * format.full) / format.step - 1e-6) * format.step
    left = math.max(0.0, left)

    if (format.step >= 1.0) then left = math.floor(left) end

    local drained = (value - left) / format.full * format.litres
    if (drained <= 0.0) then return nil end

    local metadata = {}

    for k, v in pairs(item.metadata) do
        metadata[k] = v
    end

    -- cdn-fuel keeps its litres as a string
    metadata[key] = type(item.metadata[key]) == "string" and tostring(left) or left

    if (format.mirror and metadata[format.mirror] ~= nil) then metadata[format.mirror] = left end

    -- Renewed-Fuel's optional ox_inventory edits keep a can's gallons and weight beside its durability
    if (FuelSystem == "Renewed-Fuel") then
        if (metadata.oilAmount ~= nil) then metadata.oilAmount = exports["Renewed-Fuel"]:DurabilityToGallons(left) end
        if (metadata.weight ~= nil) then metadata.weight = exports["Renewed-Fuel"]:GetFuelCanWeight(left) end
    end

    if (Functions.setItemMetadata(plyId, slot, metadata) == false) then return nil end

    return drained
end

-- Takes up to litres out of the can in a slot, as long as it still holds fuelType
---@param plyId PlayerId
---@param slot integer
---@param litres number
---@param fuelType string
---@return number? drained @ Litres taken out, nil when nothing was
function Functions.fuelCan.drain(plyId, slot, litres, fuelType)
    if (litres <= 0.0) then return nil end

    local can = Functions.fuelCan.getCan(plyId, slot)
    if (not can or can.fuelType ~= fuelType) then return nil end

    local amount = math.min(litres, can.litres)
    if (amount <= 0.0) then return nil end

    local format = getFormat()
    if (not format) then return nil end

    return drainMetadata(format, plyId, slot, amount)
end

return Functions.fuelCan