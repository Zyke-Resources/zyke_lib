-- Resolves a vehicle model label from its hash, with a title-cased fallback if no GXT label exists

-- Known GTA base-game models that have no valid GXT label, so we can suppress warnings for these
local ignoredModels = {
    [-777275802]  = true, -- FREIGHTTRAI
    [1956216962]  = true, -- TANKER
    [-2140210194] = true, -- DOCKTRAILER
    [356391690]   = true, -- proptrailer
    [1019737494]  = true, -- GRAINTRAILE
}

---@param modelHash number
---@return string
function Functions.getModelLabel(modelHash)
    local displayName = GetDisplayNameFromVehicleModel(modelHash)
    local label = GetLabelText(displayName)

    local isInvalid = label == "NULL"
    if (isInvalid) then
        -- If the label is invalid, we'll just use the display name and slightly format it
        -- This would be because you have an addon vehicle without a proper label registered
        label = displayName:lower():gsub("(%a)([%w]*)", function(first, rest)
            return first:upper() .. rest
        end)

        if (not ignoredModels[modelHash]) then
            print("^1[WARNING] ^3Invalid label for model " .. modelHash .. " using display name \"" .. displayName .. "\", using fallback \"" .. label .. "\"^7")
        end
    end

    return label
end

-- Only register this callback in zyke_lib itself, not in resources that use zyke_lib
-- Otherwise every resource would register the same callback and respond to the same request
if (GetCurrentResourceName() ~= "zyke_lib") then return Functions.getModelLabel end

---@return table<number, string>
Z.callback.register("zyke_lib:GetVehicleModelLabels", function()
    local allModels = GetAllVehicleModels()
    local modelLabels = {}

    for i = 1, #allModels do
        local model = allModels[i]
        local modelHash = joaat(model)
        modelLabels[modelHash] = Functions.getModelLabel(modelHash)
    end

    return modelLabels
end)

return Functions.getModelLabel
