-- Wraps an amount in the server's currencyFormat from the zyke_lib config, such as "$%s" or "%s kr"
-- Pre-formatted strings, such as amounts with digit grouping, pass through unchanged inside the format

---@param amount number | string
---@return string formatted
function Functions.formatMoney(amount)
    local value = amount

    -- Whole cents are printed as integers because decimal formatting is unreliable on Linux FXServer builds
    if (type(amount) == "number") then
        local cents = math.floor(math.abs(amount) * 100 + 0.5)
        local sign = amount < 0 and cents > 0 and "-" or ""

        value = cents % 100 == 0 and ("%s%d"):format(sign, cents // 100) or ("%s%d.%02d"):format(sign, cents // 100, cents % 100)
    end

    local format = LibConfig.currencyFormat or "%s"
    local startPos, endPos = format:find("%s", 1, true)
    if (not startPos) then return format .. tostring(value) end

    return format:sub(1, startPos - 1) .. tostring(value) .. format:sub(endPos + 1)
end

return Functions.formatMoney