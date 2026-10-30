local kmPerMile = 1.609344

-- Both scripts store kilometres. jg-vehiclemileage matches the plate exactly and answers 0 for a plate it has no row
-- for, zyke_garages also matches it without spaces and answers nil for a vehicle nobody owns
---@param plate string
---@return number? miles
function Functions.getVehicleMileage(plate)
    local km

    if (MileageSystem == "jg-vehiclemileage") then
        km = exports["jg-vehiclemileage"]:getMileageByPlate(plate)
    elseif (MileageSystem == "zyke_garages") then
        km = exports["zyke_garages"]:GetDistanceDriven(plate)
    end

    if (not km) then return nil end

    return km / kmPerMile
end

return Functions.getVehicleMileage