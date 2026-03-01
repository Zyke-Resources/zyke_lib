---@diagnostic disable-next-line: duplicate-set-field
function Functions.unequipWeapon()
    local _inv = Inventory

    if (_inv == "OX") then
        TriggerEvent("ox_inventory:disarm")
    elseif (_inv == "TGIANN") then
        TriggerEvent("inventory:client:removeWeapon")
    else
        -- QS, CODEM, C8RE, DEFAULT — no dedicated export
        SetCurrentPedWeapon(PlayerPedId(), `WEAPON_UNARMED`, true)
    end
end

return Functions.unequipWeapon
