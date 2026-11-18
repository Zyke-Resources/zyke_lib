---@param model string | integer @ Name or hash
---@param skipError? boolean
---@param timeout? integer @ms
---@return boolean
function Functions.loadModel(model, skipError, timeout)
    local isValid = IsModelValid(model) and IsModelInCdimage(model)

    if (not isValid) then
        if (not skipError) then
            error("Tried to load invalid model: " .. model)
        end

        return false
    end

    local started = timeout and GetGameTimer() or nil

    RequestModel(model)
    while (not HasModelLoaded(model)) do
        Wait(0)

        if (timeout and GetGameTimer() - started > timeout) then return false end
    end

    return true
end

return Functions.loadModel