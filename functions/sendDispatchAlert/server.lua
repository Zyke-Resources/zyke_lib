---@class DispatchAlertBlip
---@field sprite? integer
---@field colour? integer
---@field scale? number
---@field radius? number @ Metres, adds a radius blip
---@field duration? integer @ Seconds the blip stays on the map
---@field flash? boolean

---@class DispatchAlert
---@field coords vector3
---@field title string @ Short, such as "Store robbery"
---@field code? string @ Such as "10-90"
---@field description? string
---@field jobs? string[] @ Defaults to the police jobs
---@field blip? DispatchAlertBlip
---@field priority? integer @ 1 is the highest
---@field sound? boolean

---@class ResolvedDispatchAlertBlip
---@field sprite integer
---@field colour integer
---@field scale number
---@field radius? number
---@field duration integer
---@field flash boolean

---@class ResolvedDispatchAlert
---@field coords vector3
---@field title string
---@field code? string
---@field description? string
---@field jobs string[]
---@field blip ResolvedDispatchAlertBlip
---@field priority? integer
---@field sound boolean

local defaultBlip = {sprite = 161, colour = 1, scale = 1.2, duration = 300}

-- QBCore & Qbox mark law enforcement jobs with type "leo", ESX jobs have no type
local policeJobNames = {"police", "sheriff"}

