-- Vehicle model hash translator, uses centralized caching
-- Note that we use the auto-refetch if the key is not found, you should double check if the model is valid before calling this function
-- This is a safety measure to prevent our cache from getting stale in case people add new vehicles to the server

return {
    cached = true,

    fetch = function()
        local timeout = 3000
        local timeoutAdd = 500

        local status, modelHashes
        repeat
            local plyId = Functions.getRandomSpawner()
            if (not plyId) then break end

            status, modelHashes = Z.callback.request(plyId, "zyke_lib:GetVehicleModelHashTranslations", {status = true, timeout = timeout})
            timeout = timeout + timeoutAdd
        until (status and status.ok == true)

        return modelHashes
    end,

    -- Uses getCachedValue export which auto-refetches if key not found
    get = function(_, modelHash)
        modelHash = tonumber(modelHash)
        if (not modelHash) then return nil end

        return exports.zyke_lib:getCachedValue("translateVehicleModelHash", modelHash)
    end
}