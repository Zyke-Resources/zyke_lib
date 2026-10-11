-- Phones with a server export that delivers a text, keyed by PhoneSystem
-- Quasar only reaches online players, and 17mov_Phone is left out since its export signatures are not verified
local senders = {
    ["sd-phone"] = true,
    ["lb-phone"] = true,
    ["yseries"] = true,
    ["okokPhone"] = true,
    ["roadphone"] = true,
    ["gksphone"] = true,
    ["qs-smartphone"] = true,
    ["qs-smartphone-pro"] = true,
    ["high-phone"] = true,
    ["npwd"] = true,
}

---@return boolean supported @ Whether Z.sendPhoneMessage can deliver a text through the running phone
function Functions.canSendPhoneMessage()
    return PhoneSystem ~= nil and senders[PhoneSystem] == true
end

return Functions.canSendPhoneMessage