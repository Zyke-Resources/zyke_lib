---@param dict string
---@param skipError? boolean
---@param timeout? integer @ms
---@return boolean
function Functions.loadDict(dict, skipError, timeout)
    local isValid = DoesAnimDictExist(dict)
    if (not isValid) then
        if (not skipError) then
            error("Tried to load invalid animation dictionary: " .. dict)
        end

        return false
    end

    local started = timeout and GetGameTimer() or nil

    RequestAnimDict(dict)
    while (not HasAnimDictLoaded(dict)) do
        Wait(0)

        if (timeout and GetGameTimer() - started > timeout) then return false end
    end

    return true
end

return Functions.loadDict