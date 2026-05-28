Functions.numbers = {}

---@param number number
---@param decimals? integer @0 default
---@return integer | number
function Functions.numbers.round(number, decimals)
    local multiplier = 10 ^ (decimals or 0)

    return math.floor(number * multiplier + 0.5) / multiplier
end

---@param value number
---@param min number
---@param max number
---@return number
function Functions.numbers.clamp(value, min, max)
    if (value < min) then return min end
    if (value > max) then return max end

    return value
end

return Functions.numbers