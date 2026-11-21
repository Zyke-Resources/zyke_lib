-- Gallery saves keyed by PhoneSystem, each returning the new photo's id, false when the player carries no phone, or
-- nil when the phone refused the URL
---@type table<string, fun(plyId: PlayerId, url: string): string | false | nil>
local saves = {
    ["sd-phone"] = function(plyId, url)
        if (not exports["sd-phone"]:hasPhone(plyId)) then return false end

        -- Stored and shown as given, sd-phone never re-hosts it
        local result = exports["sd-phone"]:addPhoto(plyId, url)

        return type(result) == "table" and result.success == true and result.photo and result.photo.id or nil
    end,
    ["yseries"] = function(plyId, url)
        -- Get the player's equipped/primary phone IMEI
        local phoneImei = exports["yseries"]:GetPhoneImeiBySourceId(plyId)
        if (not phoneImei) then return false end

        -- Insert directly into YSeries gallery (change table to `yflip_gallery` if using YFlip)
        local insertId = MySQL.insert.await("INSERT INTO yphone_gallery (phone_imei, image) VALUES (?, ?)", {
            phoneImei,
            url
        })

        -- Functions.addPhonePhoto strictly checks `type(photoId) == "string"`
        return insertId and tostring(insertId) or nil
    end,
}

-- Yields, call it from a thread or handler
-- The phone shows the URL as given, so only pass a hosted HTTPS URL the player may see
---@param player PlayerId | Character
---@param url string
---@return string? photoId @ The phone's id for the new photo
---@return string? reason @ "invalidPlayer", "invalidUrl", "noPhoneSystem", "noPhone", "unsupported" or "failed"
function Functions.addPhonePhoto(player, url)
    if (not PhoneSystem) then return nil, "noPhoneSystem" end

    local save = saves[PhoneSystem]
    if (not save) then return nil, "unsupported" end
    if (type(url) ~= "string" or not url:find("^https://")) then return nil, "invalidUrl" end

    local playerData = Functions.getPlayerData(player)
    if (not playerData) then return nil, "invalidPlayer" end

    local ok, photoId = pcall(save, Functions.getPlayerId(playerData), url)
    if (not ok) then
        Functions.debug.internal("^1" .. PhoneSystem .. " failed to save a photo to a phone: " .. tostring(photoId) .. "^7")

        return nil, "failed"
    end

    if (photoId == false) then return nil, "noPhone" end
    if (type(photoId) ~= "string") then return nil, "failed" end

    return photoId
end

return Functions.addPhonePhoto
