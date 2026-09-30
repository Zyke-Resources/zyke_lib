-- World-anchored markers: a ring on every point that expands into a key prompt while active
-- Everything is drawn natively on the point every frame like ox_target, so markers never trail the
-- camera; idle rings are a sprite and an active marker is a DUI texture that runs the morph

---@class InterestPoint
---@field id string @ Unique within its set and stable, so the marker keeps animating across updates
---@field entity? integer @ Entity the point follows
---@field offset? vector3 @ Entity-local point, defaults to the entity origin
---@field coords? vector3 @ World point when there is no entity
---@field key? string @ Key label shown while active, or a "+" prefixed command resolved to its bound key
---@field label? string @ Text beside the key while active
---@field hint? string @ Smaller line under the label while active, such as what the action needs first
---@field active? boolean @ Expands the ring into the key prompt; aim sets decide this themselves
---@field opacity? number @ 0-1, defaults to 1
---@field reach? number @ Metres from the player an aim set's point can be aimed at, any distance when omitted
---@field visualId? string @ resource:set:id, built once when the set is replaced
---@field resolved? vector3 | false @ This frame's world position

---@class InterestPointOptions
---@field aim? boolean @ The marker nearest the screen centre is aimed at and shown active, read through getAimedInterestPoint
---@field aimRadius? number @ 1080p pixels from the screen centre a marker can be and still count as aimed at

---@class InterestPointSet
---@field points InterestPoint[]
---@field aim boolean
---@field aimRadius number
---@field aimed? string @ Id of the point aimed at on the last frame

---@class InterestPointVisual
---@field coords? vector3 @ Last known world position, kept while fading out
---@field seenFrame integer
---@field alpha number @ 0-1 fade in and out
---@field present boolean
---@field active boolean
---@field opacity number
---@field key? string
---@field label? string
---@field hint? string

---@class InterestPointSlot
---@field index integer
---@field dui ZykeDuiInstance
---@field ready boolean
---@field createdAt integer
---@field pointId? string @ Visual the DUI is drawn on, kept through the collapse
---@field expanded boolean
---@field releaseAt? integer @ Game timer the collapse finishes and the ring sprite takes over again
---@field key? string
---@field label? string
---@field hint? string

-- The 1080p design in pixels, scaled with the screen height; the idle ring is the same page cropped
-- to a square, so it matches the collapsed marker exactly
local duiWidth, duiHeight = 512, 64
local duiAnchor = 32
-- The DUI renders at twice its drawn size; a 1:1 texture blurs whenever the point lands between pixels
local duiQuality = 2
local fadeMs = 150
-- The page's 0.18s collapse plus a few frames for the DUI texture to catch up
local collapseMs = 260
-- Two slots let the old marker collapse while the newly aimed one expands
local slotCount = 2
-- A DUI that never reports ready is trusted after this long, so prompts still show
local readyTimeout = 2000
-- SetDrawOrigin is limited to 32 calls per frame
local maxDrawn = 30
local defaultAimRadius = 70
-- Aim is judged at this rate rather than every frame; markers still follow their point every frame
local aimInterval = 50
-- The aimed marker counts as this much closer, so it holds a little past the radius and does not
-- flicker between neighbours
local aimStickiness = 1.3

---@type table<string, table<string, InterestPointSet>> @ [resource][setId]
local sets = {}
---@type table<string, InterestPointVisual>
local visuals = {}
---@type InterestPointSlot[]
local slots = {}
-- Never expands; its texture is shared by every idle ring
---@type InterestPointSlot?
local ringSlot
local running = false
local initialized = false
local layout = {}
local frame = 0
local nextAimAt = 0

