-- Phones whose gallery other resources can read and save to, keyed by PhoneSystem
local galleries = {
    ["sd-phone"] = true,
}

---@return boolean supported @ Whether Z.getPhonePhotos and Z.addPhonePhoto work with the running phone
function Functions.canUsePhonePhotos()
    return PhoneSystem ~= nil and galleries[PhoneSystem] == true
end

return Functions.canUsePhonePhotos