-- Dependency Override Config
-- Use this file to explicitly define which system you use for each category.
-- By default, everything is set to "auto", which means zyke_lib will
-- automatically detect the first available system.
--
-- If you are getting stuck on the dependency loading step, set the
-- appropriate system to the exact resource name you use.
--
-- Options:
--   "auto"             - Automatically detect which system to use (default)
--   "<resource_name>"  - Use a specific resource (will wait for it to start)
--   "none"             - Skip detection entirely, use your framework's built-in system
--
-- NOTE: "none" is only valid for optional systems (gang, fuel, death, banking).
-- Setting "none" means the library will fall back to your framework's default behavior.
-- For example, gang = "none" will use QB's built-in gang system.

return {
    ---========================================---
    --- REQUIRED SYSTEMS
    --- These must always be set to a valid resource
    ---========================================---

    -- Your core framework
    -- Options: "auto", "es_extended", "qb-core"
    framework = "auto",

    -- Your inventory system
    -- Options: "auto", "qs-inventory", "ox_inventory", "tgiann-inventory", "codem-inventory", "core_inventory"
    inventory = "auto",

    -- Your targeting system
    -- Options: "auto", "ox_target", "qb-target"
    target = "auto",

    ---========================================---
    --- OPTIONAL SYSTEMS
    --- Set to "none" to skip and use your framework's defaults
    ---========================================---

    -- Gang system (set to "none" to use your framework's built-in gangs)
    -- Options: "auto", "none", "zyke_gangs"
    gang = "auto",

    -- Fuel system (set to "none" if you don't need fuel management)
    -- Options: "auto", "none", "ox_fuel", "LegacyFuel", "cdn-fuel", "lc_fuel"
    fuel = "auto",

    -- Death check system (set to "none" to use your framework's built-in death checks)
    -- Options: "auto", "none", "wasabi_ambulance", "wasabi_ambulance_v2"
    death = "auto",

    -- Banking system (set to "none" if you don't use society banking)
    -- Options: "auto", "none", "Renewed-Banking", "RxBanking", "okokBanking", "bablo-banking"
    banking = "auto",
}
