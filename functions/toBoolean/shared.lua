---@param value any @ Value to convert
---@param defaultValue boolean @ Default value
---@return boolean result
function Functions.toBoolean(value, defaultValue)
    if (type(value) == "boolean") then return value end
    if (type(value) == "number") then return value ~= 0 end
    if (type(value) ~= "string") then return defaultValue end

    value = value:lower()

    if (value == "true" or value == "yes" or value == "y" or value == "1") then return true end
    if (value == "false" or value == "no" or value == "n" or value == "0") then return false end

    return defaultValue
end

return Functions.toBoolean