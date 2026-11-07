-- The page copies at once when the copy follows a click on it. Otherwise it shows a card, and the click on it copies,
-- since FiveM's browser refuses a copy no click or key press on the page led to

-- zyke_lib's own focus from before the card opened, kept when the card closes, such as a form's
local hadFocus = false

---@param text string
function Functions.copy(text)
    SendNUIMessage({
        event = "copy",
        data = {
            text = text,
            title = T("copyTitle"),
            button = T("copyButton"),
        },
    })
end

RegisterNUICallback("Eventhandler:Copy", function(passed, cb)
    cb("ok")

    if (passed.event == "needsClick") then
        hadFocus = IsNuiFocused()

        return SetNuiFocus(true, true)
    end

    if (passed.event == "closed" and not hadFocus) then SetNuiFocus(false, false) end
end)