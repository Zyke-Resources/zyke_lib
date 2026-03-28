---@param text string
function Functions.copy(text)
    SendNUIMessage({
        event = "copy",
        data = {
            text = text,
        },
    })
end