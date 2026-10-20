-- World-anchored markers: a ring on every point that expands into a key prompt while active
-- Everything is drawn natively on the point every frame like ox_target, so markers never trail the
-- camera; idle rings are a sprite and an active marker is a DUI texture that runs the morph
-- A point with options expands into a timeline instead: the mouse wheel moves the selection along it
-- and the key acts on the selected option. A single option shows as a plain prompt, so a point can
-- keep the same option ids while its choices come and go
-- Only following and drawing the markers runs every frame. Rooms, aim, the camera's view and the prompts
-- are judged on the aim interval, and the loop sleeps between judgements while nothing is on screen

---@class InterestPointOption
---@field id string @ Stable within its point, so the selection holds across updates
---@field label string
---@field hint? string @ Smaller line under the label while this option is selected

---@class InterestPoint
---@field id string @ Unique within its set and stable, so the marker keeps animating across updates
---@field entity? integer @ Entity the point follows
---@field offset? vector3 @ Entity-local point, defaults to the entity origin
---@field coords? vector3 @ World point when there is no entity
---@field key? string @ Key label shown while active, or a "+" prefixed command resolved to its bound key when the prompt shows
---@field label? string @ Text beside the key while active
---@field hint? string @ Smaller line under the label while active, such as what the action needs first
---@field options? InterestPointOption[] @ Replaces the label and hint with a scrollable timeline, read through getInterestPointOption
---@field optionsKey? string @ Built once when the set is replaced
---@field active? boolean @ Expands the ring into the key prompt; aim sets decide this themselves
---@field opacity? number @ 0-1, defaults to 1
---@field reach? number @ Metres from the player an aim set's point can be aimed at, any distance when omitted
---@field visualId? string @ resource:set:id, built once when the set is replaced
---@field resolved? vector3 | false @ World position at the last judgement, false while it is in another room
---@field culled? boolean @ Outside the camera's view at the last judgement, so it can't be aimed at

---@class InterestPointOptions
---@field aim? boolean @ The marker nearest the screen centre is aimed at and shown active, read through getAimedInterestPoint
---@field aimRadius? number @ 1080p pixels from the screen centre a marker can be and still count as aimed at
---@field ignoreRooms? boolean @ Points show and can be aimed at from another room, and from outside their interior

---@class InterestPointSet
---@field points InterestPoint[]
---@field aim boolean
---@field rooms boolean @ Points only show to a player in their room
---@field aimRadius number
---@field aimed? string @ Id of the point aimed at on the last frame

---@class InterestPointRoom
---@field index integer
---@field min vector3 @ In interior space
---@field max vector3
---@field volume number

---@class InterestPointInterior
---@field origin vector3
---@field axisX vector3 @ World direction of the interior's own axes
---@field axisY vector3
---@field axisZ vector3
---@field bounds InterestPointRoom @ The limbo room, which spans the interior
---@field rooms InterestPointRoom[] @ Smallest first

---@class InterestPointVisual
---@field point? InterestPoint @ Nil once the point left its set
---@field coords? vector3 @ Last known world position, kept while fading out
---@field resolvedFrame? integer @ Frame the coords were last read on
---@field seenTick integer
---@field alpha number @ 0-1 fade in and out
---@field present boolean
---@field active boolean
---@field culled? boolean @ Outside the view at the last judgement, so it is neither followed nor drawn
---@field roomAt? vector3 @ Where the point's own room was last read
---@field roomCheckAt? integer @ Game timer the room is read again even if the point stood still
---@field roomInterior? integer
---@field roomIndex? integer
---@field opacity number
---@field key? string
---@field label? string
---@field hint? string
---@field options? InterestPointOption[]
---@field optionsKey? string
---@field selected? string @ Id of the selected option
---@field selectedIndex? integer

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
---@field optionsKey? string
---@field selectedIndex? integer

