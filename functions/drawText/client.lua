---@param value any
---@param fallback integer
---@return integer
local function getTextColorComponent(value, fallback)
    if (type(value) ~= "number") then return fallback end

    return math.floor(math.max(0, math.min(255, value)))
end

---@param text string
---@param x number? @default 0.5
---@param y number? @default 0.96
---@param scale number? @default 0.5
---@param font integer? 0 | 1 | 2 | 4 | 6 | 7 @default 4
---@param justify? "center" | "right" | "left"
---@param rgba? {r?: integer, g?: integer, b?: integer, a?: integer} @default {r = 255, g = 255, b = 255, a = 255}
---@param options? {edge?: boolean, outline?: boolean, dropShadow?: boolean}
function Functions.drawText(text, x, y, scale, font, justify, rgba, options)
    local length = x or 0.5 -- Bottom
    local height = y or 0.96 -- Center

    scale = scale or 0.5
    font = font
    rgba = rgba or {}
    options = options or {}

    -- Fonts can be 0
    if (type(font) ~= "number") then font = 4 end

    SetTextScale(scale, scale)
    SetTextFont(font)
    SetTextColour(
        getTextColorComponent(rgba.r, 255),
        getTextColorComponent(rgba.g, 255),
        getTextColorComponent(rgba.b, 255),
        getTextColorComponent(rgba.a, 255)
    )

    if (options.edge ~= false) then
        SetTextEdge(2, 0, 0, 0, 150)
    end

    if (options.dropShadow == true) then
        SetTextDropshadow(1, 0, 0, 0, 255)
    end

    SetTextEntry("STRING")

    if (justify == "right") then
        SetTextRightJustify(true)
        SetTextCentre(false)
    elseif (justify == "left") then
        SetTextRightJustify(false)
        SetTextCentre(false)
    else
        SetTextRightJustify(false)
        SetTextCentre(true)
    end

    if (options.outline ~= false) then
        SetTextOutline()
    end

    AddTextComponentString(text)
    DrawText(length, height)
end

return Functions.drawText