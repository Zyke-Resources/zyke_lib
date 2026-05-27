if (ResName == LibName) then return end

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
local language = LibConfig.language
local baseLanguage = "en"
local translations = {}

local function notFound()
    print(("^1[ERROR] Translation (locales/%s.lua) could not be loaded.^7"):format(language))
end

local function notFoundDefault()
    print("^1[ERROR] Could not find fallback translation (locales/en.lua) CRITICAL!!!^7")
end

local function notFoundSelected()
    print(("^1[WARNING] Translation (locales/%s.lua) not found, using fallback (locales/en.lua).^7"):format(selectedLanguage))
end

if (language == nil) then
    language = baseLanguage
end

---@param key string | table
---@param formatting string[] | string | nil @We may use a single string if we are only formatting one value
---@return string | table, string | nil, string | nil
function Translate(key, formatting)
    if (key == nil) then return "MISSING KEY" end

    local translation = translations[key]
    if (not translation) then return "MISSING TRANSLATION: " .. key end

    local isNotification = type(translation) == "table"
    if (isNotification) then
        local msg = translation.msg
        local notiType = translation.type
        local position = translation.position

        if (formatting) then
            if (type(formatting) == "string" or type(formatting) == "number") then -- Single string/number
                msg = msg:format(formatting)
            elseif (type(formatting) == "table") then -- Array of strings/numbers
                msg = msg:format(table.unpack(formatting))
            end
        end

        return msg, notiType, position
    else
        -- If the translation is a single string
        if (type(formatting) == "string" or type(formatting) == "number") then -- Single string/number
            return translation:format(formatting)
        elseif (type(formatting) == "table") then -- Array of strings/numbers
            return translation:format(table.unpack(formatting))
        end

        return translation
    end
end

---@param langCode string
local function loadTranslation(langCode)
    return LoadResourceFile(ResName, ("locales/%s.lua"):format(langCode))
end

local foundTranslations = loadTranslation(language)
if (not foundTranslations) then
    -- Attempt to run the base language instead
    language = baseLanguage
    foundTranslations = loadTranslation(language)
    if (foundTranslations) then
        notFoundSelected()
    else
        return notFoundDefault()
    end
end

local func, err = load(foundTranslations, ("@@%s/locales/%s.lua"):format(ResName, language))
if (not func or err) then return notFound() end

-- If you are not using the English version, which is our basic language, validate that you have all translations
if (language ~= "en") then
    local baseTranslations = load(LoadResourceFile(ResName, ("locales/%s.lua"):format("en")), ("@@%s/locales/%s.lua"):format(ResName, "en"))()
    local currTranslations = func()

    local missingTranslations = {}
    for key in pairs(baseTranslations) do
        if (currTranslations[key] == nil) then
            missingTranslations[#missingTranslations+1] = key
        end
    end

    if (#missingTranslations > 0) then
        print("^1You have missing translations:^3")

        for i = 1, #missingTranslations do
            print("^1-^3 " .. missingTranslations[i])
        end

        print("^1It is recommended that you fix these.^7")
    end
end

translations = func()

return Translate, translations