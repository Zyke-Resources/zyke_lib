-- Reads the local player's own number through the server, since most phones only expose it there
---@return string? phoneNumber
---@return string? reason
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getPhoneNumber()
    return Functions.callback.request(ResName .. ":GetPhoneNumber", nil)
end

return Functions.getPhoneNumber