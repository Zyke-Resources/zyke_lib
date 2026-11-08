-- The client half of Z.sendDispatchAlert, run by zyke_lib so a resource without a client side can send alerts too

-- Milliseconds
local notifyLength = 10000

local radiusAlpha = 128

---@param data table @ ps-dispatch CustomAlert data built by Z.sendDispatchAlert
RegisterNetEvent("zyke_lib:SendPsDispatchAlert", function(data)
    exports["ps-dispatch"]:CustomAlert(data)
end)

---@param alert ResolvedDispatchAlert
---@param name string
local function addBlips(alert, name)
    local coords = alert.coords
    local blip = alert.blip
    local radiusBlip = nil

    if (blip.radius) then
        radiusBlip = AddBlipForRadius(coords.x, coords.y, coords.z, blip.radius)

        SetBlipColour(radiusBlip, blip.colour)
        SetBlipAlpha(radiusBlip, radiusAlpha)
    end

    local pointBlip = Functions.blip.add({
        type = "coord",
        pos = coords,
        sprite = blip.sprite,
        color = blip.colour,
        scale = blip.scale,
        name = name,
    })

    if (pointBlip) then SetBlipFlashes(pointBlip, blip.flash) end

    SetTimeout(blip.duration * 1000, function()
        if (pointBlip) then Functions.blip.remove(pointBlip) end
        if (radiusBlip and DoesBlipExist(radiusBlip)) then RemoveBlip(radiusBlip) end
    end)
end

---@param alert ResolvedDispatchAlert
RegisterNetEvent("zyke_lib:SendDispatchFallback", function(alert)
    local name = alert.code and ("%s - %s"):format(alert.code, alert.title) or alert.title
    local text = alert.description and ("%s: %s"):format(name, alert.description) or name

    Functions.notify("dispatchAlert", text, notifyLength)

    if (alert.sound) then PlaySoundFrontend(-1, "Lose_1st", "GTAO_FM_Events_Soundset", true) end

    addBlips(alert, name)
end)