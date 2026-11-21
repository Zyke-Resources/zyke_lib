---@class PhoneApp
---@field id string @ Unique across every resource, such as "zyke_laptop_browser"
---@field name string
---@field description string @ Shown in the phone's App Store
---@field ui string @ A page of the calling resource as "resource/path/page.html"
---@field icon string @ An image URL, such as "https://cfx-nui-resource/icon.svg"
---@field developer? string
---@field preinstalled? boolean @ On every phone from the start, otherwise players get it from the phone's App Store

-- Phones that take apps of other resources, keyed by PhoneSystem
-- sd-phone replaces an app registered again, lb-phone takes it away first so a new name shows
---@type table<string, fun(app: PhoneApp): boolean, string?>
local adds = {
    ["sd-phone"] = function(app)
        return exports["sd-phone"]:addCustomApp({
            identifier = app.id,
            name = app.name,
            description = app.description,
            developer = app.developer,
            defaultApp = app.preinstalled == true,
            ui = app.ui,
            icon = app.icon,
        })
    end,
    ["lb-phone"] = function(app)
        exports["lb-phone"]:RemoveCustomApp(app.id)

        return exports["lb-phone"]:AddCustomApp({
            identifier = app.id,
            name = app.name,
            description = app.description,
            developer = app.developer,
            defaultApp = app.preinstalled == true,
            ui = app.ui,
            icon = app.icon,
        })
    end,
    ["yseries"] = function(app)
        exports["yseries"]:RemoveCustomApp(app.id)

        -- YSeries expects a full `https://cfx-nui-...` URL rather than a bare `resource/path/page.html` string
        local uiUrl = app.ui:find("^https?://") and app.ui or ("https://cfx-nui-" .. app.ui)

        return exports["yseries"]:AddCustomApp({
            key = app.id,
            name = app.name,
            description = app.description,
            developer = app.developer,
            defaultApp = app.preinstalled == true,
            ui = uiUrl,
            icon = app.icon,
        })
    end
}

-- Added again whenever the phone starts, it forgets the apps of other resources when it stops
---@type table<string, PhoneApp>
local apps = {}

---@param app PhoneApp
---@return boolean registered
---@return string? reason
local function add(app)
    local addApp = PhoneSystem and adds[PhoneSystem]
    if (not addApp) then return false, "unsupported" end

    local registered, err = addApp(app)
    if (registered) then return true end

    print(("^1[zyke_lib] %s could not add the %s app to %s: %s^7"):format(ResName, app.id, PhoneSystem, tostring(err)))

    return false, "failed"
end

-- The phone's exports answer a moment after it reports started
---@param resourceName string
AddEventHandler("onClientResourceStart", function(resourceName)
    if (resourceName ~= PhoneSystem or next(apps) == nil) then return end

    SetTimeout(1000, function()
        for _, app in pairs(apps) do
            add(app)
        end
    end)
end)

-- Puts an app of the calling resource on the running phone, which shows its page in a frame of its own
-- The page reaches its resource's NUI callbacks with fetch like any NUI page, call it again to change the app
---@param app PhoneApp
---@return boolean registered @ False while no phone that takes apps runs, the app is added once one starts
---@return string? reason @ "unsupported" or "failed"
function Functions.registerPhoneApp(app)
    apps[app.id] = app

    return add(app)
end

return Functions.registerPhoneApp
