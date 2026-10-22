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
-- NOTE: "none" is only valid for optional systems (gang, fuel, vehicleKeys, doorlock, death, banking, notification, phone).
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
    -- Options: "auto", "qs-inventory", "ox_inventory", "tgiann-inventory", "codem-inventory", "core_inventory", "one_inventory"
    inventory = "auto",

    -- Your targeting system
    -- Options: "auto", "ox_target", "qb-target"
    target = "auto",

    ---========================================---
    --- OPTIONAL SYSTEMS
    --- Set to "none" to skip and use your framework's defaults
    ---========================================---

    -- Gang system (set to "none" to use your framework's built-in gangs)
    -- Options: "auto", "none", "pug-gangs"
    gang = "auto",

    -- Fuel system (set to "none" if you don't need fuel management)
    -- Options: "auto", "none", "ox_fuel", "LegacyFuel", "cdn-fuel", "lc_fuel", "rcore_fuel", "Renewed-Fuel"
    fuel = "auto",

    -- Vehicle key system
    -- Options: "auto", "none", "zyke_vehiclekeys", "qb-vehiclekeys", "qbx_vehiclekeys", "qs-vehiclekeys", "wasabi_carlock"
    vehicleKeys = "auto",

    -- Door lock system, used by resources that lock their doors to a job (set to "none" to add doors yourself)
    -- qb-doorlock can't take doors from another resource, resources ship a config file for it instead
    -- Options: "auto", "none", "ox_doorlock", "rcore_doorlock", "qb-doorlock"
    doorlock = "auto",

    -- Death check system (set to "none" to use your framework's built-in death checks)
    -- Options: "auto", "none", "sky_ambulancejob", "wasabi_ambulance", "wasabi_ambulance_v2", "osp_ambulance"
    death = "auto",

    -- HUD system (set to "none" if you don't use a HUD resource)
    -- Options: "auto", "none", "jg-hud", "esx_hud", "wais-hudv6", "0r-hud-v3", "17mov_Hud",
    -- "izzy-hudv6", "vms_hud", "rhud", "envi-hud", "cx-hud", "tgiann-lumihud", "izzy-hudv7",
    -- "hex_4_hud", "minimal-hud", "izzy-hudv5", "tgg-hud", "sync-hud", "hex_hud_prem", "bablo-hud"
    hud = "auto",

    -- Banking system (set to "none" if you don't use society banking)
    -- Options: "auto", "none", "tgg-banking", "Renewed-Banking", "RxBanking", "okokBanking", "bablo-banking", "sky_banking", "kartik-banking", "lation_banking"
    banking = "auto",

    -- Notification system (set to "none" to use your framework's built-in notifications)
    -- Options: "auto", "none", "ox_lib", "lation_ui"
    notification = "auto",

    -- Phone system, used for phone numbers and texts (set to "none" to only use your framework's phone numbers)
    -- Phones are never waited for, the library follows them as they start & stop
    -- Options: "auto", "none", "sd-phone", "lb-phone", "yseries", "okokPhone", "roadphone", "gksphone",
    -- "qs-smartphone-pro", "qs-smartphone", "high-phone", "17mov_Phone", "npwd"
    phone = "auto",

    -- Progressbar system
    -- Options: "auto", "zyke_lib", "ox_lib", "lation_ui", "wasabi_uikit"
    -- Defaults to zyke_lib. You must explicitly set "ox_lib" or "lation_ui" here if you want to use their progressbars.
    progressbar = "auto",
}