return {
    debug = false,
    language = "en", -- locales

    -- Languages players can pick for themselves with the command below, by their locale file names
    -- A player who never picks one sees `language`, and an empty list turns the choice off
    -- Only resources made for it follow the player's pick, everything stored or shared stays in `language`
    playerLanguages = {"en", "sv", "de", "fr", "es", "it", "pt", "nl", "pl", "cs", "ro", "tr", "lt", "ar", "ja", "zh", "th"},
    languageCommand = "language",

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

    -- Interest points inside a building only show, and can only be used, while you are in the same room
    -- When disabled, they also show through walls from other rooms and from outside
    interestPointRoomCheck = true,

    -- Works like a target system: interest points stay hidden and can't be used until the key below is held
    -- When disabled, they always show while you are near them
    interestPointTargeting = false,

    -- Default key to hold, only used when interestPointTargeting is enabled
    -- Players can change it for themselves in the GTA key binding settings
    -- Key names: https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/
    interestPointTargetingKey = "LMENU", -- Left alt

    -- Default key that goes back out of an interest point's submenu, as its back row does
    -- Players can change it for themselves in the GTA key binding settings
    interestPointBackKey = "Q",

    -- The column the missions of every resource stack in, such as a player's jobs and the robbery they are part of
    -- position is "top-left", "top-right", "center-left", "center-right", "bottom-left" or "bottom-right"
    -- offset is the gap to the screen edges, in percent of the screen height
    missionTracker = {
        position = "top-left",
        offset = {x = 2.5, y = 2.5},
    },

    -- Discord roles, the bot token and guild ID are server convars, see the README
    discordRoles = {
        -- Keeps fetched roles in the resource KVP, so after a restart they answer right away instead of every player being fetched again
        -- A role changed while the server was down is corrected by the fetch when the player connects
        keepAfterRestart = true,

        -- Minutes before an online player's roles are fetched again in the background
        refreshMinutes = 10,

        -- Fetches roles again right away: /refreshdiscordroles <server id | Discord ID | identifier such as license:... | all>
        -- The server console and txAdmin's live console can always use it, players need one of these permissions
        refreshCommand = {command = "refreshdiscordroles", permission = {"command", "admin", "superadmin", "owner"}},
    },
}