return {
    debug = false,
    language = "en", -- locales

    -- If enabled, it will silence slow loading warnings
    -- This could potentially silence a useful indicator that something is wrong,
    -- so it's a trade-off between a cleaner console log and info
    silenceWarnings = false,

    -- Formats numbers using JavaScript Intl.NumberFormat.
    -- Injects automatically to your locales during runtime
    -- Any valid Intl locale string can be used,
    -- these common choices cover the main distinct output styles.
    -- Examples use the value 1234567.89:
    -- ar-EG - Arabic (Egypt) - ١٬٢٣٤٬٥٦٧٫٨٩
    -- bn-BD - Bangla (Bangladesh) - ১২,৩৪,৫৬৭.৮৯
    -- de-DE - German (Germany) - 1.234.567,89
    -- en-IN - English (India) - 12,34,567.89
    -- en-US - English (United States) - 1,234,567.89
    -- fa-IR - Persian (Iran) - ۱٬۲۳۴٬۵۶۷٫۸۹
    -- fr-FR - French (France) - 1 234 567,89
    -- hi-IN-u-nu-deva - Hindi (India, Devanagari digits) - १२,३४,५६७.८९
    -- sv-SE - Swedish (Sweden) - 1 234 567,89
    localeString = "en-US",

    -- Wraps formatted numbers with your preferred currency display
    -- Injects automatically to your locales during runtime
    -- Examples: "$%s", "%s kr", "€%s", "%s EUR"
    currencyFormat = "$%s",

    -- Shows a dot in the middle of the screen while you are close to looking at an interest point
    -- you aim at to interact with, so it is easier to line up
    interestPointGuide = true,

    -- Works like a target system: interest points stay hidden and can't be used until the key below is held
    -- When disabled, they always show while you are near them
    interestPointTargeting = false,

    -- Default key to hold, only used when interestPointTargeting is enabled
    -- Players can change it for themselves in the GTA key binding settings
    -- Key names: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    interestPointTargetingKey = "LMENU", -- Left alt
}