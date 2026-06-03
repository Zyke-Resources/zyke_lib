local requests = {}
local cbEvent = "zlib:cb:%s"

Functions.callback = {}

local function unpackPacked(t)
    if (type(t) ~= "table") then
        return t
    end

    return table.unpack(t, 1, t.n or #t)
end

local function resolveTimeout(p, cbExtras, reqId)
    if (cbExtras and cbExtras.status) then
        local status = {
            ok = false,
            err = "timeout",
            timedOut = true,
        }

        if (cbExtras.cb) then
            cbExtras.cb(status)
        elseif (p) then
            p:resolve({ n = 1, status })
        end
    else
        if (cbExtras and cbExtras.cb) then
            cbExtras.cb(nil)
        elseif (p) then
            p:resolve({ n = 1, nil })
        end
    end

    if (reqId) then
        Z.debug.internal("^3Request timed out^7", reqId)
    end
end

local function getKey()
    local id

    repeat
        id = math.random(0, 1000000)
    until not requests[id]

    return id
end

RegisterNetEvent(cbEvent:format(ResName), function(reqId, ...)
    local cb = requests[reqId]
    requests[reqId] = nil

    return cb and cb(...)
end)

---@class CallbackExtras
---@field retry number | false | nil @Number of retry attempts (0/false/nil for no retry)
---@field timeout number | false | nil @ms, 0/false/nil for no timeout, how long to wait for each attempt before retrying/giving up
---@field status boolean | nil @If true, prepends a status table as the first return value: `{ ok=true }` or `{ ok=false, err="timeout" }`
---@field cb function | nil @Callback to be called when the request is resolved, doesn't block flow of code

---@param event string
---@param cbExtras CallbackExtras | nil @Extra information, like a timeout, not passed to the server
---@param ... any @Arguments to be passed to the server
local function triggerServerCallback(event, cbExtras, ...)
    if (not cbExtras) then cbExtras = {} end

    local args = { ... }
    local p = cbExtras.cb and nil or promise.new()
    local prevKey = nil
    local done = false
    local attemptsLeft = (cbExtras.retry and cbExtras.retry > 0) and cbExtras.retry or 0

    local function executeNewCallback()
        if (done) then return end
        if (prevKey) then requests[prevKey] = nil end

        local reqId = getKey()
        prevKey = reqId
        local attemptTimedOut = false

        requests[reqId] = function(...)
            if (done or attemptTimedOut) then
                return
            end

            local res
            if (cbExtras.status) then
                res = table.pack({ ok = true }, ...)
            else
                res = table.pack(...)
            end
            done = true

            if (cbExtras.cb) then
                cbExtras.cb(unpackPacked(res))
            else
                p:resolve(res)
            end
        end

        TriggerServerEvent(cbEvent:format(event), ResName, reqId, table.unpack(args))

        -- Timeout handler for this attempt
        if (
            cbExtras.timeout and
            cbExtras.timeout ~= false and
            cbExtras.timeout ~= nil and
            cbExtras.timeout ~= 0
        ) then
            SetTimeout(cbExtras.timeout, function()
                if (not done and not attemptTimedOut) then
                    attemptTimedOut = true

                    if (attemptsLeft > 0) then
                        attemptsLeft = attemptsLeft - 1
                        Z.debug.internal("^3Request timed out, retrying (" .. attemptsLeft .. " attempts left)^7", reqId)
                        executeNewCallback()
                    else
                        done = true

                        if (prevKey) then
                            requests[prevKey] = nil
                        end

                        Z.debug.internal("^3Request timed out with no retries left^7", reqId)

                        if (cbExtras.cb) then
                            resolveTimeout(nil, cbExtras, reqId)
                        else
                            resolveTimeout(p, cbExtras, reqId)
                        end
                    end
                end
            end)
        end
    end

    executeNewCallback()

    if (not cbExtras.cb) then
        local res = Citizen.Await(p)
        return unpackPacked(res)
    end
end

---@deprecated
---@param event string
---@param ... any @Arguments to be passed to the server
---@diagnostic disable-next-line: duplicate-set-field
function Functions.callback.await(event, ...)
    return triggerServerCallback(event, nil, ...)
end

-- Support for the new cbExtras parameter
-- New function to avoid breaking old compatibility
--- Should eventually move everything to this request function, or refactor all old await functions to the new cbExtras parameter
---@param event string
---@param cbExtras CallbackExtras | nil @Extra information, like a timeout, not passed to the server
---@param ... any @Arguments to be passed to the server
---@diagnostic disable-next-line: duplicate-set-field
function Functions.callback.request(event, cbExtras, ...)
    return triggerServerCallback(event, cbExtras, ...)
end

---@diagnostic disable-next-line: duplicate-set-field
function Functions.callback.register(event, cb)
    RegisterNetEvent(cbEvent:format(event), function(reqId, ...)
        TriggerServerEvent(cbEvent:format(ResName), reqId, cb(...))
    end)
end

return Functions.callback