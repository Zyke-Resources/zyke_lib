return {
    debug = false,
    language = "en", -- locales
    localeString = "en", -- https://en.wikipedia.org/wiki/IETF_language_tag#List_of_common_primary_language_subtags TODO: Inject the localeString in all locales, or just include it in the locales

    -- If enabled, it will silence slow loading warnings
    -- This could potentially silence a useful indicator that something is wrong,
    -- so it's a trade-off between a cleaner console log and info
    silenceWarnings = true,
}