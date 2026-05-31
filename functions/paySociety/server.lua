---@param name string
---@param amount number
---@return boolean @success
function Functions.paySociety(name, amount)
    return Functions.society.add(name, amount)
end

return Functions.paySociety