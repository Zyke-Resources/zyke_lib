Functions.fuelCan = {}

-- Reading and draining the cans is server-side, this mirrors which fuel systems it covers
---@return boolean supported
function Functions.fuelCan.isSupported()
    return FuelSystem == "OX" or FuelSystem == "LegacyFuel" or FuelSystem == "LCFuel" or FuelSystem == "CDNFuel" or FuelSystem == "RenewedFuel"
end

return Functions.fuelCan
