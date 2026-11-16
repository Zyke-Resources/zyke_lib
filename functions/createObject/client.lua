-- Creates objects with the door flag by default, since door archetypes such as safes and vault gates only spawn without
-- it when the server sets game_enableDynamicDoorCreation, which most servers do not. With the flag a door model spawns
-- as a plain object, which the door system can still lock and open but which no longer swings on its own hinge

---@param model string | integer
---@param coords vector3 | vector4 @ A vector4's w is the heading when heading is nil
---@param heading? number
---@param isNetworked? boolean
---@param asDoor? boolean @ Spawns door models as real doors that swing on their hinge; needs game_enableDynamicDoorCreation, without it the game refuses them and this returns nil
---@return integer? object @ Nil when the model is invalid or the game refused to create it
function Functions.createObject(model, coords, heading, isNetworked, asDoor)
    local hash = type(model) == "string" and joaat(model) or model
    if (not Functions.loadModel(hash, true, 5000)) then
        print(("^3[WARNING] [%s] Could not load model %s for an object^7"):format(ResName, model))

        return nil
    end

    local object = CreateObjectNoOffset(hash, coords.x, coords.y, coords.z, isNetworked == true, isNetworked == true, asDoor ~= true)

    SetModelAsNoLongerNeeded(hash)

    if (object == 0) then
        print(("^3[WARNING] [%s] The game refused to create an object of model %s^7"):format(ResName, model))

        return nil
    end

    if (not heading and type(coords) == "vector4") then heading = coords.w end
    if (heading) then SetEntityHeading(object, heading + 0.0) end

    return object
end

return Functions.createObject