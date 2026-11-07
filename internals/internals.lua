LibName = "zyke_lib"
ResName = "zyke_lib"
Context = IsDuplicityVersion() and "server" or "client"

local function empty() end

-- Holds what the interfaces/ client scripts set before the loader ran
local interfaceFunctions = Functions

Functions = setmetatable({
    name = LibName,
    context = Context
}, {
    __newindex = function(self, key, fn)
        rawset(self, key, fn)

        exports(key, fn)
    end,
    __index = function(self, key)
        local path = "functions"
        local contextChunk = LoadResourceFile(LibName, ("%s/%s/%s.lua"):format(path, key, Context))
        local sharedChunk = LoadResourceFile(LibName, ("%s/%s/shared.lua"):format(path, key))

        local chunk = sharedChunk or contextChunk
        local _context = sharedChunk and "shared" or Context

        if (chunk) then
            local func, err = load(chunk, ("@@%s/%s/%s/%s.lua"):format(LibName, path, key, _context))

            if (not func or err) then
                return error(err)
            end

            rawset(self, key, func() or empty)

            return self[key]
        end

        return interfaceFunctions and rawget(interfaceFunctions, key)
    end
})