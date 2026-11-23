local kmPerMile = 1.609344

-- jg-vehiclemileage, zyke_garages and zyke_mechanic store kilometres. jg-vehiclemileage matches the plate exactly and
-- answers 0 for a plate it has no row for, zyke_garages also matches it without spaces and answers nil for a vehicle
-- nobody owns, zyke_mechanic matches it trimmed and in capitals and answers nil for a car it never saw
---@param plate string
---@return number? mileage @ Miles, except jim-mechanic, whose own distance is passed on as it gives it
function Functions.getVehicleMileage(plate)
    -- jim-mechanic stores the distance its client sends, already in the unit its distkph setting shows
    if (MileageSystem == "jim-mechanic") then return exports["jim-mechanic"]:GetMilage(plate) end

    local km

    if (MileageSystem == "jg-vehiclemileage") then
        km = exports["jg-vehiclemileage"]:getMileageByPlate(plate)
    elseif (MileageSystem == "zyke_garages") then
        km = exports["zyke_garages"]:GetDistanceDriven(plate)
    elseif (MileageSystem == "zyke_mechanic") then
        km = exports["zyke_mechanic"]:GetVehicleKm(plate)
    end

    if (not km) then return nil end

    return km / kmPerMile
end

return Functions.getVehicleMileage