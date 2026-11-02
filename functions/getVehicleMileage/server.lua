local kmPerMile = 1.609344

-- jg-vehiclemileage and zyke_garages store kilometres. jg-vehiclemileage matches the plate exactly and answers 0 for a
-- plate it has no row for, zyke_garages also matches it without spaces and answers nil for a vehicle nobody owns
-- jim-mechanic's docs do not give GetMilage's unit, so its raw distance is read as kilometres until that is confirmed
---@param plate string
---@return number? miles
function Functions.getVehicleMileage(plate)
    local km

    if (MileageSystem == "jg-vehiclemileage") then
        km = exports["jg-vehiclemileage"]:getMileageByPlate(plate)
    elseif (MileageSystem == "zyke_garages") then
        km = exports["zyke_garages"]:GetDistanceDriven(plate)
    elseif (MileageSystem == "jim-mechanic") then
        km = exports["jim-mechanic"]:GetMilage(plate)
    end

    if (not km) then return nil end

    return km / kmPerMile
end

return Functions.getVehicleMileage