---@param veh integer
---@return number fuel
function Functions.getFuel(veh)
    local fuel

    if (FuelSystem == "LegacyFuel") then
        fuel = exports["LegacyFuel"]:GetFuel(veh)
    elseif (FuelSystem == "OX") then
        fuel = GetVehicleFuelLevel(veh)
    elseif (FuelSystem == "CDNFuel") then
        fuel = exports["cdn-fuel"]:GetFuel(veh)
    elseif (FuelSystem == "LCFuel") then
        fuel = exports["lc_fuel"]:GetFuel(veh)
    else
        fuel = GetVehicleFuelLevel(veh)
    end

    fuel = (fuel and tonumber(fuel)) or GetVehicleFuelLevel(veh) or 100.0

    return Functions.numbers.round(fuel, 1)
end

return Functions.getFuel
