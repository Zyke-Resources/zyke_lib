---@return boolean
local function dirExists()
    local num = GetNumResourceMetadata(ResName, "file")
    if (num == 0) then return false end

    for i = 1, num do
        local str = GetResourceMetadata(ResName, "file", i - 1)

        if (str:sub(1, 8) == "locales/") then
            return true
        end
    end

    return false
end

if (not dirExists()) then return nil end

local selectedLanguage = LibConfig.language
local baseLanguage = "en"
local serverLanguage = selectedLanguage or baseLanguage
-- Player state the server sets from each player's own choice
local languageStateKey = "zyke_lib:language"
-- From zyke_player_language "yes" in the fxmanifest.lua, other resources stay in the server language
local isPerPlayer = GetResourceMetadata(ResName, "zyke_player_language", 0) == "yes"
-- A resource without a page logs a warning for each NUI message
local hasNui = GetResourceMetadata(ResName, "ui_page", 0) ~= nil

---@type table<string, table<string, string | table> | false> @ Locale files by language, false for one that is missing
local loadedStrings = {}
---@type table<string, true> @ Keys whose text failed to format, so each one warns once
local brokenKeys = {}
-- Server settings added to every language's strings, never in a locale file
local formatKeys = {localeString = true, currencyFormat = true}

local function notFoundDefault()
    print("^1[ERROR] Could not find fallback translation (locales/en.lua) CRITICAL!!!^7")
end

local function notFoundSelected()
    print(("^1[WARNING] Translation (locales/%s.lua) not found, using fallback (locales/en.lua).^7"):format(selectedLanguage))
end

---@param language string
---@return table<string, string | table>? strings
local function readLocale(language)
    -- The language can come from a player's choice, so it never reaches a file path unchecked
    if (type(language) ~= "string" or not language:find("^[%a_%-]+$")) then return nil end

    local source = LoadResourceFile(ResName, ("locales/%s.lua"):format(language))
    if (not source) then return nil end

    local func, err = load(source, ("@@%s/locales/%s.lua"):format(ResName, language))
    if (not func) then
        print(("^1[ERROR] Translation (locales/%s.lua) could not be loaded: %s^7"):format(language, err))

        return nil
    end

    local strings = func()

    return type(strings) == "table" and strings or nil
end

-- English fills every key a locale file lacks, so a partly translated file still shows text
---@param language string
---@param warnMissing? boolean
---@return table<string, string | table>? strings @ Nil for a language this resource has no locale file for
local function getStrings(language, warnMissing)
    if (loadedStrings[language] ~= nil) then return loadedStrings[language] or nil end

    local strings = readLocale(language)
    if (not strings) then
        loadedStrings[language] = false

        return nil
    end

    if (language ~= baseLanguage) then
        local missingTranslations = {}

        for key, baseTranslation in pairs(getStrings(baseLanguage) or {}) do
            if (strings[key] == nil and not formatKeys[key]) then
                missingTranslations[#missingTranslations+1] = key
                strings[key] = baseTranslation
            end
        end

        if (warnMissing and #missingTranslations > 0) then
            print("^1You have missing translations:^3")

            for i = 1, #missingTranslations do
                print("^1-^3 " .. missingTranslations[i])
            end

            print("^1It is recommended that you fix these.^7")
        end
    end

    -- Number & money formats are server settings, not part of a language
    strings.localeString = LibConfig.localeString
    strings.currencyFormat = LibConfig.currencyFormat
    loadedStrings[language] = strings

    return strings
end

local serverStrings = getStrings(serverLanguage, true)
if (not serverStrings) then
    serverLanguage = baseLanguage
    serverStrings = getStrings(baseLanguage)

    if (not serverStrings) then return notFoundDefault() end

    notFoundSelected()
end

-- Handed out as Translations & swapped in place on a language change, since other code keeps references to it
local translations = {}
for key, value in pairs(serverStrings) do
    translations[key] = value
end

---@param text string
---@param formatting? any[] | string | number
---@return string
local function format(text, formatting)
    if (type(formatting) == "table") then return text:format(table.unpack(formatting)) end
    if (type(formatting) == "string" or type(formatting) == "number") then return text:format(formatting) end

    return text
end

-- A placeholder a translator got wrong falls back to the English text instead of breaking the handler that asked
---@param key string
---@param text string
---@param formatting? any[] | string | number
---@return string
local function formatSafely(key, text, formatting)
    local isFormatted, result = pcall(format, text, formatting)
    if (isFormatted) then return result end

    if (not brokenKeys[key]) then
        brokenKeys[key] = true

        print(("^1[zyke_lib] %s could not format the translation '%s': %s^7"):format(ResName, key, result))
    end

    local baseTranslation = (getStrings(baseLanguage) or {})[key]
    local baseText = type(baseTranslation) == "table" and baseTranslation.msg or baseTranslation
    if (type(baseText) ~= "string" or baseText == text) then return text end

    local isBaseFormatted, baseResult = pcall(format, baseText, formatting)

    return isBaseFormatted and baseResult or baseText
end

---@param strings table<string, string | table>
---@param key string
---@param formatting? any[] | string | number
---@return string | table, string | nil, string | nil
local function translateWith(strings, key, formatting)
    if (key == nil) then return "MISSING KEY" end

    local translation = strings[key]
    if (not translation) then return "MISSING TRANSLATION: " .. key end

    if (type(translation) == "table") then
        return formatSafely(key, translation.msg, formatting), translation.type, translation.position
    end

    return formatSafely(key, translation, formatting)
end

---@param key string
---@param formatting? any[] | string | number @ A single value fills the only placeholder
---@return string | table, string | nil, string | nil
function Translate(key, formatting)
    return translateWith(translations, key, formatting)
end

-- T writes in the server language on the server. This writes in the language the player sees this resource in,
-- for text that only reaches that player, such as a callback result or a message built on the server
---@param plyId PlayerId
---@param key string
---@param formatting? any[] | string | number
---@return string | table, string | nil, string | nil
function TranslateFor(plyId, key, formatting)
    if (Context ~= "server" or not isPerPlayer) then return Translate(key, formatting) end

    local language = Player(plyId).state[languageStateKey]
    local strings = language and language ~= serverLanguage and getStrings(language)
    if (not strings) then return Translate(key, formatting) end

    return translateWith(strings, key, formatting)
end

if (Context == "client" and isPerPlayer) then
    local currentStrings = serverStrings

    -- A language this resource has no locale file for shows the server language
    ---@param language? string
    ---@return boolean isChanged
    local function useLanguage(language)
        local strings = language and getStrings(language) or serverStrings
        if (strings == currentStrings) then return false end

        for key in pairs(translations) do
            translations[key] = nil
        end

        for key, value in pairs(strings) do
            translations[key] = value
        end

        currentStrings = strings

        return true
    end

    -- Read while the resource starts, so one started later in the session opens in the player's language
    useLanguage(LocalPlayer.state[languageStateKey])

    ---@param value? string
    AddStateBagChangeHandler(languageStateKey, ("player:%s"):format(GetPlayerServerId(PlayerId())), function(_, _, value)
        if (not useLanguage(value)) then return end

        -- Every NUI asks for its strings once, so it is sent the new ones
        if (hasNui) then SendNUIMessage({event = "zyke_lib:strings", data = translations}) end

        TriggerEvent(("zyke_lib:languageChanged:%s"):format(ResName), value or serverLanguage)
    end)
end

return Translate, translations, TranslateFor