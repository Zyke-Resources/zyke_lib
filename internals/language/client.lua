-- The player's own language: stored on their PC, set on the server, which checks it & shares it with every resource
local kvpKey = "language"
local serverLanguage = LibConfig.language or "en"

-- In their own language, so a player finds theirs whatever they read now
local nativeNames = {
    en = "English",
    sv = "Svenska",
    de = "Deutsch",
    fr = "Français",
    es = "Español",
    it = "Italiano",
    pt = "Português",
    nl = "Nederlands",
    pl = "Polski",
    cs = "Čeština",
    ro = "Română",
    tr = "Türkçe",
    lt = "Lietuvių",
    ar = "العربية",
    ja = "日本語",
    zh = "中文",
    th = "ไทย",
    da = "Dansk",
    fi = "Suomi",
    no = "Norsk",
    hu = "Magyar",
    ru = "Русский",
    vi = "Tiếng Việt",
}

---@type string[]
local languages = {}
---@type table<string, true>
local allowedLanguages = {}
for _, language in ipairs({serverLanguage, table.unpack(LibConfig.playerLanguages or {})}) do
    if (not allowedLanguages[language]) then
        allowedLanguages[language] = true
        languages[#languages+1] = language
    end
end

-- Picked in this session, notified once it is set
---@type string?
local pickedLanguage = nil

---@param language string
local function pickLanguage(language)
    pickedLanguage = language

    SetResourceKvp(kvpKey, language)
    TriggerServerEvent("zyke_lib:setLanguage", language)
end

local function openLanguageMenu()
    local current = LocalPlayer.state["zyke_lib:language"] or serverLanguage
    local options = {}

    for i = 1, #languages do
        local language = languages[i]

        options[i] = {
            title = nativeNames[language] or language,
            description = language,
            icon = language == current and "check" or "translate",
            onSelect = function() pickLanguage(language) end,
        }
    end

    Functions.registerContext({
        id = "zyke_lib:language",
        title = T("languageMenuTitle"),
        icon = "translate",
        options = options,
    })
    Functions.showContext("zyke_lib:language")
end

---@param language string
Functions.onLanguageChange(function(language)
    if (language ~= pickedLanguage) then return end

    pickedLanguage = nil

    Functions.notify("languageChanged", nativeNames[language] or language)
end)

-- With no other language to pick, the command is left out
if (#languages > 1) then
    ---@param args string[]
    RegisterCommand(LibConfig.languageCommand or "language", function(_, args)
        local language = args[1]
        if (not language) then return openLanguageMenu() end
        if (not allowedLanguages[language]) then return Functions.notify("languageUnknown", table.concat(languages, ", ")) end

        pickLanguage(language)
    end, false)
end

-- One the server no longer offers is ignored
local storedLanguage = GetResourceKvpString(kvpKey)
if (storedLanguage and allowedLanguages[storedLanguage]) then TriggerServerEvent("zyke_lib:setLanguage", storedLanguage) end