---@return string[] jobs
local function getPoliceJobs()
    local jobs = Functions.getJobs()
    local found = {}

    for name, job in pairs(jobs) do
        if (type(job) == "table" and job.type == "leo") then found[#found + 1] = name end
    end

    if (#found > 0) then return found end

    for i = 1, #policeJobNames do
        if (jobs[policeJobNames[i]]) then found[#found + 1] = policeJobNames[i] end
    end

    if (#found > 0) then return found end

    return {"police"}
end

---@param data DispatchAlert
---@return ResolvedDispatchAlert
local function resolveAlert(data)
    local blip = data.blip or {}
    local radius = tonumber(blip.radius)
    local hasJobs = type(data.jobs) == "table" and #data.jobs > 0

    return {
        coords = vec3(data.coords.x, data.coords.y, data.coords.z),
        title = data.title,
        code = data.code ~= "" and data.code or nil,
        description = data.description ~= "" and data.description or nil,
        jobs = hasJobs and data.jobs or getPoliceJobs(),
        priority = tonumber(data.priority),
        sound = data.sound ~= false,
        blip = {
            sprite = blip.sprite or defaultBlip.sprite,
            colour = blip.colour or defaultBlip.colour,
            scale = blip.scale or defaultBlip.scale,
            radius = radius and radius > 0 and radius + 0.0 or nil,
            duration = blip.duration or defaultBlip.duration,
            flash = blip.flash == true,
        },
    }
end

---@param alert ResolvedDispatchAlert
---@return boolean isUrgent
local function isUrgent(alert)
    return alert.priority ~= nil and alert.priority <= 1
end

---@param alert ResolvedDispatchAlert
---@return "high" | "medium" | "low" priority
local function getPriorityName(alert)
    local priority = alert.priority or 2
    if (priority <= 1) then return "high" end
    if (priority == 2) then return "medium" end

    return "low"
end

-- For dispatches with a single text field
---@param alert ResolvedDispatchAlert
---@return string text
local function getText(alert)
    if (not alert.description) then return alert.title end

    return ("%s - %s"):format(alert.title, alert.description)
end

---@param alert ResolvedDispatchAlert
---@return integer minutes
local function getBlipMinutes(alert)
    return math.max(1, math.ceil(alert.blip.duration / 60))
end

-- cd_dispatch and cd_dispatch3d take the same AddNotification table
---@param alert ResolvedDispatchAlert
---@return table data
local function getCodesignData(alert)
    local blip = alert.blip
    local title = alert.code and ("%s - %s"):format(alert.code, alert.title) or alert.title

    return {
        job_table = alert.jobs,
        coords = alert.coords,
        title = title,
        message = alert.description or alert.title,
        flash = isUrgent(alert) and 1 or 0,
        unique_id = tostring(math.random(1000000, 9999999)),
        sound = alert.sound and 1 or nil,
        blip = {
            sprite = blip.sprite,
            scale = blip.scale,
            colour = blip.colour,
            flashes = blip.flash,
            text = title,
            time = getBlipMinutes(alert),
            radius = blip.radius or 0,
        },
    }
end

-- Sends keyed by DispatchSystem, each returning whether the dispatch took the alert
---@type table<string, fun(alert: ResolvedDispatchAlert): boolean>
local sends = {
    ["cd_dispatch3d"] = function(alert)
        TriggerEvent("cd_dispatch:AddNotification", getCodesignData(alert))

        return true
    end,
    ["ps-dispatch"] = function(alert)
        -- Only its client export makes a call for a whole job, so the player closest to the alert sends it
        local plyId = Functions.getClosestPlayerToPos(alert.coords)
        if (plyId == -1) then return false end

        local blip = alert.blip

        TriggerClientEvent("zyke_lib:SendPsDispatchAlert", plyId, {
            message = alert.title,
            code = alert.code,
            information = alert.description,
            priority = isUrgent(alert) and 1 or 2,
            coords = alert.coords,
            jobs = alert.jobs,
            radius = blip.radius or 0,
            sprite = blip.sprite,
            color = blip.colour,
            scale = blip.scale,
            length = blip.duration / 60,
            flash = blip.flash,
        })

        return true
    end,
    ["cd_dispatch"] = function(alert)
        -- Every client receives it and keeps it when its job is in job_table
        TriggerClientEvent("cd_dispatch:AddNotification", -1, getCodesignData(alert))

        return true
    end,
    ["qs-dispatch"] = function(alert)
        local blip = alert.blip

        TriggerEvent("qs-dispatch:server:CreateDispatchCall", {
            job = alert.jobs,
            callLocation = alert.coords,
            callCode = {code = alert.code or "", snippet = alert.title},
            message = alert.description or alert.title,
            flashes = isUrgent(alert),
            blip = {
                sprite = blip.sprite,
                scale = blip.scale,
                colour = blip.colour,
                flashes = blip.flash,
                text = alert.title,
                time = blip.duration * 1000,
            },
        })

        return true
    end,
    ["rcore_dispatch"] = function(alert)
        local blip = alert.blip

        TriggerEvent("rcore_dispatch:server:sendAlert", {
            code = alert.code or "",
            default_priority = getPriorityName(alert),
            coords = alert.coords,
            job = alert.jobs,
            text = getText(alert),
            type = "alerts",
            blip_time = blip.duration,
            blip = {
                sprite = blip.sprite,
                colour = blip.colour,
                scale = blip.scale,
                text = alert.title,
                flashes = blip.flash,
                radius = blip.radius or 0,
            },
        })

        return true
    end,
    ["core_dispatch"] = function(alert)
        local blip = alert.blip
        local extraInfo = alert.description and {{icon = "fa-circle-info", info = alert.description}} or {}

        exports["core_dispatch"]:addCall(alert.code or "", alert.title, extraInfo, alert.coords, alert.jobs, blip.duration * 1000, blip.sprite, blip.colour, isUrgent(alert))

        return true
    end,
    ["tk_dispatch"] = function(alert)
        local blip = alert.blip

        exports["tk_dispatch"]:addCall({
            title = alert.title,
            jobs = alert.jobs,
            coords = alert.coords,
            code = alert.code,
            priority = alert.priority and ("Priority %d"):format(alert.priority) or nil,
            message = alert.description,
            removeTime = blip.duration * 1000,
            flash = isUrgent(alert),
            playSound = alert.sound,
            blip = {
                sprite = blip.sprite,
                scale = blip.scale,
                color = blip.colour,
                flash = blip.flash,
                radius = blip.radius,
            },
        })

        return true
    end,
    ["codem-dispatchv2"] = function(alert)
        local blip = alert.blip

        local callId = exports["codem-dispatchv2"]:SendDispatchAlert({
            code = alert.code,
            message = getText(alert),
            coords = alert.coords,
            jobs = alert.jobs,
            priority = isUrgent(alert),
            sound = alert.sound,
            blip = {
                sprite = blip.sprite,
                color = blip.colour,
                scale = blip.scale,
                radius = blip.radius or 0,
                length = getBlipMinutes(alert),
                flash = blip.flash,
            },
        })

        return callId ~= nil and callId ~= false
    end,
    ["lb-tablet"] = function(alert)
        local blip = alert.blip
        local options = {
            priority = getPriorityName(alert),
            code = alert.code or "",
            title = alert.title,
            description = alert.description or "",
            location = {label = alert.title, coords = vec2(alert.coords.x, alert.coords.y)},
            time = blip.duration,
            job = alert.jobs,
            blip = {
                type = blip.radius and "radius" or "default",
                sprite = blip.sprite,
                color = blip.colour,
                size = blip.scale,
                label = alert.title,
                radius = blip.radius,
            },
        }

        -- False mutes it, leaving it out plays the default sound
        if (not alert.sound) then options.sound = false end

        local dispatchId = exports["lb-tablet"]:AddDispatch(options)

        -- False when no MDT takes any of the jobs
        return dispatchId ~= nil and dispatchId ~= false
    end,
}

-- A notification & a temporary blip for each on-duty player of the jobs
---@param alert ResolvedDispatchAlert
local function sendFallback(alert)
    local players = Functions.getPlayersOnJob(alert.jobs)

    for i = 1, #players do
        local job = Functions.getJob(players[i])

        -- ESX jobs without a duty state count as on duty
        if (job and job.onDuty ~= false) then
            TriggerClientEvent("zyke_lib:SendDispatchFallback", players[i], alert)
        end
    end
end

-- May yield through the dispatch's exports, call it from a thread or handler
-- When no dispatch runs, or it refuses or fails, the on-duty players of the jobs get the fallback instead
---@param data DispatchAlert
---@return boolean taken @ Whether a dispatch resource took the alert
function Functions.sendDispatchAlert(data)
    if (type(data) ~= "table" or not data.coords) then return false end
    if (type(data.title) ~= "string" or data.title == "") then return false end

    local alert = resolveAlert(data)
    local send = DispatchSystem and sends[DispatchSystem]

    if (send) then
        local ok, taken = pcall(send, alert)
        if (ok and taken) then return true end

        if (not ok) then
            Functions.debug.internal("^1" .. tostring(DispatchSystem) .. " failed to take a dispatch alert: " .. tostring(taken) .. "^7")
        end
    end

    sendFallback(alert)

    return false
end

return Functions.sendDispatchAlert