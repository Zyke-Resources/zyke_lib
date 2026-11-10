Functions.appearance = {}

---@class AppearancePiece
---@field id integer @ Component id (0-11) in components, prop anchor id (0-7) in props
---@field drawable integer @ Index inside collection when one is given, else the global drawable; -1 takes a prop off
---@field texture? integer
---@field collection? string @ Clothing collection such as "mp_m_zyke_dden", whose indexes stay the same whatever other clothing packs the server streams

---@class AppearanceOutfit
---@field components? AppearancePiece[]
---@field props? AppearancePiece[]

---@param ped integer
---@param piece AppearancePiece
---@param isProp boolean
---@return boolean streamed @ The piece's collection has its drawable on this ped model
local function isPieceStreamed(ped, piece, isProp)
    if (not piece.collection or piece.drawable < 0) then return true end

    local count = isProp
        and GetNumberOfPedCollectionPropDrawableVariations(ped, piece.id, piece.collection)
        or GetNumberOfPedCollectionDrawableVariations(ped, piece.id, piece.collection)

    return piece.drawable < count
end

-- Puts clothes on the player without saving them, the appearance resource keeps the saved look for restore
---@param outfit AppearanceOutfit
---@return boolean worn @ False when a collection piece is not streamed for the player's ped, nothing changes then
function Functions.appearance.wearOutfit(outfit)
    local ped = PlayerPedId()
    local components = outfit.components or {}
    local props = outfit.props or {}

    for i = 1, #components do
        if (not isPieceStreamed(ped, components[i], false)) then return false end
    end

    for i = 1, #props do
        if (not isPieceStreamed(ped, props[i], true)) then return false end
    end

    for i = 1, #components do
        local piece = components[i]

        if (piece.collection) then
            SetPedCollectionComponentVariation(ped, piece.id, piece.collection, piece.drawable, piece.texture or 0, 0)
        else
            SetPedComponentVariation(ped, piece.id, piece.drawable, piece.texture or 0, 0)
        end
    end

    for i = 1, #props do
        local piece = props[i]

        if (piece.drawable < 0) then
            ClearPedProp(ped, piece.id)
        elseif (piece.collection) then
            SetPedCollectionPropIndex(ped, piece.id, piece.collection, piece.drawable, piece.texture or 0, true)
        else
            SetPedPropIndex(ped, piece.id, piece.drawable, piece.texture or 0, true)
        end
    end

    return true
end

-- Puts the player's saved look back on from the appearance resource that keeps it
---@return boolean restored @ False when no appearance resource was found to restore from
function Functions.appearance.restore()
    if (AppearanceSystem == "illenium-appearance") then
        -- true skips its reload cooldown; it still refuses while the player is dead, cuffed, falling or in a vehicle
        TriggerEvent("illenium-appearance:client:reloadSkin", true)

        return true
    end

    if (AppearanceSystem == "rcore_clothing") then
        TriggerServerEvent("rcore_clothing:reloadSkin")

        return true
    end

    if (AppearanceSystem == "onex-creation") then
        TriggerEvent("onex-creation:client:syncClothes")

        return true
    end

    if (AppearanceSystem == "qb-clothing") then
        TriggerServerEvent("qb-clothes:loadPlayerSkin")

        return true
    end

    if (AppearanceSystem == "esx_skin" and Framework == "ESX") then
        ESX.TriggerServerCallback("esx_skin:getPlayerSkin", function(skin)
            TriggerEvent("skinchanger:loadSkin", skin)
        end)

        return true
    end

    return false
end

-- Opens the appearance resource's menu of the player's saved outfits, such as a wardrobe in a
-- house or a hotel room uses
---@return boolean opened @ False when the appearance resource has no outfit menu to open
function Functions.appearance.openWardrobe()
    -- onex-creation provides illenium-appearance and answers its events
    if (AppearanceSystem == "illenium-appearance" or AppearanceSystem == "onex-creation") then
        TriggerEvent("illenium-appearance:client:openOutfitMenu")

        return true
    end
    
    if (AppearanceSystem == "rcore_clothing") then
        TriggerEvent('rcore_clothing:openChangingRoom')

        return true
    end

    if (AppearanceSystem == "qb-clothing") then
        TriggerEvent("qb-clothing:client:openOutfitMenu")

        return true
    end

    return false
end

return Functions.appearance
