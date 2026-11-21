# Phone

The phone bridge reads a character's phone number, finds the owner of a number, sends texts, hears texts sent to a number and reads and saves to a character's photo gallery through whichever phone resource the server runs. When no phone is running it falls back to the number the framework keeps (`charinfo.phone` on QBCore and Qbox, `users.phone_number` on ESX when a phone resource added that column).

zyke_lib never caches numbers. Many phones tie the number to the phone item or SIM card, so it changes when the player swaps phones and is `nil` while they carry none. Read it each time you need it, and cache it yourself for a short time if you read it often.

## Quick Start

```lua
-- Server, from a thread or handler
local phoneNumber, reason = Z.getPhoneNumber(source)
if (not phoneNumber) then
    print("No phone number:", reason)
    return
end

if (Z.canSendPhoneMessage()) then
    Z.sendPhoneMessage(source, "Your code is 4821", {number = "8255", name = "Messenger"})
end
```

---

## Setup

Detection is automatic. To pin a phone or disable the bridge, set `phone` in `dependency_override.lua`:

- `"auto"` (default) -- use the first running phone in the order below.
- `"<resource name>"` -- use only that phone.
- `"none"` -- skip phones and use the framework's number only.

Phones are never waited for at startup. The bridge follows phone resources as they start and stop, so a phone started later takes over, and the next one (or the framework) takes over when it stops.

Auto-detection order: `sd-phone`, `lb-phone`, `yseries`, `okokPhone`, `roadphone`, `gksphone`, `qs-smartphone-pro`, `qs-smartphone`, `high-phone`, `17mov_Phone`, `npwd`.

- `sd-phone` comes first because it `provide`s the names of the phones it imitates, which then report as started. Any provide alias is resolved to the real resource.
- `qs-smartphone` with `qs-base` running is treated as the legacy Quasar phone.
- `qb-phone` needs no entry. It uses the framework's `charinfo.phone`, which the fallback reads.

The SQL fallbacks run in the calling resource, so it must load `@oxmysql/lib/MySQL.lua`.

---

## API

All server methods may yield (phone exports and database reads). Call them from a thread or handler.

### `Z.getPhoneNumber(player)` (server)

Returns the character's phone number as the phone stores it, or `nil` and a reason.

```lua
local phoneNumber, reason = Z.getPhoneNumber(source)
local offlineNumber = Z.getPhoneNumber("char1:1a2b3c")
```

- `player` (PlayerId | CharacterIdentifier | Character, required) -- an online player, or the identifier of an online or offline character.

sd-phone assigns a number to an online character on first use, like opening the phone does. It never assigns one to an offline character.

When a phone is running but returns no number, the result is `nil, "noNumber"`. It does not fall back to the framework, whose number that phone does not use.

---

### `Z.getPhoneNumber()` (client)

Returns the local player's own number through a server callback. Same returns as the server version.

```lua
local phoneNumber, reason = Z.getPhoneNumber()
```

---

### `Z.getPhoneNumberOwner(phoneNumber)` (server)

Returns the identifier of the character that owns a number, its player id when online, or a reason.

```lua
local identifier, plyId, reason = Z.getPhoneNumberOwner("5551234567")
```

- `phoneNumber` (string, required) -- the number as `Z.getPhoneNumber` returned it. Most phones compare the exact stored string, so a reformatted number may not match. sd-phone accepts any formatting.

Offline owners are found through sd-phone, QBCore/Qbox and ESX `users.phone_number`. The other phones only find online owners and return `"offlineUnsupported"` on a miss.

---

### `Z.sendPhoneMessage(target, message, sender?)` (server)

Sends a text to a player's phone. Returns `true`, or `false` and a reason.

```lua
local sent, reason = Z.sendPhoneMessage(source, "Your code is 4821", {number = "8255", name = "Messenger"})
```

- `target` (PlayerId | CharacterIdentifier | Character | string, required) -- a player, or a number as `Z.getPhoneNumber` returned it. A string of digits and separators (`+`, spaces, `-`, brackets) is a number, any other string is an identifier. Prefer a player target, it avoids number format problems.
- `message` (string, required) -- the text.
- `sender` (PhoneMessageSender, optional) -- `{number?, name?}`. Defaults to `"0000"` and the calling resource's name. Use digits for `number`, sd-phone strips everything else. `name` is shown by phones that support a sender name.

---

### `Z.onPhoneMessage(phoneNumber, handler)` (server)

Calls `handler` each time a player texts `phoneNumber`. The number does not need an owner, so a resource can run its own contact, such as an informant who answers with `Z.sendPhoneMessage`. Texts are heard only while sd-phone or lb-phone runs. The handler stays registered while another phone runs, and hears texts again once a supported one starts.

```lua
Z.onPhoneMessage("5550199", function(message)
    if (not message.plyId) then return end

    Z.sendPhoneMessage(message.plyId, "Who is this?", {number = "5550199", name = "5550199"})
end)
```

- `phoneNumber` (string | number, required) -- compared with `Z.normalizePhoneNumber`. Use digits only, sd-phone strips everything else.
- `handler` (fun(message: IncomingPhoneMessage), required) -- may yield. `message` holds `from` and `to` (as the phone stores them), `message` (the text) and `plyId` (the sender, `nil` when they could not be found online).

Only plain texts from players reach the handler. Pictures, group texts and sd-phone's system texts (the ones `Z.sendPhoneMessage` sends) are skipped, so a reply never loops back. On lb-phone the sender is found through `Z.getPhoneNumberOwner`, since its event carries no player id.

---

### `Z.canSendPhoneMessage()` (server)