---@param key? string
---@return string? resolvedKey
local function resolveKey(key)
    if (type(key) ~= "string" or #key <= 1 or key:byte(1) ~= 43) then return key end

    local keyData = Functions.keys.getKeyDataForCommand(key)

    return keyData and keyData.label or "?"
end

---@param point InterestPoint
---@return vector3? coords
local function resolveCoords(point)
    if (point.entity) then
        if (not DoesEntityExist(point.entity)) then return nil end

        local offset = point.offset or vector3(0.0, 0.0, 0.0)

        return GetOffsetFromEntityInWorldCoords(point.entity, offset.x, offset.y, offset.z)
    end

    return point.coords
end

---@param slot InterestPointSlot
---@param data table
local function sendSlot(slot, data)
    slot.dui:sendMessage({event = "SetInterestPoint", data = data})
end

-- Sprites are sized in screen fractions against the 1080p design scaled to the screen height
local function initialize()
    if (initialized) then return end

    initialized = true

    local screenW, screenH = GetActiveScreenResolution()
    local scale = screenH / 1080
    layout = {
        screenW = screenW,
        screenH = screenH,
        scale = scale,
        ringW = duiHeight * scale / screenW,
        ringH = duiHeight * scale / screenH,
        duiW = duiWidth * scale / screenW,
        duiH = duiHeight * scale / screenH,
        -- Moves the texture so the marker centre, not the texture centre, lands on the point
        duiX = (duiWidth / 2 - duiAnchor) * scale / screenW,
    }

    ---@param index integer
    ---@param width integer @ 1080p pixels
    ---@return InterestPointSlot? slot
    local function createSlot(index, width)
        local dui = Functions.dui:new({
            url = ("https://cfx-nui-%s/nui/interest_point/index.html?slot=%s"):format(ResName, index),
            width = math.floor(width * scale * duiQuality + 0.5),
            height = math.floor(duiHeight * scale * duiQuality + 0.5),
        })
        if (not dui) then return nil end

        return {index = index, dui = dui, ready = false, createdAt = GetGameTimer(), expanded = false}
    end

    ringSlot = createSlot(0, duiHeight)

    for i = 1, slotCount do
        slots[#slots + 1] = createSlot(i, duiWidth)
    end
end

---@param slot InterestPointSlot
---@return boolean ready
local function isSlotReady(slot)
    if (slot.ready) then return true end
    if (GetGameTimer() - slot.createdAt < readyTimeout or not IsDuiAvailable(slot.dui.duiObject)) then return false end

    slot.ready = true

    return true
end

---@param pointId string
---@return InterestPointSlot? slot
local function getPointSlot(pointId)
    for i = 1, #slots do
        if (slots[i].pointId == pointId) then return slots[i] end
    end

    return nil
end

-- A free slot first, else the one whose collapse started longest ago
---@return InterestPointSlot? slot
local function claimSlot()
    local best

    for i = 1, #slots do
        local slot = slots[i]
        if (isSlotReady(slot)) then
            if (not slot.pointId) then return slot end
            if (not slot.expanded and (not best or slot.releaseAt < best.releaseAt)) then best = slot end
        end
    end

    return best
end

-- Judges aim the way the player sees it: the marker nearest the screen centre, where the crosshair
-- is. A 3D ray keeps missing points that sit inside geometry, such as a hub behind the tyre wall
---@param set InterestPointSet
---@param pedCoords vector3
---@return string? aimedId
local function findAimedPoint(set, pedCoords)
    local bestId, bestDist

    for i = 1, #set.points do
        local point = set.points[i]
        local coords = point.resolved

        if (coords and (not point.reach or #(coords - pedCoords) <= point.reach)) then
            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

            if (onScreen) then
                local dist = #(vector2((screenX - 0.5) * layout.screenW, (screenY - 0.5) * layout.screenH)) / layout.scale
                if (point.id == set.aimed) then dist = dist / aimStickiness end

                if (dist <= set.aimRadius and (not bestDist or dist < bestDist)) then bestId, bestDist = point.id, dist end
            end
        end
    end

    return bestId
end

-- Runs every frame, so it allocates nothing for points that are already on screen
---@param now integer
---@param deltaMs number
---@param paused boolean
local function updateVisuals(now, deltaMs, paused)
    frame = frame + 1

    local judgeAim = now >= nextAimAt
    local pedCoords = judgeAim and GetEntityCoords(PlayerPedId())
    if (judgeAim) then nextAimAt = now + aimInterval end

    for _, resourceSets in pairs(sets) do
        for _, set in pairs(resourceSets) do
            local points = set.points

            for i = 1, #points do
                points[i].resolved = resolveCoords(points[i]) or false
            end

            if (set.aim and judgeAim) then set.aimed = not paused and findAimedPoint(set, pedCoords) or nil end

            for i = 1, #points do
                local point = points[i]
                local id = point.visualId
                local visual = visuals[id]
                local coords = point.resolved or nil
                local active = set.aim and point.id == set.aimed or (not set.aim and point.active == true)

                if (not visual) then
                    visual = {alpha = 0.0}
                    visuals[id] = visual
                end

                visual.seenFrame = frame
                visual.coords = coords or visual.coords
                visual.present = coords ~= nil
                visual.active = coords ~= nil and active
                visual.opacity = point.opacity or 1.0
                visual.key, visual.label, visual.hint = point.key, point.label, point.hint
            end
        end
    end

    local step = deltaMs / fadeMs

    for id, visual in pairs(visuals) do
        if (visual.seenFrame ~= frame) then visual.present, visual.active = false, false end

        visual.alpha = visual.present and math.min(visual.alpha + step, 1.0) or math.max(visual.alpha - step, 0.0)
        if (visual.alpha <= 0.0 and not visual.present and not getPointSlot(id)) then visuals[id] = nil end
    end

    for i = 1, #slots do
        local slot = slots[i]
        local visual = slot.pointId and visuals[slot.pointId]

        if (slot.expanded and not (visual and visual.active)) then
            slot.expanded = false
            slot.releaseAt = now + collapseMs
            sendSlot(slot, {active = false})
        elseif (slot.releaseAt and now >= slot.releaseAt) then
            slot.pointId, slot.releaseAt = nil, nil
        end
    end

    for id, visual in pairs(visuals) do
        if (visual.active) then
            local slot = getPointSlot(id)

            if (slot) then
                -- Aimed again mid-collapse, so it grows back from where it is
                if (not slot.expanded or slot.key ~= visual.key or slot.label ~= visual.label or slot.hint ~= visual.hint) then
                    slot.expanded, slot.releaseAt = true, nil
                    slot.key, slot.label, slot.hint = visual.key, visual.label, visual.hint
                    sendSlot(slot, {active = true, key = visual.key or "", label = visual.label or "", hint = visual.hint or ""})
                end
            else
                slot = claimSlot()

                if (slot) then
                    slot.pointId, slot.expanded, slot.releaseAt = id, true, nil
                    slot.key, slot.label, slot.hint = visual.key, visual.label, visual.hint
                    sendSlot(slot, {reset = true, active = true, key = visual.key or "", label = visual.label or "", hint = visual.hint or ""})
                end
            end
        end
    end
end

---@param paused boolean
local function drawVisuals(paused)
    if (paused) then return end

    local drawn = 0
    local ringReady = ringSlot ~= nil and isSlotReady(ringSlot)

    for id, visual in pairs(visuals) do
        if (drawn >= maxDrawn) then break end

        local coords = visual.coords
        if (coords and visual.alpha > 0.0) then
            local slot = getPointSlot(id)
            drawn = drawn + 1

            SetDrawOrigin(coords.x, coords.y, coords.z, 0)

            if (slot) then
                DrawSprite(slot.dui.dictName, slot.dui.txtName, layout.duiX, 0.0, layout.duiW, layout.duiH, 0.0, 255, 255, 255, math.floor(visual.alpha * 255))
            elseif (ringReady) then
                DrawSprite(ringSlot.dui.dictName, ringSlot.dui.txtName, 0.0, 0.0, layout.ringW, layout.ringH, 0.0, 255, 255, 255, math.floor(visual.alpha * visual.opacity * 255))
            end
        end
    end

    ClearDrawOrigin()
end

local function startRendering()
    if (running) then return end

    running = true
    initialize()

    CreateThread(function()
        local last = GetGameTimer()

        while (next(sets) or next(visuals)) do
            local now = GetGameTimer()
            local paused = IsPauseMenuActive()
            updateVisuals(now, now - last, paused)
            drawVisuals(paused)
            last = now

            Wait(0)
        end

        running = false
    end)
end

---@param resourceName string
---@param id string
local function clearSet(resourceName, id)
    local resourceSets = sets[resourceName]
    if (not resourceSets) then return end

    resourceSets[id] = nil
    if (not next(resourceSets)) then sets[resourceName] = nil end
end

-- Replaces the calling resource's set; call again whenever a point is added, removed or changes state
---@param id string @ Set identifier within the calling resource
---@param points InterestPoint[]
---@param options? InterestPointOptions
Functions.setInterestPoints = function(id, points, options)
    local resourceName = GetInvokingResource() or ResName
    local normalized = {}

    for i = 1, #points do
        local point = points[i]
        local entity = type(point.entity) == "number" and point.entity ~= 0 and point.entity or nil
        local coords = type(point.coords) == "vector3" and point.coords or nil

        if (type(point.id) == "string" and (entity or coords)) then
            normalized[#normalized + 1] = {
                id = point.id,
                entity = entity,
                offset = type(point.offset) == "vector3" and point.offset or nil,
                coords = coords,
                key = resolveKey(point.key),
                label = point.label,
                hint = type(point.hint) == "string" and point.hint ~= "" and point.hint or nil,
                active = point.active,
                opacity = tonumber(point.opacity),
                reach = tonumber(point.reach),
                visualId = ("%s:%s:%s"):format(resourceName, id, point.id),
            }
        end
    end

    if (#normalized == 0) then
        clearSet(resourceName, id)

        return
    end

    options = options or {}
    sets[resourceName] = sets[resourceName] or {}

    local previous = sets[resourceName][id]
    sets[resourceName][id] = {
        points = normalized,
        aim = options.aim == true,
        aimRadius = tonumber(options.aimRadius) or defaultAimRadius,
        -- Kept so the stickiness carries over the refresh
        aimed = previous and previous.aimed,
    }

    startRendering()
end

---@param id string @ Set identifier within the calling resource
Functions.clearInterestPoints = function(id)
    clearSet(GetInvokingResource() or ResName, id)
end

-- Shakes a point's expanded prompt, such as when the player can't do its action right now; a ring
-- that is not expanded has nothing to shake
---@param id string @ Set identifier within the calling resource
---@param pointId string
Functions.shakeInterestPoint = function(id, pointId)
    local slot = getPointSlot(("%s:%s:%s"):format(GetInvokingResource() or ResName, id, pointId))
    if (not slot or not slot.expanded) then return end

    sendSlot(slot, {shake = true})
end

-- Aim sets judge the aim every frame; this reads the result of the last one
---@param id string @ Set identifier within the calling resource
---@return string? pointId
Functions.getAimedInterestPoint = function(id)
    local resourceSets = sets[GetInvokingResource() or ResName]
    local set = resourceSets and resourceSets[id]

    return set and set.aimed or nil
end

-- The DUI page reports once it can take messages
---@param passed {event: string, data: {slot: integer}}
---@param cb fun(response: string)
RegisterNUICallback("Eventhandler:InterestPoint", function(passed, cb)
    if (passed.event == "Ready") then
        if (ringSlot and passed.data.slot == ringSlot.index) then ringSlot.ready = true end

        for i = 1, #slots do
            if (slots[i].index == passed.data.slot) then slots[i].ready = true end
        end
    end

    cb("ok")
end)

---@param resourceName string @ Stopping resource name
AddEventHandler("onClientResourceStop", function(resourceName)
    sets[resourceName] = nil
end)