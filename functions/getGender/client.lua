---@return "male" | "female"
---@diagnostic disable-next-line: duplicate-set-field
function Functions.getGender()
    local player = Functions.getPlayerData()
    if (not player) then return IsPedMale(PlayerPedId()) and "male" or "female" end

    if (Framework == "ESX") then return player?.sex == "m" and "male" or "female" end
    if (Framework == "QB") then return player?.charinfo?.gender == 0 and "male" or "female" end

    return IsPedMale(PlayerPedId()) and "male" or "female"
end

return Functions.getGender