-- The 1080p design in pixels, scaled with the screen height; the idle ring is the same page cropped
-- to a square, so it matches the collapsed marker exactly
local duiWidth, duiHeight = 512, 64
local duiAnchor = 32
-- Expanded slots are taller than the ring so an option timeline fits above and below the marker,
-- fading out three rows away
local expandedHeight = 256
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
-- A point's own room is read again once it moved this many metres, or after one to two of these intervals
-- in case its interior finished loading. GetInteriorAtCoords costs more than everything else a point takes
local roomMoveTolerance = 0.5
local roomRecheckMs = 1000
-- Degrees past the corners of the screen a point still counts as in view. A point outside is skipped
-- until the next judgement, so it only shows late when the camera turns faster than this per aim interval
local viewMargin = 25
-- Metres from the camera within which a point always counts as in view
local viewMinDistance = 2.0
local zeroOffset = vector3(0.0, 0.0, 0.0)
-- How often the screen resolution is checked for a settings change
local layoutInterval = 3000
-- The guide dot shows once a marker is within this many aim radii of the screen centre
local guideRadiusScale = 3
-- Metres past a point's reach the guide dot still shows, so the player is guided before they are in range
local guideReachMargin = 1.5
-- 1080p pixels, drawn from a texture generated at this many pixels per side
local guideSize = 7
local guideTextureSize = 32
local guideTxd, guideTxn = "zyke_lib_interest_point_guide", "dot"
-- The mouse wheel's weapon wheel next and previous; the weapon select controls are held off too, so
-- scrolling an option never swaps weapons
local scrollNextControl, scrollPrevControl = 14, 15
local scrollControls = {14, 15, 16, 17, 261, 262}
local targetingCommand = "zyke_lib_interest_point_targeting"

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
-- Counts judgements; a visual not seen on the latest one has left its set
local tick = 0
local nextAimAt = 0
-- A set was cleared, so its markers go on the next frame rather than at the interval
local setsChanged = false
-- An expanded marker has options, so the mouse wheel is read every frame
local scrollable = false
-- The camera at the last judgement
local viewCoords, viewForward, viewCos = zeroOffset, zeroOffset, -1.0
local nextLayoutAt = 0
local guideEnabled = LibConfig.interestPointGuide == true
local guideReady = false
local guideVisible = false
-- The guide only helps find a point, so it steps aside once any aim set's prompt is shown
local guideAimed = false
local guideAlpha = 0.0
-- Like a target system: nothing shows and nothing can be aimed at until the targeting key is held
local targetingEnabled = LibConfig.interestPointTargeting == true
local wasTargeting = not targetingEnabled
local roomCheckEnabled = LibConfig.interestPointRoomCheck ~= false
---@type table<integer, InterestPointInterior> @ [interiorId], an interior's rooms never change
local interiors = {}
-- The player's interior and room index at the last aim judgement, no room while it is unknown
local plyInterior = 0
---@type integer?
local plyRoom
-- Where the rooms' boxes put the player while the game keeps them outside. A rooftop or a yard can lie inside a
-- building's bounds, and the points around the player there are read from the same boxes
local plyBoxInterior = 0
---@type integer?
local plyBoxRoom
---@type vector3?
local plyBoxAt
local plyBoxCheckAt = 0

-- Only called when a prompt is sent: reading a command's binding costs more than the rest of a set's refresh
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

        local offset = point.offset or zeroOffset

        return GetOffsetFromEntityInWorldCoords(point.entity, offset.x, offset.y, offset.z)
    end

    return point.coords
end

---@param interiorId integer
---@param roomIndex integer
---@return InterestPointRoom room
local function readRoom(interiorId, roomIndex)
    local minX, minY, minZ, maxX, maxY, maxZ = GetInteriorRoomExtents(interiorId, roomIndex)

    return {
        index = roomIndex,
        min = vector3(minX, minY, minZ),
        max = vector3(maxX, maxY, maxZ),
        volume = (maxX - minX) * (maxY - minY) * (maxZ - minZ),
    }
end

