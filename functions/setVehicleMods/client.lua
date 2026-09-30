---@param value any @ Candidate RGB color array, {r, g, b}
---@return integer[] | nil
local function normalizeRgbArray(value)
    if (type(value) ~= "table") then return nil end

    local r, g, b = tonumber(value[1]), tonumber(value[2]), tonumber(value[3])
    if (not r or not g or not b) then return nil end

    return {r, g, b}
end

-- Foreign formats store different shapes in these fields, like RGB arrays in paint indexes
-- Frameworks pass props into natives unchecked, so normalize them to avoid errors killing the caller
---@param mods table
local function sanitizeVehicleMods(mods)
    -- Keep indexed colors numeric for both providers, including QB's mixed-color path
    for _, key in ipairs({"color1", "color2", "xenonColor"}) do
        if (type(mods[key]) ~= "number") then mods[key] = nil end
    end

    for _, key in ipairs({"customPrimaryColor", "customSecondaryColor", "customXenonColor", "neonColor", "tyreSmokeColor"}) do
        mods[key] = normalizeRgbArray(mods[key])
    end

    if (mods.neonEnabled ~= nil) then
        local enabled = mods.neonEnabled
        mods.neonEnabled = type(enabled) == "table" and {
            enabled[1] == true or enabled[1] == 1,
            enabled[2] == true or enabled[2] == 1,
            enabled[3] == true or enabled[3] == 1,
            enabled[4] == true or enabled[4] == 1,
        } or nil
    end

    if (type(mods.plate) == "number") then
        mods.plate = tostring(mods.plate)
    elseif (mods.plate ~= nil and type(mods.plate) ~= "string") then
        mods.plate = nil
    end

    for _, key in ipairs({"pearlescentColor", "wheelColor", "interiorColor", "dashboardColor", "windowTint", "wheels", "plateIndex", "wheelSize", "wheelWidth", "paintType1", "paintType2", "lockState", "modRoofLivery", "liveryRoof", "livery", "modLivery", "bodyHealth", "engineHealth", "tankHealth", "fuelLevel", "oilLevel", "dirtLevel", "fuel", "engine", "body"}) do
        if (mods[key] ~= nil and type(mods[key]) ~= "number") then mods[key] = nil end
    end

    for _, key in ipairs({"tyresCanBurst", "bulletProofTyres", "driftTyres", "modTurbo", "modSmokeEnabled", "modXenon", "modSubwoofer", "modHydraulics", "modCustomTiresF", "modCustomTiresR"}) do
        local value = mods[key]
        if (value == 1) then mods[key] = true
        elseif (value == 0) then mods[key] = false
        elseif (value ~= nil and type(value) ~= "boolean") then mods[key] = nil end
    end

    for _, key in ipairs({"extras", "windowsBroken", "doorsBroken", "tyreBurst", "windowStatus", "doorStatus", "tireHealth", "tireBurstState", "tireBurstCompletely", "tyres", "windows", "doors"}) do
        if (mods[key] ~= nil and type(mods[key]) ~= "table") then mods[key] = nil end
    end

    -- Remaining mod fields are always numbers or booleans in framework formats
    for key, value in pairs(mods) do
        if (type(key) == "string" and key:match("^mod%u") and type(value) ~= "number" and type(value) ~= "boolean") then
            mods[key] = nil
        end
    end
end

---@param veh integer
---@param mods table
function Functions.setVehicleMods(veh, mods)
    if (not DoesEntityExist(veh)) then return end
    if (type(mods) ~= "table") then return end

    -- Do not rewrite the caller's saved properties while adapting provider formats
    local properties = {}

    for key, value in pairs(mods) do
        properties[key] = value
    end

    local primary = normalizeRgbArray(mods.customPrimaryColor) or normalizeRgbArray(mods.color1)
    local secondary = normalizeRgbArray(mods.customSecondaryColor) or normalizeRgbArray(mods.color2)
    local xenon = normalizeRgbArray(mods.customXenonColor) or normalizeRgbArray(mods.xenonColor)
    mods = properties
    sanitizeVehicleMods(mods)
    mods.customPrimaryColor = nil
    mods.customSecondaryColor = nil
    mods.customXenonColor = nil

    if (Framework == "ESX") then
        ESX.Game.SetVehicleProperties(veh, mods)
    elseif (Framework == "QB") then
        QB.Functions.SetVehicleProperties(veh, mods)
    end

    -- Frameworks also apply modLivery as the native livery, and unset native liveries spawn randomized
    -- Older QB saves omit livery, where a modLivery of -1 means the native livery was 0
    local livery = mods.livery
    if (livery == nil and mods.modLivery == -1) then livery = 0 end
    if (livery and livery >= 0 and livery < GetVehicleLiveryCount(veh)) then SetVehicleLivery(veh, livery) end

    -- Apply RGB after indexed paint so provider ordering cannot overwrite custom colors
    if (primary) then SetVehicleCustomPrimaryColour(veh, primary[1], primary[2], primary[3]) end
    if (secondary) then SetVehicleCustomSecondaryColour(veh, secondary[1], secondary[2], secondary[3]) end
    if (xenon) then SetVehicleXenonLightsCustomColor(veh, xenon[1], xenon[2], xenon[3]) end

    Functions.setFuel(veh, mods.fuel)

    -- Extra since depending on your ESX/QB version, this may not work as they use strings instead of integers, which is incorrect
    if (mods.windowStatus) then
        for windowId, isIntact in pairs(mods.windowStatus) do
            if (not isIntact) then
                ---@diagnostic disable-next-line: param-type-mismatch
                SmashVehicleWindow(veh, tonumber(windowId))
            end
        end
    end
end

return Functions.setVehicleMods