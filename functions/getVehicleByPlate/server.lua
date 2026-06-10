---@param plate string
---@return Vehicle | nil, NetId | nil
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getVehicleByPlate(plate)
    local vehicles = GetAllVehicles()

    plate = plate:gsub("%s+", "")

    for i = 1, #vehicles do
        if (GetVehicleNumberPlateText(vehicles[i]):gsub("%s+", "") == plate) then
            return vehicles[i], Functions.network.getNetId(vehicles[i])
        end
    end

    return nil, nil
end

return Functions.getVehicleByPlate