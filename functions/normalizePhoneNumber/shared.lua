-- Builds the comparison key for phone numbers, which phones store in different formats
-- Letters are kept so vanity numbers like 555-BUSINESS stay distinct, while leading zeros and country codes are left alone
---@param phoneNumber? string | number
---@return string? normalized @ nil when nothing usable is left
function Functions.normalizePhoneNumber(phoneNumber)
    if (type(phoneNumber) == "number") then phoneNumber = tostring(math.tointeger(phoneNumber) or phoneNumber) end
    if (type(phoneNumber) ~= "string") then return nil end

    local normalized = phoneNumber:upper():gsub("[^%w]", "")
    if (normalized == "") then return nil end

    return normalized
end

return Functions.normalizePhoneNumber