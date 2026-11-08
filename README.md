# [> Download](https://github.com/ZykeWasTaken/zyke_lib/releases/latest)

# What Is This?

Our library acts as a bridge for dependencies, such as frameworks, progressbars, dispatch systems, inventories etc. Our resources call functions within the library, which then calls the automatically selected dependency to streamline the entire process. Despite it's name, it is not the same as other libraries such as ox_lib.

There are a few similar resources from other creators, but unfortunately no centralized solution that everyone can use exists. This is because these libraries are usually constructed differently, consume and return different information etc.

All of our resources are built on top of this library, and is a requirement to use if you wish to run any of them.

## Important

Downloading an experimental & non-release version is **not recommended unless you know what you are doing**. We constantly update this repository to make the development of Zyke Resources' scripts easier, and we don't always test all functionality on different servers using different frameworks. **[Head over to the release page for a stable release.](https://github.com/ZykeWasTaken/zyke_lib/releases/latest)**

## Modified Servers

Please be aware that heavily modified servers may cause our library to struggle without any adapting. Everything framework-dependant in our resources can be modified in our library, or in the unlocked files of the resource. If you are unsure if our resources will work for you, feel free to create a ticket in our Discord and we will assist you swiftly.

## Framework Support

- ESX
- QBCore
- Qbox

## Inventory Support

-   **BIG NOTE:** There may be changes for specific resources, view each resources' dependencies carefully
-   Regular QBCore inventories
  	- Variations like ps or ak47 may be incompatible. Please consult us in our [Discord](https://discord.zykeresources.com) before purchase if you are unsure.
-   Full support for ox_inventory
-   Full support for qs-inventory
-   Full support for TGIANN-inventory
-   Full support for codem-inventory
-   Full QBCore support for core_inventory

## Target Support

-   ox_target
-   qb-target
-   We are now using a most-fitting approach for our releases, which means some features may require a target system if it fits the best

## Dependencies

- [A compatible framework](#framework-support)
- [A compatible inventory](#inventory-support)

## Adding Compatibility

All interactions with outside dependencies, such as frameworks, progressbars and inventories can modified, and most of it in here.

We use a modular approach, allowing you to add new compatibility, or custom behaviour, for specific functions.

Below you will find all the files connected to a dependency.

### Inventory

Some inventories offer a lot of backwards-compatible functionality and you may not need to edit all of the files.

-   [systems/inventory.lua](systems/inventory.lua)
-   [formatting/formatItem/shared.lua](formatting/formatItem/shared.lua)
-   [functions/addItem/server.lua](functions/addItem/server.lua)
-   [functions/canCarryItem/server.lua](functions/canCarryItem/server.lua)
-   [functions/getInventoryImagePath/shared.lua](functions/getInventoryImagePath/shared.lua)
-   [functions/getInventorySlot/server.lua](functions/getInventorySlot/server.lua)
-   [functions/getItemDurability/shared.lua](functions/getItemDurability/shared.lua)
-   [functions/getPlayerItems/client.lua](functions/getPlayerItems/client.lua)
-   [functions/getPlayerItems/server.lua](functions/getPlayerItems/server.lua)
-   [functions/hasItem/server.lua](functions/hasItem/server.lua)
-   [functions/money/server.lua](functions/money/server.lua)
-   [functions/registerUsableItem/server.lua](functions/registerUsableItem/server.lua)
-   [functions/removeFromSlot/server.lua](functions/removeFromSlot/server.lua)
-   [functions/setItemDurability/server.lua](functions/setItemDurability/server.lua)
-   [functions/setItemMetadata/server.lua](functions/setItemMetadata/server.lua)
-   [functions/stash/client.lua](functions/stash/client.lua)
-   [functions/stash/server.lua](functions/stash/server.lua)
-   [functions/unequipWeapon/client.lua](functions/unequipWeapon/client.lua)
-   [internals/events/client.lua](internals/events/client.lua)
-   [internals/items/client.lua](internals/items/client.lua)
-   [internals/items/server.lua](internals/items/server.lua)
-   [interfaces/weaponBlock/client.lua](interfaces/weaponBlock/client.lua)
-   [internals/weaponBlock/server.lua](internals/weaponBlock/server.lua)

### Fuel

-   `systems/fuel.lua`
-   `functions/getFuel/client.lua`
-   `functions/setFuel/client.lua`

### Door Lock

-   `systems/doorlock.lua`
-   `functions/doorlock/server.lua`

### Target

-   `systems/target.lua`
-   `functions/target/client.lua`

### Death/Ambulance

-   `systems/death.lua`
-   `functions/isPlayerDead/client.lua`

### HUD

-   `systems/hud.lua`
-   `functions/hud/client.lua`

### Appearance

-   `systems/appearance.lua`
-   `functions/appearance/client.lua`

### Framework

To add in a completely new framework, you would need to modify pretty much all files.

### Gang

Currently unused

## Dependency Override

By default, `zyke_lib` automatically detects which systems you are running (framework, inventory, target, etc.). If auto-detection fails or you want to explicitly specify a system, you can configure this in `dependency_override.lua`.

Each system supports the following values:

| Value | Description |
|---|---|
| `"auto"` | Automatically detect which system to use **(default)** |
| `"<resource_name>"` | Use a specific resource (will wait for it to start) |
| `"none"` | Skip detection entirely, fall back to your framework's built-in system |

> **Note:** `"none"` is only valid for **optional** systems (gang, fuel, vehicle keys, door lock, death, banking, notification, dispatch). Setting it means the library will use your framework's default behavior instead.

### Available Systems

**Required** (must always resolve to a valid resource):

| System | Options |
|---|---|
| `framework` | `"auto"`, `"es_extended"`, `"qb-core"` |
| `inventory` | `"auto"`, `"qs-inventory"`, `"ox_inventory"`, `"tgiann-inventory"`, `"codem-inventory"`, `"core_inventory"`, `"one_inventory"` |
| `target` | `"auto"`, `"ox_target"`, `"qb-target"` |

**Optional** (can be set to `"none"`):

| System | Options |
|---|---|
| `gang` | `"auto"`, `"none"`, `"pug-gangs"` |
| `fuel` | `"auto"`, `"none"`, `"ox_fuel"`, `"LegacyFuel"`, `"cdn-fuel"`, `"lc_fuel"`, `"rcore_fuel"`, `"Renewed-Fuel"`, `"lyre_fuel"` |
| `vehicleKeys` | `"auto"`, `"none"`, `"zyke_vehiclekeys"`, `"qb-vehiclekeys"`, `"qbx_vehiclekeys"`, `"qs-vehiclekeys"`, `"wasabi_carlock"`, `"Renewed-Vehiclekeys"` |
| `doorlock` | `"auto"`, `"none"`, `"ox_doorlock"`, `"rcore_doorlock"`, `"qb-doorlock"` |
| `death` | `"auto"`, `"none"`, `"sky_ambulancejob"`, `"wasabi_ambulance"`, `"wasabi_ambulance_v2"`, `"osp_ambulance"` |
| `hud` | `"auto"`, `"none"`, or any HUD listed under [HUD Visibility](#hud-visibility) |
| `banking` | `"auto"`, `"none"`, `"tgg-banking"`, `"Renewed-Banking"`, `"RxBanking"`, `"okokBanking"`, `"bablo-banking"`, `"sky_banking"`, `"kartik-banking"`, `"lation_banking"` |
| `notification` | `"auto"`, `"none"`, `"ox_lib"`, `"lation_ui"`, `"wasabi_uikit"` |
| `dispatch` | `"auto"`, `"none"`, `"cd_dispatch3d"`, `"ps-dispatch"`, `"cd_dispatch"`, `"qs-dispatch"`, `"rcore_dispatch"`, `"core_dispatch"`, `"tk_dispatch"`, `"codem-dispatchv2"`, `"lb-tablet"` |
| `progressbar` | `"auto"`, `"zyke_lib"`, `"ox_lib"`, `"lation_ui"`, `"wasabi_uikit"` |
| `appearance` | `"auto"`, `"none"`, `"onex-creation"`, `"illenium-appearance"`, `"rcore_clothing"`, `"qb-clothing"`, `"esx_skin"` |

### Example

```lua
-- dependency_override.lua
return {
    framework = "auto",
    inventory = "ox_inventory",  -- Force ox_inventory
    target = "auto",

    gang = "none",    -- Use framework's built-in gang system
    fuel = "ox_fuel",
    vehicleKeys = "auto",
    doorlock = "auto",
    death = "auto",
    hud = "auto",
    banking = "none",
    notification = "auto",
    progressbar = "auto",
}
```

> **Note:** `wasabi_uikit` has no per-call cancel setting, so its cancel key can stop progressbars that set `canCancel = false`.

> **Tip:** If your server gets stuck on the dependency loading step, set the appropriate system to the exact resource name you use instead of `"auto"`.

## Listing the Systems a Resource Uses

A resource lists the systems it uses with `zyke_systems` in its `fxmanifest.lua`. Before its files load, the loader waits only for those and for the framework and inventory, which it always waits for. Every other system is followed: it selects the resource that runs at that moment and selects again whenever one of its resources starts or stops. A fuel or garage resource that is stopped or starts later then no longer holds back resources that never use it.

```lua
zyke_systems {
    "framework",
    "inventory",
    "target",
    "fuel",
    "vehicleKeys",
}
```

- The names are the keys of `dependency_override.lua`, and both work together: a listed system waits for the resource named there, and a followed one selects it while it runs.
- A resource without `zyke_systems` waits for every system, as before.
- List every system the resource uses, also the ones it only reaches through another function, such as the fuel that `Z.setVehicleMods` sets. When the resource uses a function that reads a system it did not list, the console warns once and names the system.
- A resource that uses no other system lists `"framework"`, since an empty list reads the same as no list.
- A listed system is selected once while the resource starts, as before, so it keeps that selection if its resource stops later.

## Player Languages

`language` in `config.lua` is the server language. Players can also pick their own with `/language`, which opens a menu, or `/language sv`. Each player's pick is saved on their PC, so it comes back every time they join, and the server only accepts languages listed in `playerLanguages`. An empty list turns the choice off.

```lua
language = "en",
playerLanguages = {"en", "sv", "de", "fr"},
languageCommand = "language",
```

The player's pick changes only the text that player sees. Item labels, item metadata, saved names, logs and webhooks, and anything other players see all stay in the server language. A resource follows the pick only when it is made for it, and all other resources stay in the server language.

### Making a Resource Follow the Player's Language

Add the opt-in to the resource's `fxmanifest.lua`:

```lua
zyke_player_language "yes"
```

- On the client, `T` and `Translations` switch to the new language the moment the player picks it. Code that keeps a reference to `Translations` sees the new text.
- Text built only once, such as key mapping descriptions, blips, target options and labels the resource saved earlier, is rebuilt in `Z.onLanguageChange`. It runs after `Translations` has changed.

```lua
Z.onLanguageChange(function(language)
    refreshBlips()
end)
```

- The NUI is sent the new strings as the message `{event = "zyke_lib:strings", data = strings}`, so the page replaces the strings it asked for at start.
- On the server, `T` writes in the server language. Text the server builds for one player alone, such as a callback result, is written with `TFor(plyId, key, formatting)`, which uses that player's language. `Z.notify(plyId, key)` is translated on the player's client, so it already follows their language.
- A language the resource has no locale file for shows the server language, and a key a locale file lacks shows the English text.
- A translation whose placeholders do not format falls back to the English text and warns once in the console. It no longer breaks the code that asked for it.

## Dispatch

`Z.sendDispatchAlert(data)` sends a police alert through the server's dispatch resource. It runs on the server and returns whether a dispatch resource took the alert. With no dispatch, the on-duty players of the alert's jobs get a notification and a temporary map blip instead.

```lua
Z.sendDispatchAlert({
    coords = vector3(25.7, -1347.3, 29.5),
    title = "Store robbery",
    code = "10-90",
    blip = {sprite = 52, colour = 1, duration = 300},
    priority = 1,
})
```

Supported: ps-dispatch, cd_dispatch3d, cd_dispatch, qs-dispatch, rcore_dispatch, core_dispatch, tk_dispatch, codem-dispatchv2 and lb-tablet. Fields, the fallback and each dispatch's limits are in [docs/dispatch.md](docs/dispatch.md).

## Door Lock

`Z.doorlock.*` lets a resource lock its own doors to a job. It runs on the server.

| `Z.doorlock` method | Purpose |
|---|---|
| `getProvider()` | Selected resource name |
| `isAvailable()` | Whether the selected resource is started |
| `ensure(entry)` | Adds the door unless the door lock already has it, returns `ensured, reason?` |

`entry` takes a unique `name`, `doors` (one door, or both halves of a double door, each `{model, coords, heading}`), and optionally `label`, `group`, `jobs` (names or `{name, minGrade}`, as for `Z.isJob`), `locked` (default `true`), `distance` and `pin`. A door already there is left as it is, so changes the server owner made in the door lock stay. Renaming an entry adds the door again.

| Provider | How the door is added |
|---|---|
| `ox_doorlock` | `createDoor` export with the jobs as groups, found again by `name` in the `ox_doorlock` table. The calling resource must load `@oxmysql/lib/MySQL.lua` |
| `rcore_doorlock` | `addDoor` export, one door per half, found again by position. rcore takes no job from another resource, so the door opens with `pin` until the server owner sets its access in `/doors` |
| `qb-doorlock` | Not possible: it reads its doors from `qb-doorlock/configs/*.lua`. `ensure` returns `false, "doorlockConfigOnly"` and the resource ships a config file instead |

Other `reason` values: `doorlockUnavailable` (no door lock started), `invalidDoor`, `databaseUnavailable` and `doorNotAdded`.

## Appearance

`Z.appearance.*` puts work outfits on and the saved look back. It runs on the client.

| `Z.appearance` method | Purpose |
|---|---|
| `wearOutfit(outfit)` | Puts `outfit.components` and `outfit.props` on the player without saving them, returns `worn` |
| `restore()` | Puts the character's saved clothes back on from the appearance resource, returns `restored` |

Each piece is `{id, drawable, texture?, collection?}`: `id` is the component id (0-11) or the prop anchor (0-7), and `drawable` -1 takes a prop off. With `collection` (such as `"mp_m_zyke_dden"`), `drawable` is the index inside that clothing collection, which stays the same whatever other clothing packs a server streams, where a global drawable number does not. `wearOutfit` changes nothing and returns `false` when a collection piece is not streamed for the player's ped.

| Provider | How `restore` gets the saved look |
|---|---|
| `onex-creation` | `onex-creation:client:syncClothes` event, which reloads the saved appearance from the database |
| `illenium-appearance` | `illenium-appearance:client:reloadSkin` event, which refuses while the player is dead, cuffed, falling or in a vehicle |
| `rcore_clothing` | `rcore_clothing:reloadSkin` server event, which loads the saved skin from the database |
| `qb-clothing` | `qb-clothes:loadPlayerSkin` server event |
| `esx_skin` | `esx_skin:getPlayerSkin` callback, then `skinchanger:loadSkin` |

With no appearance resource found, `restore` returns `false` and the outfit stays on.

## Discord Roles

`Z.getDiscordRoles` and `Z.hasDiscordRole` read a player's Discord roles. They run on the server.

Setup:

1. In the [Discord Developer Portal](https://discord.com/developers/applications), create an application, open **Bot** and copy the token with **Reset Token**. Use a bot of its own, since rate limits are shared per token.
2. Add the bot to your Discord server: open `https://discord.com/oauth2/authorize?client_id=APPLICATION_ID&scope=bot&permissions=0` with your application ID. It needs no permissions.
3. Turn on **Developer Mode** in Discord (**User Settings > Advanced**), right-click your server and **Copy Server ID**.
4. Add both to `server.cfg` above `ensure zyke_lib`. Use `set`, never `setr`, so the token is not sent to clients:

```cfg
set zyke_lib:discordBotToken "your bot token"
set zyke_lib:discordGuildId "your server id"
```

Players need Discord running while they connect, otherwise they have no Discord identifier and no roles. Role IDs are copied the same way, by right-clicking a role in **Server Settings > Roles**.

| Function | Purpose |
|---|---|
| `getDiscordRoles(target, maxAge?)` | Role IDs of a player server ID or Discord user ID: empty when they are not in the guild, `nil` when unknown |
| `hasDiscordRole(target, roleIds, maxAge?)` | Whether they hold the role, or any one of an array of roles. Role IDs are strings |

Without `maxAge`, the cached roles are returned straight away. Pass `maxAge` in seconds where an old answer is not good enough, such as a whitelist check: an older entry is fetched from Discord first, and the cached roles are returned when Discord does not answer within 5 seconds.

Every resource shares one cache and one request queue in `zyke_lib`, so a bot token is never used by several scripts at once:

- Roles are fetched while a player connects, unless they were fetched in the last minute. A player seen before is answered from the cache meanwhile.
- Online players are fetched again in the background every `refreshMinutes` (`config.lua`, 10 by default).
- With `keepAfterRestart` (on by default), the roles are kept in the resource KVP and loaded when `zyke_lib` starts, so a restart answers right away instead of fetching every player again. Entries not fetched for 14 days are deleted.
- Requests are sent one at a time. Lookups that wait for an answer go first; background fetches only use what is left of each rate limit bucket, and an empty bucket is waited out instead of running into a 429.
- A token or guild that Discord refuses switches the lookups off until `zyke_lib` restarts. While Discord is down, the cached roles are kept.

To fetch roles again right away, for example after someone bought a role, use `refreshdiscordroles <server id | Discord ID | identifier | all>`. An identifier such as `license:...` finds an online player, and `all` refreshes every online player in the background. The server console and txAdmin's live console can always use it; players need one of the permissions in `refreshCommand` in `config.lua`. The command only exists on the server and has no net event, so a client cannot reach it. Other server resources refresh with `Z.getDiscordRoles(target, 0)`.

Give `zyke_lib` its own bot when another bot or script already uses one: rate limits belong to the token, so sharing it shares the limits.

## Vehicle Keys

`Z.vehicleKeys.*` methods belong to `zyke_lib`; they dispatch to exports or events owned by the selected key resource. The tables below list every supported method and integration. When a method has no branch for the selected provider, it returns the documented false, nil, zero, or empty-table default.

### Key state terminology

- **Frequency** is the current physical-key generation for a plate. Item-backed providers store it in key metadata and advance it during rotation so older key items stop granting access.
- **Key counter** tracks active permanent keys for replacement-limit enforcement. It excludes garage-managed and temporary access; its increment, decrement, and reset methods adjust accounting without granting or removing access themselves.
- **Access** is persistent, garage-managed identifier access stored separately from keys issued directly to players. Updating it does not revoke purchased or otherwise issued keys.
- **Temporary access** is a replacement runtime-only identifier map. It is not persisted by the provider and must be restored after a resource restart.
- **Vehicle-state import** seeds legacy frequency, counter, and garage access when the provider has no existing state for the plate.
- **Vehicle-action notification** sends provider feedback, such as lock sounds, after another resource performs an action. It does not authorize or change vehicle state.

`rotate(plate)` invalidates player-issued permanent keys while preserving garage-managed access. `deleteVehicle(plate)` retires the provider state so old keys cannot regain access if the plate is later reused.

### Shared inspection methods

| `Z.vehicleKeys` method | Provider export | Purpose |
|---|---|---|
| `getProvider()` | None | Selected resource name |
| `isAvailable()` | None | Whether the selected resource is started |
| `getCapabilities()` | `GetCapabilities` | Provider feature and argument requirements |

### Server methods

| `Z.vehicleKeys` method | Provider export | Capability flag |
|---|---|---|
| `give(plyId, plate, allowFallback?, context?)` | `GiveKey` | `giveKey` |
| `giveTemporary(plyId, plate, skipCanGiveCheck?, allowFallback?)` | `GiveTemporaryKey`, or the provider's normal grant | `giveTemporaryKey` |
| `has(plyId, plate)` | `HasKey` | `hasKey` |
| `remove(plyId, plate)` | `RemoveKey` | `removeKey` |
| `removeAll(plyId, plate)` | `RemoveAllKeys`, or the provider's normal removal | `removeAllKeys` |
| `rotate(plate)` | `RotateKeys` | `rotateKeys` |
| `renamePlate(oldPlate, newPlate)` | `RenamePlate` | `renamePlate` |
| `deleteVehicle(plate)` | `DeleteVehicle` | `deleteVehicle` |
| `setAccess(plate, access)` | `SetAccess` | `setAccess` |
| `setTemporaryAccess(plate, access)` | `SetTemporaryAccess` | `temporaryAccessSync` |
| `importVehicleState(plate, state)` | `ImportVehicleState` | `importVehicleState` |
| `getKeyCounter(plate)` | `GetKeyCounter` | `keyCounter` |
| `getKeyFrequency(plate)` | `GetKeyFrequency` | `keyFrequency` |
| `incrementKeyCounter(plate)` | `IncrementKeyCounter` | `keyCounter` |
| `decrementKeyCounter(plate, amount?)` | `DecrementKeyCounter` | `keyCounter` |
| `resetKeyCounter(plate)` | `ResetKeyCounter` | `keyCounter` |
| `getAccessiblePlates(plyId)` | `GetAccessiblePlates` | `listKeys` |
| `notifyVehicleAction(plyId, netId, action, desiredState)` | `NotifyVehicleAction` | `vehicleActionFeedback` |

### Client methods

| `Z.vehicleKeys` method | Provider export | Capability flag |
|---|---|---|
| `give(plateOrVehicle)` | `GiveKey` | `giveKey` |
| `has(plateOrVehicle)` | `HasKey` | `hasKey` |
| `remove(plateOrVehicle)` | `RemoveKey` | `removeKey` |
| `getAccessiblePlates()` | Provider key list | `listKeys` |
| `setLockState(vehicle, locked)` | `SetLockState` | `lockControl` |
| `setEngineState(vehicle, enabled)` | `SetEngineState` | `engineControl` |
| `getItemLabelSettings()` | `GetItemLabelSettings` | `customKeyLabels` |
| `getSavedItemLabel()` | `GetSavedItemLabel` | `customKeyLabels` |
| `setSavedItemLabel(label)` | `SetSavedItemLabel` | `customKeyLabels` |
| `getPersonalSettings()` | `GetPersonalSettings` | `personalSettings` |
| `setPersonalSetting(name, value)` | `SetPersonalSetting` | `personalSettings` |
| `playKeyFobSound()` | `PlayKeyFobSound` | `keyFobSound` |
| `getKeybinds()` | `GetKeybinds` | `keybinds` |

### Built-in provider adapters

| Provider | Client integration | Server integration |
|---|---|---|
| `zyke_vehiclekeys` | All client exports listed above | All server exports listed above |
| `qb-vehiclekeys` | Give event `vehiclekeys:client:SetOwner`, `HasKeys` export, remove event `qb-vehiclekeys:client:RemoveKeys`, and the provider key-list callback | `GiveKeys`, `HasKeys`, and `RemoveKeys` exports; key listing bridges through the client |
| `qbx_vehiclekeys` | `HasKeys` export with a live vehicle; give/remove unavailable | `GiveKeys`, `HasKeys`, and `RemoveKeys` exports with a live vehicle; key listing resolves the player's `keysList` state bag |
| `qs-vehiclekeys` | `GiveKeys`, `GetKey`, and `RemoveKeys` exports with plate/model | Server requests bridge to those client exports; key listing reads `vehiclekeys` item metadata |
| `wasabi_carlock` | `GiveKey`, `HasKey`, `RemoveKey`, and `GetAllKeys` exports | Give/has/remove use server exports; key listing bridges through the client |
| `Renewed-Vehiclekeys` | `addKey`, `hasKey`, and `removeKey` exports; `setLockState` sets the `vehicleLock` state bag on vehicles the client owns | `addKey`, `hasKey`, and `removeKey` exports; temporary keys are permanent and key listing is unavailable |

Renewed-Vehiclekeys is supported with its default identifier keys; its `useKeyItem` item-key mode is not supported. Qbox and Quasar require a live vehicle for the operations marked above. Check `requiresVehicle` and `serverAuthoritative` before calling a provider outside a normal streamed-vehicle flow. Capability-only metadata such as `identifierAccess`, `itemAccess`, `liveMenu`, and `actionMaxDistance` is returned unchanged by `getCapabilities()`.

### Adding a provider

Vehicle-key integrations use direct system checks rather than a provider registry or export-name map. Add the resource name to `systems/vehicleKeys.lua` when it should be auto-detected, then add direct branches for its supported methods in `functions/vehicleKeys/client.lua` and `functions/vehicleKeys/server.lua`. Each branch owns its real export or event name, execution side, arguments, and return conversion in one place.

An exact `vehicleKeys` override does not need to appear in the auto-detection list, but every supported operation still needs an explicit system branch. Unknown systems fall through to the method's false, nil, zero, or empty-table default; there is no generic export contract.

This table describes outbound `zyke_lib` dispatch. Incoming QB/QBX/QS/Wasabi compatibility exports and events are separate adapters owned by `zyke_vehiclekeys`.

Vehicle-key state is read from the active provider through `getAccessiblePlates`; `zyke_lib` does not synthesize a mutation event because direct provider exports cannot be intercepted reliably.

## HUD Visibility

`Z.hud.toggle(visible)`, `Z.hud.hide()`, and `Z.hud.show()` control the detected external HUD. When no external HUD is selected, they control the native GTA HUD and radar instead. `Z.hud.get()` returns the current visibility when it can be determined reliably, otherwise it returns `nil`.

A getter is not required to control a HUD. When available, it provides a better experience by letting `zyke_lib` avoid changing a HUD whose visibility already matches the requested state. The native fallback returns `nil` when the HUD and radar have different visibility states so the next toggle can synchronize both.

| HUD resource | Visibility integration | Getter |
|---|---|---|
| None selected | `DisplayHud(visible)` / `DisplayRadar(visible)` | `IsHudHidden()` / `IsRadarHidden()` |
| `jg-hud` | `toggleHud(visible)` | — |
| `esx_hud` | `HudToggle(visible)` | — |
| `wais-hudv6` | `showHud()` / `hideHud()` | — |
| `0r-hud-v3` | `ToggleVisible(visible)` | — |
| `17mov_Hud` | `ToggleDisplay(visible)` | — |
| `izzy-hudv5` | `setDisplay(visible)` | — |
| `izzy-hudv6` | `setDisplay(visible)` | — |
| `izzy-hudv7` | `showHUD()` / `hideHUD()` | — |
| `vms_hud` | `Display(visible)` | — |
| `rhud` | `set_visible(visible)` | `get_visible()` |
| `envi-hud` | `ToggleHUD(visible)` | — |
| `cx-hud` | `showHud()` / `hideHud()` | — |
| `tgiann-lumihud` | `tgiann-lumihud:ui` event | — |
| `hex_4_hud` | `HideHud(not visible)` | — |
| `minimal-hud` | `toggleHud(visible)` | — |
| `tgg-hud` | `ToggleHud(visible)` | — |
| `sync-hud` | `ToggleHUD(visible)` | — |
| `hex_hud_prem` | `HideHud(not visible)` | — |
| `bablo-hud` | `ShowHud()` / `HideHud()` | `IsHudVisible()` |

## Loader

This is an experimental approach to simplify the setup process for all of our products. Utilizing this loader, it is ensured that **all** dependenciesa are properly loaded before we allow the scripts to be started. This is essentially expanding on the default "dependency" fxmanifest.lua section that often fails due to timing issues in certain cases. This loader may be niche, but there are a lot of servers that will benefit from a simplified setup when installing our resources.

Instead of specifying inside of client_scripts {...} and so on, we specify the path inside of loader {...}, where it automatically fetches the context or allows you to prefix with context:path.

Unfortunately it seems that wildcards (using stars to start entire folders) are not suitible to be used at the moment.

This is most likely going to be expanded on and simplified in the future, but is a working proof of concept that will be implemented into all of our resources to make installations easier.

**Example from zyke_vending:**

```lua
shared_scripts {
	-- We import our imports.lua file from zyke_lib, which will ensure our entire resource along with it's dependencies
	"@zyke_lib/imports.lua",
}

files {
	-- Not related to the loader, but we specify our translations here too
	"locales/*.lua",

	-- Specify our client-sided files so they can be found, required by Cfx
	"shared/*.lua",
	"client/*.lua",
}

-- Specify all of the files loading & their order
loader {
	"shared/config.lua",

	"client/main.lua",
	"client/debug.lua",

	"server/main.lua",
	"server/validate_items.lua"

	-- This is not used in this particular resource, but we can specifically ensure context by doing this:
	-- "shared:main.lua"
	-- "server:main.lua"
	-- "client:main.lua"
}

-- Specify all the dependencies we will be waiting for
dependencies {
	"zyke_lib"
}
```

## Links

-   [Documentation](https://docs.zykeresources.com/free-resources/zyke-lib)
-   [Discord Community](https://discord.zykeresources.com)
-   [Store](https://zykeresources.com/)

## Credits

-   Credits to the [Overextended team](https://github.com/overextended/ox_lib) for the module structure of importing and executing functions.
-   Credits to all of the [contributors](https://github.com/ZykeWasTaken/zyke_lib/graphs/contributors) making pull requests & our amazing community that share snippets in our Discord for me to add here.