Returns whether the running phone can deliver a text, without sending anything. `false` when no phone is running.

---

### `Z.canUsePhonePhotos()` (server)

Returns whether the running phone's gallery can be read and saved to, so a resource can hide its phone photo features up front. `false` when no phone is running.

---

### `Z.getPhonePhotos(player, limit?)` (server)

Returns the photos and videos in the character's phone gallery, newest first, or `nil` and a reason.

```lua
local photos, reason = Z.getPhonePhotos(source)
if (not photos) then return end

for _, photo in ipairs(photos) do
    if (not photo.isVideo) then print(photo.id, photo.url, photo.takenAt) end
end
```

- `player` (PlayerId | Character, required) -- an online player.
- `limit` (integer, optional) -- at most 200, the default.

Each `PhonePhoto` holds `id` (the phone's own id), `url`, `isVideo`, `favorite` and `takenAt` (Unix seconds). The URL is wherever the phone hosts its media, such as Fivemanage or Zyke Media Studio, so show it as it is and never hand it to players who could not already see it.

The gallery belongs to the character, but the player has to carry a phone to reach it: without one the result is `nil, "noPhone"`.

---

### `Z.addPhonePhoto(player, url)` (server)

Saves an already hosted picture into the character's phone gallery. Returns the phone's id for the new photo, or `nil` and a reason.

```lua
local photoId, reason = Z.addPhonePhoto(source, "https://cdn.example.com/photo.webp")
```

- `player` (PlayerId | Character, required) -- an online player carrying a phone.
- `url` (string, required) -- an HTTPS URL. The phone stores and shows it as given, it never uploads it again.

sd-phone keeps at most `Photos.MaxPhotosPerPlayer` photos (200 by default) and drops the oldest past that, so saving many at once can push old photos out.

---

### `Z.onPhonePhotoChange(handler)` (server)

Calls `handler` each time a character's phone gallery gains or loses a photo, so an open view of the gallery can refresh.

```lua
Z.onPhonePhotoChange(function(change)
    if (not change.plyId) then return end

    print(change.plyId, change.change, change.id)
end)
```

- `handler` (fun(change: PhonePhotoChange), required) -- may yield. `change` holds `change` (`"added"` or `"removed"`), `id`, `url`, `identifier` (whose gallery) and `plyId` (`nil` when the owner is offline).

Photos taken, saved and deleted on the phone count, and so do saves through `Z.addPhonePhoto`. sd-phone fires no event for an accepted AirShare, so those are not heard.

---

### `Z.normalizePhoneNumber(phoneNumber)` (shared)

Returns the comparison key for a number: upper case with everything but letters and digits removed, or `nil` when nothing is left. Use it for account keys and comparisons, and keep the raw number for calls into the phone.

```lua
Z.normalizePhoneNumber("(555) 123-4567") -- "5551234567"
Z.normalizePhoneNumber("+49 764 9867") -- "497649867"
Z.normalizePhoneNumber("555-BUSINESS") -- "555BUSINESS"
```

Leading zeros and country codes are left alone, so `+1 555 123 4567` and `5551234567` stay different keys.

---

## Reasons

| Reason | Meaning |
|---|---|
| `invalidPlayer` | The input is not an online player or a known character identifier |
| `noPhoneSystem` | No phone is running and the framework keeps no number (plain ESX) |
| `noNumber` | The phone is running but the character has no number, usually no phone or SIM equipped. For owner lookups: nobody owns the number |
| `noPhone` | Gallery methods: the player carries no phone |
| `invalidUrl` | `Z.addPhonePhoto`: the URL is not an HTTPS string |
| `offlineUnsupported` | The character is offline and the phone has no offline read or lookup |
| `unsupported` | The phone can not do this |
| `failed` | The phone rejected the call or threw an error |

---

## Support

| Phone | Number | Offline number | Owner lookup | Texts | Hears texts | Gallery | Source |
|---|---|---|---|---|---|---|---|
| sd-phone | yes | yes | online & offline | yes, stored for offline players | yes | yes | local source (1.0.5) |
| lb-phone | yes | yes | online | yes | yes | no | official docs |
| yseries | yes | yes | online (primary phone only) | yes, the target number must exist | no | no | official docs |
| okokPhone | yes | no | online | yes | no | no | official docs |
| roadphone | yes (Pro by source, base by identifier) | yes | online | yes | no | no | official docs |
| gksphone | yes | no | online | yes, system message | no | no | official docs |
| qs-smartphone-pro | yes (by identifier) | yes | no | online players only, as an app | no | no | archived docs only |
| qs-smartphone (V3) | yes | no | no | online players only, as an app | no | no | official docs |
| qs-smartphone (legacy, with qs-base) | yes | no | no | no | no | no | archived docs only |
| high-phone | yes | no | online | yes | no | no | official docs, ownership model undocumented |
| npwd | yes | no | online | yes | no | no | source |
| 17mov_Phone | unsupported | unsupported | unsupported | unsupported | unsupported | unsupported | export signatures unverified |
| Framework (QBCore, Qbox) | `charinfo.phone` | yes | online & offline | no | no | no | source |
| Framework (ESX) | the `phoneNumber` player variable, else `users.phone_number` when the column exists | yes | online & offline | no | no | no | source |

lb-phone's docs do not say whether it fires its sent event for a number nobody owns, so test `Z.onPhoneMessage` on an lb-phone server before relying on it.

The gallery methods cover sd-phone only. The other phones were not checked for gallery exports yet, and return `"unsupported"`.

Phones known only from archived docs, or with undocumented behaviour, may need adjusting once tested against the real resource.