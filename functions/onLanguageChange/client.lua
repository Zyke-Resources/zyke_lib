-- Runs after this resource's Translations hold the player's new language, for text a resource built once,
-- such as key mappings, blips & target options. Only fires in resources with zyke_player_language "yes"
---@param handler fun(language: string)
function Functions.onLanguageChange(handler)
    AddEventHandler(("zyke_lib:languageChanged:%s"):format(ResName), handler)
end

return Functions.onLanguageChange