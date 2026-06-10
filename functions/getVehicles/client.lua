-- TODO: Redo this once I see fit and find time

-- Note that you can only use limited options when only using the client, such as states not always being synced the same (but usually is), getting routing buckets, etc
---@param serverFetch boolean? @Used client-side to allow for server-sided vehicle fetch, allows reach beyond your render
---@param options? GetVehicleOptions
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getVehicles(serverFetch, options)
    if (serverFetch) then
        return Functions.callback.await("zyke_lib:GetVehicles", options) -- Will callback and run the same complete function on the server side
    end

    local vehicles = GetGamePool("CVehicle")

    ---@diagnostic disable-next-line: return-type-mismatch @GetAllVehicles() always returns a table, not an integer as far as my testing went
    if (not options) then return vehicles end

    local formatted = {}

    -- Verifying maxDistance
    local maxDistance = options.maxDistance
    if (maxDistance == false) then
        maxDistance = -1
    elseif (maxDistance == nil) then
        maxDistance = 350.0
    end

    -- Verifying positions
    local pos = options.pos
    if (not pos) then
        pos = GetEntityCoords(PlayerPedId())
    end

    -- Make sure you have a position to check distance with if you are utilizing maxDistance
    if (maxDistance and maxDistance > 0 and not pos) then
        error("Trying to utilize maxDistance without providing a position to check distance with")
    end

    -- Verifying states
    local filterByStates = type(options.states) == "table"

    ---@diagnostic disable-next-line: param-type-mismatch @GetAllVehicles() always returns a table, not an integer as far as my testing went
    for _, veh in pairs(vehicles) do
        -- Check if it's within reach
        if (maxDistance ~= nil) then
            if (maxDistance ~= -1) then
                local dst = #(pos - GetEntityCoords(veh))
                if (dst > maxDistance) then goto continue end
            end
        end

        -- Check if it's within the required states
        if (filterByStates) then
            for state, requiredValue in pairs(options.states) do
                local entityStateValue = Entity(veh)?.state?[state]

                if (requiredValue == "none") then
                    if (entityStateValue == nil) then goto continue end
                elseif (requiredValue == "optional") then
                else
                    if (requiredValue ~= entityStateValue) then goto continue end
                end
            end
        end

        if (options.netId) then
            local netId = Functions.network.getNetId(veh)
            if (netId ~= options.netId) then goto continue end
        end

        local vehicleDetails
        if (options.detailed) then
            vehicleDetails = {
                pos = GetEntityCoords(veh),
                netId = Functions.network.getNetId(veh),
                plate = GetVehicleNumberPlateText(veh),
                vehicleType = GetVehicleType(veh),
                model = GetEntityModel(veh),
                handler = veh,
            }

            if (type(options.detailed) == "table") then
                if (options.detailed.includeStates) then
                    for state in pairs(options.states) do
                        vehicleDetails[state] = Entity(veh)?.state?[state]
                    end
                end
            end

            table.insert(formatted, vehicleDetails)
        else
            table.insert(formatted, veh)
        end

        -- If you can reach here and you're looking for a specific netId, then you've found it
        if (options.netId) then
            break
        end

        ::continue::
    end

    return formatted
end

return Functions.getVehicles