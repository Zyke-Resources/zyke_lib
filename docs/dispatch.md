# Dispatch

The dispatch bridge sends a police alert, such as a store robbery or an alarm, through whichever dispatch resource the server runs. When none runs, the on-duty players of the alert's jobs get a notification and a temporary map blip instead, so an alert is never lost.

## Quick Start

```lua
-- Server, from a thread or handler
local taken = Z.sendDispatchAlert({
    coords = vector3(25.7, -1347.3, 29.5),
    title = "Store robbery",
    code = "10-90",
    description = "The clerk is being held at gunpoint",
    blip = {sprite = 52, colour = 1, radius = 40.0, duration = 300},
    priority = 1,
})

if (not taken) then
    print("No dispatch resource took the alert, the fallback was sent instead")
end
```

List `"dispatch"` in the resource's `zyke_systems`.

---

## Setup

Detection is automatic. To pin a dispatch or disable the bridge, set `dispatch` in `dependency_override.lua`:

- `"auto"` (default) -- use the first running dispatch in the order below.
- `"<resource name>"` -- use only that dispatch.
- `"none"` -- skip dispatches and always send the fallback.

Dispatches are never waited for at startup. The bridge follows dispatch resources as they start and stop, so a dispatch started later takes over, and the next one (or the fallback) takes over when it stops.

Auto-detection order: `cd_dispatch3d`, `ps-dispatch`, `cd_dispatch`, `qs-dispatch`, `rcore_dispatch`, `core_dispatch`, `tk_dispatch`, `codem-dispatchv2`, `lb-tablet`.

- `cd_dispatch3d` comes first because it also answers the alerts of the dispatches it replaces (ps-dispatch, cd_dispatch, lb-tablet, rcore_dispatch).
- `lb-tablet` comes last because servers often run it for its other apps beside another dispatch.

---

## API

### `Z.sendDispatchAlert(data)` (server)

Sends an alert. Returns `true` when a dispatch resource took it, `false` when the fallback was sent instead. May yield through the dispatch's exports, so call it from a thread or handler.

- `data` (DispatchAlert, required):

| Field | Type | Default | Meaning |
|---|---|---|---|
| `coords` | vector3 | required | Where it happened |
| `title` | string | required | Short, such as `"Store robbery"` |
| `code` | string | none | Such as `"10-90"` |
| `description` | string | none | The longer text officers read |
| `jobs` | string[] | the police jobs | Jobs that receive the alert |
| `blip` | table | see below | The map blip |
| `priority` | integer | none (normal) | `1` is the highest |
| `sound` | boolean | `true` | `false` asks for a silent alert |

`blip` fields:

| Field | Type | Default | Meaning |
|---|---|---|---|
| `sprite` | integer | `161` | Blip sprite ID |
| `colour` | integer | `1` (red) | Blip colour ID |
| `scale` | number | `1.2` | Blip size |
| `radius` | number | none | Metres, adds a radius blip |
| `duration` | integer | `300` | Seconds the blip stays on the map |
| `flash` | boolean | `false` | Makes the blip flash |

The police jobs are every job whose type is `"leo"` on QBCore and Qbox. ESX jobs have no type, so there they are `police` and `sheriff`, whichever exist. Pass `jobs` when the server uses other job names.

When the dispatch resource throws an error or refuses the alert (lb-tablet when no MDT takes any of the jobs, codem-dispatchv2 when it returns `false`), the fallback is sent and the result is `false`.

---

## Fallback

With `dispatch = "none"`, when no supported dispatch runs, or when the dispatch refuses the alert, every player on one of the `jobs` gets:

- a notification through zyke_lib's notification system, in that player's language, with the code, title and description;
- a blip at `coords` with the `blip` settings, plus the radius blip when `radius` is set, removed after `duration` seconds;
- the GTA alert sound unless `sound = false`.

Players whose job is off duty are skipped. ESX jobs without a duty state count as on duty.

---

## Support

| Dispatch | How the alert is sent | Notes | Source |
|---|---|---|---|
| ps-dispatch | Client export `CustomAlert`, sent from the player closest to `coords` | See below | source on GitHub (3.0.0, Aug 2026) |
| cd_dispatch3d | Server event `cd_dispatch:AddNotification` | | official docs |
| cd_dispatch | Client event `cd_dispatch:AddNotification` sent to every client, each keeps it when its job is in the list | | official docs |
| qs-dispatch | Server event `qs-dispatch:server:CreateDispatchCall` | Each job must also be in its `Config.JobsAllowed`. No radius blip | official docs (Nov 2026) |
| rcore_dispatch | Server event `rcore_dispatch:server:sendAlert` | Title and description are joined into its single text | official docs |
| core_dispatch | Server export `addCall` | The description becomes an extra info row. No radius blip or sound setting | official docs |
| tk_dispatch | Server export `addCall` | Jobs must be in its `Config.Dispatch` | official docs |
| codem-dispatchv2 | Server export `SendDispatchAlert` | Title and description are joined into its single text | official docs |
| lb-tablet | Server export `AddDispatch` | Jobs reach every MDT whose default permissions hold them. The location label is the title | official docs |

### ps-dispatch

ps-dispatch makes a call for a whole job only through its client export `CustomAlert`, which also reads the street name on that client. Its server event takes alerts from clients only, and its server export `SendTargetedAlert` only reaches named players and only exists in newer versions. So the bridge sends the alert to the online player closest to `coords` (in a robbery, usually the robber), and zyke_lib's client hands it to `CustomAlert` there. That player sees nothing; the call shows only for the jobs in `jobs`.

- `sound` is ignored: ps-dispatch plays its alert sound for every call. Officers mute it in its settings.
- `priority = 1` shows as its red priority call, anything else as a normal call.
- When nobody is online the alert has no client to go through, the fallback is sent and the result is `false`.

### Units the dispatches leave undocumented

The bridge passes `blip.duration` in the unit each dispatch documents: minutes for ps-dispatch, cd_dispatch and codem-dispatchv2 (rounded up to whole minutes for the last two), milliseconds for qs-dispatch, core_dispatch and tk_dispatch, and seconds for rcore_dispatch. lb-tablet's `time` has no documented unit and is given in seconds. Check these against the real resource once it is tested on a server.
