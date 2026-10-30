local kmPerMile = 1.609344

-- jg-vehiclemileage stores kilometres whatever unit its config shows, and answers 0 for a plate it has no row for
---@param plate string @ As stored, jg-vehiclemileage matches it exactly
---@return number? miles
function Functions.getVehicleMileage(plate)
    if (MileageSystem == "jg-vehiclemileage") then
        local km = exports["jg-vehiclemileage"]:getMileageByPlate(plate)
        if (not km) then return nil end

        return km / kmPerMile
    end

    return nil
end

return Functions.getVehicleMileage