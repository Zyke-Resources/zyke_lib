---@param plyId PlayerId
---@param key string
---@param formatting any[]
---@param length number? @ms
---@param raw boolean? @ If true, we will not translate the key & use it as the translated string, it also does not apply any formatting
---@param _notifyType string? @ If provided, we will use it as the notification type instead of the default, primarily meant to substitute for raw
---@param position string? @ ox_lib notification position. Ignored by fallback framework notifications
---@diagnostic disable-next-line: duplicate-set-field
function Functions.notify(plyId, key, formatting, length, raw, _notifyType, position)
    TriggerClientEvent(ResName .. ":notify", plyId, key, formatting, length, raw, _notifyType, position)
end

return Functions.notify