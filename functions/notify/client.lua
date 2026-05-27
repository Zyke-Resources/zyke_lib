---@param key string
---@param formatting any[]
---@param length number? @ms
---@param raw boolean? @ If true, we will not translate the key & use it as the translated string, it also does not apply any formatting
---@param _notifyType string? @ If provided, we will use it as the notification type instead of the default, primarily meant to substitute for raw
---@param position string? @ ox_lib notification position. Ignored by fallback framework notifications
---@diagnostic disable-next-line: duplicate-set-field
function Functions.notify(key, formatting, length, raw, _notifyType, position)
    local notifyStr, notifyType = nil, _notifyType
    if (raw == true) then
        notifyStr = key
    else
        local localePosition = nil

        notifyStr, notifyType, localePosition = T(key, formatting)
        notifyType = notifyType or _notifyType
        position = position or localePosition
    end

    notifyType = notifyType or "primary"

    if (NotificationSystem == "OX") then
        local oxNotifyType = notifyType
        if (oxNotifyType == "primary") then oxNotifyType = "info" end

        TriggerEvent("ox_lib:notify", {
            description = notifyStr,
            type = oxNotifyType,
            duration = length,
            position = position,
        })

        return
    end

    if (Framework == "QB") then QB.Functions.Notify(notifyStr, notifyType, length) return end

    if (Framework == "ESX") then
        if (notifyType == "primary") then notifyType = "info" end
        if (notifyType == "warning") then notifyType = "error" end

        ESX.ShowNotification(notifyStr, notifyType, length)
        return
    end
end

RegisterNetEvent(ResName .. ":notify", function(key, formatting, length, raw, _notifyType, position)
    Functions.notify(key, formatting, length, raw, _notifyType, position)
end)

return Functions.notify