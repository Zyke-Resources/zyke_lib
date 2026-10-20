---@param veh Vehicle
---@param amount number
function Functions.setFuel(veh, amount)
    if (FuelSystem == "LegacyFuel") then return exports["LegacyFuel"]:SetFuel(veh, amount) end
    if (FuelSystem == "OX") then Entity(veh).state.fuel = amount return end
    if (FuelSystem == "CDNFuel") then return exports["cdn-fuel"]:SetFuel(veh, amount) end
    if (FuelSystem == "LCFuel") then return exports["lc_fuel"]:SetFuel(veh, amount) end
    if (FuelSystem == "RcoreFuel") then return exports["rcore_fuel"]:SetVehicleFuel(veh, amount) end

    -- Requires obtaining the fuel type
    if (FuelSystem == "Renewed-Fuel") then
        local fuelType = Entity(veh).state.fuelType
        return exports["Renewed-Fuel"]:SetFuel(veh, amount, fuelType)
    end

    SetVehicleFuelLevel(veh, amount)
end

return Functions.setFuel