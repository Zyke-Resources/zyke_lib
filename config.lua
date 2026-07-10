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
}