---@param interiorId integer
---@return InterestPointInterior? interior @ Nil until the interior has loaded
local function getInterior(interiorId)
    local interior = interiors[interiorId]
    if (interior) then return interior end
    if (not IsInteriorReady(interiorId)) then return nil end

    local origin = GetOffsetFromInteriorInWorldCoords(interiorId, 0.0, 0.0, 0.0)
    local rooms = {}

    -- Room 0 is limbo
    for i = 1, GetInteriorRoomCount(interiorId) - 1 do
        rooms[#rooms + 1] = readRoom(interiorId, i)
    end

    table.sort(rooms, function(a, b)
        return a.volume < b.volume
    end)

    interior = {
        origin = origin,
        axisX = GetOffsetFromInteriorInWorldCoords(interiorId, 1.0, 0.0, 0.0) - origin,
        axisY = GetOffsetFromInteriorInWorldCoords(interiorId, 0.0, 1.0, 0.0) - origin,
        axisZ = GetOffsetFromInteriorInWorldCoords(interiorId, 0.0, 0.0, 1.0) - origin,
        bounds = readRoom(interiorId, 0),
        rooms = rooms,
    }
    interiors[interiorId] = interior

    return interior
end

---@param room InterestPointRoom
---@param x number @ In interior space
---@param y number
---@param z number
---@return boolean inside
local function isInRoom(room, x, y, z)
    local min, max = room.min, room.max

    return x >= min.x and x <= max.x and y >= min.y and y <= max.y and z >= min.z and z <= max.z
end

-- There is no native for the room at a position, so it is read from the rooms' boxes. A box is as wide as its
-- room's furthest corners, so the box of an L-shaped room also covers the rooms in its corner: the smallest box
-- the point is in is taken as its room
---@param coords vector3
---@return integer interiorId @ 0 when outside
---@return integer? roomIndex @ Nil when the room is unknown
local function getRoomAtCoords(coords)
    local interiorId = GetInteriorAtCoords(coords.x, coords.y, coords.z)
    if (interiorId == 0) then return 0, nil end

    local interior = getInterior(interiorId)
    if (not interior) then return interiorId, nil end

    local offset = coords - interior.origin
    local x, y, z = dot(offset, interior.axisX), dot(offset, interior.axisY), dot(offset, interior.axisZ)

    for i = 1, #interior.rooms do
        if (isInRoom(interior.rooms[i], x, y, z)) then return interiorId, interior.rooms[i].index end
    end

    -- GetInteriorAtCoords also answers for a point just outside the walls
    if (not isInRoom(interior.bounds, x, y, z)) then return 0, nil end

    return interiorId, nil
end

-- A point on an entity is in the room the game keeps the entity in. The boxes put a prop on a counter or by a doorway
-- in the neighbouring room whenever that room's box is the smaller one. An entity in no interior is read from the boxes
---@param point InterestPoint
---@param coords vector3
---@return integer interiorId @ 0 when outside
---@return integer? roomIndex @ Nil when the room is unknown
local function getPointRoom(point, coords)
    local interiorId = point.entity and GetInteriorFromEntity(point.entity) or 0
    if (interiorId == 0) then return getRoomAtCoords(coords) end

    local roomIndex = GetInteriorRoomIndexByHash(interiorId, GetRoomKeyFromEntity(point.entity))

    return interiorId, roomIndex > 0 and roomIndex or nil
end

-- Cheaper than a ray per point every frame, at the cost of still showing a point behind a wall inside the same room.
-- The point's own room is kept on its visual until the point moves, as it does not depend on where the player is
---@param visual InterestPointVisual
---@param point InterestPoint
---@param coords vector3
---@param now integer
---@return boolean visible
local function isInPlayerRoom(visual, point, coords, now)
    if (not visual.roomAt or now >= visual.roomCheckAt or #(coords - visual.roomAt) > roomMoveTolerance) then
        visual.roomInterior, visual.roomIndex = getPointRoom(point, coords)
        -- Spread out, so points added together do not all read their rooms on the same frame
        visual.roomAt, visual.roomCheckAt = coords, now + math.random(roomRecheckMs, roomRecheckMs * 2)
    end

    if (visual.roomInterior == plyInterior) then return not visual.roomIndex or not plyRoom or visual.roomIndex == plyRoom end
    if (plyInterior ~= 0 or visual.roomInterior ~= plyBoxInterior) then return false end

    return not visual.roomIndex or not plyBoxRoom or visual.roomIndex == plyBoxRoom
end

---@param ped integer
---@param now integer
local function refreshPlayerRoom(ped, now)
    plyInterior = GetInteriorFromEntity(ped)

    local roomIndex = plyInterior ~= 0 and GetInteriorRoomIndexByHash(plyInterior, GetRoomKeyFromEntity(ped)) or 0
    plyRoom = roomIndex > 0 and roomIndex or nil

    if (plyInterior ~= 0) then
        plyBoxInterior, plyBoxRoom, plyBoxAt = 0, nil, nil

        return
    end

    local coords = GetEntityCoords(ped)
    if (plyBoxAt and now < plyBoxCheckAt and #(coords - plyBoxAt) <= roomMoveTolerance) then return end

    plyBoxInterior, plyBoxRoom = getRoomAtCoords(coords)
    plyBoxAt, plyBoxCheckAt = coords, now + roomRecheckMs
end

---@param slot InterestPointSlot
---@param data table
local function sendSlot(slot, data)
    slot.dui:sendMessage({event = "SetInterestPoint", data = data})
end

-- Sprites are sized in screen fractions against the 1080p design scaled to the screen height, so they
-- are rebuilt whenever the resolution or aspect ratio changes in the settings
---@param now integer
local function refreshLayout(now)
    if (now < nextLayoutAt) then return end

    nextLayoutAt = now + layoutInterval

    local screenW, screenH = GetActiveScreenResolution()
    if (screenW == layout.screenW and screenH == layout.screenH) then return end

    local scale = screenH / 1080
    layout = {
        screenW = screenW,
        screenH = screenH,
        scale = scale,
        ringW = duiHeight * scale / screenW,
        ringH = duiHeight * scale / screenH,
        duiW = duiWidth * scale / screenW,
        duiH = expandedHeight * scale / screenH,
        -- Moves the texture so the marker centre, not the texture centre, lands on the point
        duiX = (duiWidth / 2 - duiAnchor) * scale / screenW,
        guideW = guideSize * scale / screenW,
        guideH = guideSize * scale / screenH,
    }
end

-- The view is a cone from the camera out to the screen's corners plus the margin
local function refreshView()
    local rotation = GetFinalRenderedCamRot(2)
    local pitch, yaw = math.rad(rotation.x), math.rad(rotation.z)
    local flat = math.abs(math.cos(pitch))
    local aspect = layout.screenW / layout.screenH
    local corner = math.deg(math.atan(math.tan(math.rad(GetFinalRenderedCamFov() / 2)) * math.sqrt(1 + aspect * aspect)))

    viewCoords = GetFinalRenderedCamCoord()
    viewForward = vector3(-math.sin(yaw) * flat, math.cos(yaw) * flat, math.sin(pitch))
    viewCos = math.cos(math.rad(math.min(corner + viewMargin, 180)))
end

---@param coords vector3
---@return boolean outside
local function isOutsideView(coords)
    local offset = coords - viewCoords
    local distance = #offset
    if (distance <= viewMinDistance) then return false end

    return dot(offset, viewForward) < distance * viewCos
end

-- Generated rather than shipped as an image: a white dot with a soft dark rim, so it stays visible
-- on bright backgrounds and on top of an expanded prompt
local function createGuideTexture()
    local texture = CreateRuntimeTexture(CreateRuntimeTxd(guideTxd), guideTxn, guideTextureSize, guideTextureSize)
    local centre = (guideTextureSize - 1) / 2
    local outerRadius = guideTextureSize / 2 - 0.5
    local innerRadius = outerRadius * 0.7

    for x = 0, guideTextureSize - 1 do
        for y = 0, guideTextureSize - 1 do
            local dist = #(vector2(x - centre, y - centre))
            local inner = math.min(math.max(innerRadius - dist + 0.5, 0.0), 1.0)
            local outer = math.min(math.max(outerRadius - dist + 0.5, 0.0), 1.0)
            local alpha = inner + (1.0 - inner) * outer * 0.5
            local colour = alpha > 0.0 and math.floor(255 * inner / alpha + 0.5) or 0

            SetRuntimeTexturePixel(texture, x, y, colour, colour, colour, math.floor(alpha * 255 + 0.5))
        end
    end

    CommitRuntimeTexture(texture)
    guideReady = true
end

-- The DUI pages scale with their own viewport, so their textures are sized once at the first
-- resolution and only the drawn sprite follows later changes
local function initialize()
    if (initialized) then return end

    initialized = true
    refreshLayout(GetGameTimer())

    local scale = layout.scale

    ---@param index integer
    ---@param width integer @ 1080p pixels
    ---@param height integer @ 1080p pixels
    ---@return InterestPointSlot? slot
    local function createSlot(index, width, height)
        local dui = Functions.dui:new({
            url = ("https://cfx-nui-%s/nui/interest_point/index.html?slot=%s&height=%s"):format(ResName, index, height),
            width = math.floor(width * scale * duiQuality + 0.5),
            height = math.floor(height * scale * duiQuality + 0.5),
        })
        if (not dui) then return nil end

        return {index = index, dui = dui, ready = false, createdAt = GetGameTimer(), expanded = false}
    end

    ringSlot = createSlot(0, duiHeight, duiHeight)

    for i = 1, slotCount do
        slots[#slots + 1] = createSlot(i, duiWidth, expandedHeight)
    end

    if (guideEnabled) then createGuideTexture() end
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
---@return boolean guided @ A marker is close enough to the screen centre to show the guide dot
local function findAimedPoint(set, pedCoords)
    local bestId, bestDist
    local guided = false

    for i = 1, #set.points do
        local point = set.points[i]
        local coords = point.resolved

        local pedDist = coords and point.reach and #(coords - pedCoords)
        local inReach = not pedDist or pedDist <= point.reach

        if (coords and not point.culled and (inReach or pedDist <= point.reach + guideReachMargin)) then
            local onScreen, screenX, screenY = GetScreenCoordFromWorldCoord(coords.x, coords.y, coords.z)

            if (onScreen) then
                local dist = #(vector2((screenX - 0.5) * layout.screenW, (screenY - 0.5) * layout.screenH)) / layout.scale
                if (point.id == set.aimed) then dist = dist / aimStickiness end
                if (dist <= set.aimRadius * guideRadiusScale) then guided = true end

                if (inReach and dist <= set.aimRadius and (not bestDist or dist < bestDist)) then bestId, bestDist = point.id, dist end
            end
        end
    end

    return bestId, guided
end

-- Keeps the selection on the same option across updates, or on the same row when that option is gone
---@param visual InterestPointVisual
local function syncSelection(visual)
    local options = visual.options

    if (not options) then
        visual.selected, visual.selectedIndex = nil, nil

        return
    end

    for i = 1, #options do
        if (options[i].id == visual.selected) then
            visual.selectedIndex = i

            return
        end
    end

    local index = math.min(visual.selectedIndex or 1, #options)
    visual.selected, visual.selectedIndex = options[index].id, index
end

-- Moves the selection of every expanded marker with options; the timeline ends rather than wraps
---@param paused boolean
---@return boolean moved
local function scrollOptions(paused)
    if (paused) then return false end

    local step
    local moved = false

    for _, visual in pairs(visuals) do
        local options = visual.active and visual.options

        if (options and #options > 1) then
            if (not step) then
                for i = 1, #scrollControls do
                    DisableControlAction(0, scrollControls[i], true)
                end

                step = (IsDisabledControlJustPressed(0, scrollNextControl) and 1 or 0) - (IsDisabledControlJustPressed(0, scrollPrevControl) and 1 or 0)
            end

            local index = math.max(1, math.min(visual.selectedIndex + step, #options))

            if (index ~= visual.selectedIndex) then
                visual.selected, visual.selectedIndex = options[index].id, index
                moved = true
            end
        end
    end

    if (moved) then PlaySoundFrontend(-1, "NAV_UP_DOWN", "HUD_FRONTEND_DEFAULT_SOUNDSET", true) end

    return moved
end

-- Copies the visual's prompt onto its slot and expands it; the options only go over when they changed
---@param slot InterestPointSlot
---@param visual InterestPointVisual
---@param reset boolean @ The slot was showing another point
local function sendPrompt(slot, visual, reset)
    local data = {reset = reset, active = true, key = resolveKey(visual.key) or "", label = visual.label or "", hint = visual.hint or "", selected = visual.selectedIndex}
    if (reset or slot.optionsKey ~= visual.optionsKey) then data.options = visual.options and #visual.options > 1 and visual.options or false end

    slot.expanded, slot.releaseAt = true, nil
    slot.key, slot.label, slot.hint = visual.key, visual.label, visual.hint
    slot.optionsKey, slot.selectedIndex = visual.optionsKey, visual.selectedIndex
    sendSlot(slot, data)
end

-- Collapses the slots whose point stopped being active and keeps every active point's prompt on a slot
---@param now integer
local function syncSlots(now)
    for i = 1, #slots do
        local slot = slots[i]
        local visual = slot.pointId and visuals[slot.pointId]

        if (slot.expanded and not (visual and visual.active)) then
            slot.expanded = false
            slot.releaseAt = now + collapseMs

            sendSlot(slot, {active = false})
        end
    end

    for id, visual in pairs(visuals) do
        if (visual.active) then
            local slot = getPointSlot(id)

            if (slot) then
                -- Aimed again mid-collapse, so it grows back from where it is
                if (not slot.expanded or slot.key ~= visual.key or slot.label ~= visual.label or slot.hint ~= visual.hint or slot.optionsKey ~= visual.optionsKey or slot.selectedIndex ~= visual.selectedIndex) then
                    sendPrompt(slot, visual, false)
                end
            else
                slot = claimSlot()

                if (slot) then
                    slot.pointId = id

                    sendPrompt(slot, visual, true)
                end
            end
        end
    end
end

-- A collapsed slot hands its point back to the ring sprite
---@param now integer
local function releaseSlots(now)
    for i = 1, #slots do
        local slot = slots[i]
        if (slot.releaseAt and now >= slot.releaseAt) then slot.pointId, slot.releaseAt = nil, nil end
    end
end

-- Everything but following and drawing the markers: rooms, the camera's view, aim, the prompts and the slots
---@param now integer
---@param paused boolean
---@param targeting boolean
local function judge(now, paused, targeting)
    tick = tick + 1
    nextAimAt = now + aimInterval
    setsChanged, scrollable = false, false
    guideVisible, guideAimed = false, false

    local ped = PlayerPedId()
    local pedCoords = GetEntityCoords(ped)

    refreshPlayerRoom(ped, now)
    refreshView()

    for _, resourceSets in pairs(sets) do
        for _, set in pairs(resourceSets) do
            local points = set.points

            for i = 1, #points do
                local point = points[i]
                local visual = visuals[point.visualId]

                if (not visual) then
                    visual = {alpha = 0.0}
                    visuals[point.visualId] = visual
                end

                -- Nothing shows while the targeting key is up, so there is nothing to read
                local coords = targeting and resolveCoords(point) or nil
                if (coords and set.rooms and not isInPlayerRoom(visual, point, coords, now)) then coords = nil end

                point.resolved = coords or false
                point.culled = coords ~= nil and isOutsideView(coords)
            end

            if (set.aim) then
                local aimed, guided = nil, false
                if (not paused and targeting) then aimed, guided = findAimedPoint(set, pedCoords) end

                set.aimed = aimed
                guideVisible = guideVisible or guided
                guideAimed = guideAimed or aimed ~= nil
            end

            for i = 1, #points do
                local point = points[i]
                local visual = visuals[point.visualId]
                local coords = point.resolved or nil
                local active = set.aim and point.id == set.aimed or (not set.aim and point.active == true)

                visual.point, visual.seenTick = point, tick
                visual.present, visual.culled = coords ~= nil, point.culled
                visual.active = visual.present and active
                visual.opacity = point.opacity or 1.0
                visual.key, visual.label, visual.hint = point.key, point.label, point.hint
                visual.options, visual.optionsKey = point.options, point.optionsKey

                if (coords) then visual.coords, visual.resolvedFrame = coords, frame end

                -- Looking away starts the timeline over at the first option
                if (not visual.active) then visual.selected, visual.selectedIndex = nil, nil end

                syncSelection(visual)

                if (visual.active and visual.options and #visual.options > 1) then scrollable = true end
            end
        end
    end

    for id, visual in pairs(visuals) do
        if (visual.seenTick ~= tick) then visual.point, visual.present, visual.active = nil, false, false end

        if (not visual.point and visual.alpha <= 0.0 and not getPointSlot(id)) then
            visuals[id] = nil
        elseif (not visual.present) then
            -- Fading out where it was last seen
            visual.culled = visual.alpha > 0.0 and visual.coords ~= nil and isOutsideView(visual.coords)
        end
    end

    syncSlots(now)
end

-- Follows, fades and draws the markers. Runs every frame, so it allocates nothing
---@param deltaMs number
---@param paused boolean
---@return boolean busy @ Something is on screen or the mouse wheel is read, so the next frame is needed
local function renderVisuals(deltaMs, paused)
    local step = deltaMs / fadeMs
    local ringReady = ringSlot ~= nil and isSlotReady(ringSlot)
    local drawn = 0
    local busy = scrollable

    for id, visual in pairs(visuals) do
        if (visual.culled) then
            -- Not drawn before the next judgement, so there is no fade to show
            visual.alpha = visual.present and 1.0 or 0.0
        elseif (visual.present or visual.alpha > 0.0) then
            local point = visual.point
            busy = true

            if (point and visual.resolvedFrame ~= frame) then
                local coords = resolveCoords(point)

                if (coords) then
                    visual.coords = coords
                else
                    visual.present, visual.active = false, false
                end
            end

            local alpha = visual.present and math.min(visual.alpha + step, 1.0) or math.max(visual.alpha - step, 0.0)
            local coords = visual.coords
            visual.alpha = alpha

            if (not paused and coords and alpha > 0.0 and drawn < maxDrawn) then
                local slot = getPointSlot(id)
                drawn = drawn + 1

                SetDrawOrigin(coords.x, coords.y, coords.z, 0)

                if (slot) then
                    DrawSprite(slot.dui.dictName, slot.dui.txtName, layout.duiX, 0.0, layout.duiW, layout.duiH, 0.0, 255, 255, 255, math.floor(alpha * 255))
                elseif (ringReady) then
                    DrawSprite(ringSlot.dui.dictName, ringSlot.dui.txtName, 0.0, 0.0, layout.ringW, layout.ringH, 0.0, 255, 255, 255, math.floor(alpha * visual.opacity * 255))
                end
            end
        end
    end

    if (drawn > 0) then ClearDrawOrigin() end

    guideAlpha = guideVisible and not guideAimed and math.min(guideAlpha + step, 1.0) or math.max(guideAlpha - step, 0.0)

    if (guideReady and guideAlpha > 0.0) then
        busy = true

        if (not paused) then DrawSprite(guideTxd, guideTxn, 0.5, 0.5, layout.guideW, layout.guideH, 0.0, 255, 255, 255, math.floor(guideAlpha * 255)) end
    end

    return busy and not paused
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
            local targeting = not targetingEnabled or HoldingKeys[targetingCommand] == true
            frame = frame + 1

            refreshLayout(now)
            releaseSlots(now)

            -- Judged right away when a set is cleared or the targeting key changes, so neither lags behind the
            -- interval. A replaced set waits for it, as the consumers send theirs again several times a second
            if (setsChanged or now >= nextAimAt or targeting ~= wasTargeting) then judge(now, paused, targeting) end

            wasTargeting = targeting

            if (scrollable and scrollOptions(paused)) then syncSlots(now) end

            local busy = renderVisuals(now - last, paused)
            last = now

            if (busy) then
                Wait(0)
            elseif (not targeting) then
                -- Pressing the targeting key starts rendering again
                break
            else
                Wait(math.max(nextAimAt - now, 0))

                -- Nothing faded while asleep, so the first frame back starts from where it was
                last = GetGameTimer()
            end
        end

        running = false
    end)
end

---@param options any
---@return InterestPointOption[]? options
---@return string? optionsKey @ Changes whenever an option does, so the DUI only gets them again then
local function normalizeOptions(options)
    if (type(options) ~= "table") then return nil, nil end

    local normalized = {}
    local parts = {}

    for i = 1, #options do
        local option = options[i]

        if (type(option) == "table" and type(option.id) == "string") then
            local label = tostring(option.label or "")
            local hint = type(option.hint) == "string" and option.hint ~= "" and option.hint or nil

            normalized[#normalized + 1] = {id = option.id, label = label, hint = hint}
            parts[#parts + 1] = ("%s\0%s\0%s"):format(option.id, label, hint or "")
        end
    end

    if (#normalized == 0) then return nil, nil end

    return normalized, table.concat(parts, "\1")
end

---@param resourceName string
---@param id string
---@param pointId string
---@return string? optionId
local function getSelectedOption(resourceName, id, pointId)
    local visual = visuals[("%s:%s:%s"):format(resourceName, id, pointId)]

    return visual and visual.selected or nil
end

---@param resourceName string
---@param id string
local function clearSet(resourceName, id)
    local resourceSets = sets[resourceName]
    if (not resourceSets) then return end

    resourceSets[id] = nil
    if (not next(resourceSets)) then sets[resourceName] = nil end

    setsChanged = true
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
            local pointOptions, optionsKey = normalizeOptions(point.options)
            local single = pointOptions and #pointOptions == 1 and pointOptions[1]
            local hint = single and single.hint or point.hint

            normalized[#normalized + 1] = {
                id = point.id,
                entity = entity,
                offset = type(point.offset) == "vector3" and point.offset or nil,
                coords = coords,
                key = point.key,
                label = single and single.label or point.label,
                hint = type(hint) == "string" and hint ~= "" and hint or nil,
                options = pointOptions,
                optionsKey = optionsKey,
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
        rooms = roomCheckEnabled and options.ignoreRooms ~= true,
        -- Kept so the stickiness carries over the refresh
        aimed = previous and previous.aimed,
    }

    -- The DUIs load now, so the markers are ready by the time the targeting key is pressed
    initialize()

    -- With targeting, rendering only runs while the key is held, and the press starts it
    if (not targetingEnabled or HoldingKeys[targetingCommand] == true) then startRendering() end
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

-- Aim sets judge the aim on the aim interval; this reads the result of the last judgement
---@param id string @ Set identifier within the calling resource
---@return string? pointId
---@return string? optionId @ Selected option of the aimed point when it has options
Functions.getAimedInterestPoint = function(id)
    local resourceName = GetInvokingResource() or ResName
    local resourceSets = sets[resourceName]
    local set = resourceSets and resourceSets[id]
    if (not set or not set.aimed) then return nil, nil end

    return set.aimed, getSelectedOption(resourceName, id, set.aimed)
end

-- The selection holds while the marker is expanded and starts over at the first option once it collapses
---@param id string @ Set identifier within the calling resource
---@param pointId string
---@return string? optionId
Functions.getInterestPointOption = function(id, pointId)
    return getSelectedOption(GetInvokingResource() or ResName, id, pointId)
end

if (targetingEnabled) then
    -- Rendering stops while the key is up, so the press starts it again
    Functions.registerKey(targetingCommand, LibConfig.interestPointTargetingKey or "LMENU", "Show interaction points (hold)", function()
        if (next(sets)) then startRendering() end
    end)
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
    setsChanged = true
end)