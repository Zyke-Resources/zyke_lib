-- TODO: Redo this once I see fit and find time

---@class DetailedVehicle
---@field pos vector3
---@field netId number
---@field plate string
---@field vehicleType string
---@field model string
---@field handler number

---@class GetVehicleOptionsDetails
---@field includeStates boolean -- Includes all of the required states, note that you can not name the state keys as any of the default detail properties

---@class GetVehicleOptions
---@field maxDistance number | false | nil @Use number, if false (or -1) it will go as far as you can render, nil will default to 350.0
---@field pos vector3 | vector4 | table @Position to check distance with, if not provided it will use your player position if client
---@field states table? @States to filter by, example: {locked = true, engine = true}, note that you can also set the value to "none" to solely filter based on the state existing, set as "optional" to include if includeStates is true, but not required
---@field detailed GetVehicleOptionsDetails | boolean? @Will give you class DetailedVehicle when set to true, if set to a table it will act as a boolean, but also allows you to add more details
---@field netId integer? @If passed in, it will only return the vehicle with the matching netId (Will perform a break for next iteration)

-- TODO: Make sure you're fetching from the correct routing session
-- Note that you can only use limited options when only using the client, such as states not always being synced the same (but usually is), getting routing buckets, etc
---@param _ boolean? @DEPRECATED
---@param options? GetVehicleOptions
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getVehicles(_, options)
    local vehicles = GetAllVehicles()

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

Functions.callback.register("zyke_lib:GetVehicles", function(source, data)
    return Functions.getVehicles(true, data)
end)

return Functions.getVehicles