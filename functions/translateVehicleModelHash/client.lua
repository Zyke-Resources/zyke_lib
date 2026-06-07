---@type table<number, string> | nil
local vehicleModelHashes

-- Refreshes and returns the new table
---@return table<number, string>
local function refreshVehicleModelHashes()
    local allModels = GetAllVehicleModels()
    vehicleModelHashes = {}

    for i = 1, #allModels do
        local model = allModels[i]

        vehicleModelHashes[joaat(model)] = model
    end

    return vehicleModelHashes
end

-- Translates, and re-fetches the cache if the model is missing
---@param modelHash number | string
---@return string | nil
function Functions.translateVehicleModelHash(modelHash)
    modelHash = tonumber(modelHash)
    if (not modelHash) then return nil end

    local modelHashes = vehicleModelHashes or refreshVehicleModelHashes()
    local model = modelHashes[modelHash]
    if (model) then return model end

    modelHashes = refreshVehicleModelHashes()

    return modelHashes[modelHash]
end

-- Only register this callback in zyke_lib itself, not in resources that use zyke_lib
-- Otherwise every resource would register the same callback and respond to the same request
if (GetCurrentResourceName() ~= "zyke_lib") then return Functions.translateVehicleModelHash end

---@return table<number, string>
Z.callback.register("zyke_lib:GetVehicleModelHashTranslations", function()
    return refreshVehicleModelHashes()
end)

return Functions.translateVehicleModelHash