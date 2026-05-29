# Context Menu

The context menu system provides a corner-positioned panel with selectable options. It supports three interaction modes, sub-menu navigation, inventory images, and metadata popouts on hover. All functions are blocking — the calling thread yields until the player selects an option or closes the menu.

## Quick Start

```lua
local result = Z.openContext({
    title = "Shop",
    icon = "cart",
    options = {
        { title = "Iron Ore", description = "{amount}x = ${amount * price}", amount = { default = 1, min = 1, max = 10, vars = { price = 50 } }, image = Z.getInventoryImagePath("iron_ore") },
        { title = "Coal", description = "{amount}x = ${amount * price}", amount = { default = 1, min = 1, max = 10, vars = { price = 30 } }, image = Z.getInventoryImagePath("coal") },
    },
})
```

---

## API

### `Z.openContext(data)`

Opens a context menu directly from a table. Blocks until the player selects an option or closes the menu. Returns the selected option's `args`, `value`, or `true` on select. Returns `nil` if cancelled.

```lua
local result = Z.openContext({
    id = "my_menu",
    title = "My Menu",
    options = { ... },
})
```

- `data` (ContextMenuData, required) -- menu definition (see [Menu Data](#menu-data)).

---

### `Z.registerContext(context)`

Registers one or more context menus by ID so they can be opened later with `Z.showContext()` or used as a sub-menu target. Does not open the menu.

```lua
Z.registerContext({
    id = "sub_weapons",
    title = "Weapons",
    options = { ... },
})
```

- `context` (ContextMenuData, required) -- menu definition with a unique `id`.
- `context[]` (ContextMenuData[], optional) -- ox-style array of menu definitions to register in one call.

---

### `Z.showContext(id)`

Opens a previously registered context menu by ID. Blocks until closed. Returns the same as `Z.openContext`.

```lua
Z.registerContext({ id = "shop", title = "Shop", options = { ... } })
local result = Z.showContext("shop")
```

- `id` (string, required) -- the ID passed to `Z.registerContext`.

---

### `Z.hideContext([runOnExit])`

Soft-closes the active context menu. Resolves the pending promise as `nil`. By default runs the `onExit` callback.

- `runOnExit` (boolean, default `true`) -- whether to fire the menu's `onExit` callback.

---

### `Z.closeContext()`

Closes the active context menu. Always runs the `onExit` callback. Resolves the pending promise as `nil`.

---

### `Z.isContextOpen()`

Returns `boolean` -- whether a context menu is currently open.

---

### `Z.getOpenContextMenu()`

Returns `string|nil` -- the ID of the currently open context menu, or `nil` if none.

---

## Menu Data

The `ContextMenuData` table defines the menu's appearance and behaviour.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | string | no | Unique identifier. Auto-generated if omitted. |
| `title` | string | yes | Header title. |
| `description` | string | no | Subtitle below the header. |
| `icon` | string | no | Header icon name (see [Icons](#icons)). |
| `position` | string | no | Corner position: `"top-left"`, `"top-right"`, `"bottom-left"`, `"bottom-right"`. Default `"top-right"`. |
| `mode` | string | no | Interaction mode: `"action"`, `"select"`, `"multiselect"`. Default `"action"`. |
| `canClose` | boolean | no | Whether the player can close the menu. Default `true`. |
| `hints` | string \| table | no | Optional footer hint, or array of hints, shown bottom-right. |
| `menu` | string | no | Parent menu ID for back navigation. |
| `onExit` | function | no | Callback fired when the menu closes. |
| `onBack` | function | no | Callback fired when the player presses back. |
| `options` | table[] | yes | Array of option definitions. |

---

### Footer Hints

The `hints` field shows small helper text in the footer, on the right side of the close instruction. It can be a single string or an array of strings.

```lua
Z.openContext({
    title = "Shop",
    icon = "cart",
    hints = {
        "Scroll over an item to change quantity",
        "Shift + scroll changes quantity faster",
    },
    options = { ... },
})
```

When multiple hints are provided, they rotate automatically. The display time scales with the hint length so longer hints stay visible longer. If a hint is too long for the available footer space, it waits briefly, then slowly pans so the full text can be read.

---

## Options

Each entry in the `options` array is a `ContextOption` table.

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | yes | Option label. |
| `description` | string | no | Secondary text below the title. |
| `icon` | string | no | Icon name (see [Icons](#icons)). |
| `iconColor` | string | no | CSS color for the icon. |
| `image` | string | no | Image URL (e.g. from `Z.getInventoryImagePath`). Takes priority over `icon`. |
| `disabled` | boolean | no | Greys out the option and prevents interaction. |
| `readOnly` | boolean | no | Prevents selection/navigation while keeping normal text, icon, hover, and metadata styling. |
| `menu` | string \| table | no | Registered menu ID or inline `ContextMenuData` for sub-menu navigation. |
| `onSelect` | function | no | Callback fired when the option is selected. Receives `args` and `amount` (if an amount tracker is set). |
| `event` | string | no | Client event to trigger on select. |
| `serverEvent` | string | no | Server event to trigger on select. |
| `args` | any | no | Data forwarded to `onSelect`, `event`, or `serverEvent`. |
| `value` | any | no | Value returned by `openContext` / `showContext` when this option is selected (used in `select` / `multiselect` modes). |
| `arrow` | boolean | no | Force-show or hide the navigation arrow. Auto-shown when `menu` is set. |
| `metadata` | table[] | no | Array of metadata entries shown in the hover popout. |
| `progress` | number | no | Progress bar value (0--100) rendered below the title. |
| `colorScheme` | string | no | CSS variable name for the progress bar colour (e.g. `"blue1"`). |
| `amount` | table | no | Scrollable amount tracker. See [Amount Tracker](#amount-tracker). |

---

### Metadata

Options with a `metadata` array show a hover popout panel with label/value pairs.

```lua
{
    title = "Iron Sword",
    description = "A sturdy blade",
    icon = "build",
    metadata = {
        { label = "Damage", value = "24" },
        { label = "Durability", value = "85%", progress = 85, colorScheme = "green1" },
        { label = "Weight", value = "3.2 kg" },
    },
}
```

Each metadata entry:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `label` | string | yes | Label text. |
| `value` | any | yes | Value text (converted to string). |
| `progress` | number | no | Progress bar value (0--100). |
| `colorScheme` | string | no | Progress bar colour variable name. |

---

### Inventory Images

Use `Z.getInventoryImagePath(itemName)` to resolve an inventory item image URL. When provided, the image renders in both the option row and the hover popout.

```lua
{
    title = "Iron Ore",
    description = "A chunk of raw iron",
    image = Z.getInventoryImagePath("iron_ore"),
}
```

If the image fails to load, the option falls back to a placeholder icon. Invalid images are cached so the popout does not flicker on repeated hovers.

---

## Amount Tracker

Options can have a scrollable amount value that updates in real-time. The player scrolls their mouse wheel over the option to increase or decrease the amount. Holding **Shift** multiplies the step by 5.

Any string field on the option (`title`, `description`, `metadata[].label`, `metadata[].value`) can use template expressions enclosed in `{}`. The special keyword `{amount}` resolves to the current value, and custom variables can be used for arithmetic.

### Amount Config

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `default` | number | no | Starting value. Default `1`. |
| `min` | number | no | Minimum value. Default `1`. |
| `max` | number | yes | Maximum value. |
| `step` | number | no | Increment per scroll tick. Default `1`. |
| `vars` | table | no | Named number variables accessible in templates (e.g. `{ price = 30 }`). |

### Template Syntax

Expressions inside `{}` are evaluated as simple arithmetic. Available tokens:

- `amount` -- the current amount value
- Any key from `vars` -- the corresponding number

Supported operators: `+`, `-`, `*`, `/`, parentheses.

```lua
-- Static string (no template):
description = "Price: $50"

-- With template:
description = "{amount}x = ${amount * price}"
-- amount=1, price=50 → "1x = $50"
-- amount=3, price=50 → "3x = $150"
```

### Basic Example

```lua
Z.openContext({
    title = "Shop",
    icon = "cart",
    options = {
        {
            title = "Iron Ore",
            description = "{amount}x = ${amount * price}",
            image = Z.getInventoryImagePath("iron_ore"),
            amount = {
                default = 1,
                min = 1,
                max = 10,
                vars = { price = 50 },
            },
            onSelect = function(args, amount)
                print("Bought " .. amount .. "x Iron Ore for $" .. (amount * 50))
            end,
        },
    },
})
```

### With Metadata Templates

Metadata `label` and `value` fields also support templates:

```lua
{
    title = "Iron Ore",
    description = "Scroll to change quantity",
    amount = { default = 1, min = 1, max = 20, vars = { price = 50, weight = 0.5 } },
    metadata = {
        { label = "Total Cost", value = "${amount * price}" },
        { label = "Total Weight", value = "{amount * weight} kg" },
    },
}
```

### Receiving the Amount

When the player selects an option with an amount tracker, the current amount is:

1. Passed as the second argument to `onSelect(args, amount)`
2. Included in the promise result as `.amount`

```lua
-- Using onSelect callback:
{
    title = "Buy",
    amount = { default = 1, min = 1, max = 10, vars = { price = 50 } },
    description = "{amount}x = ${amount * price}",
    onSelect = function(args, amount)
        local total = amount * 50
        Z.callback.await("my_resource:Purchase", "iron_ore", amount)
    end,
}

-- Using the promise result:
local result = Z.openContext({
    title = "Buy",
    options = {
        {
            title = "Iron Ore",
            args = { name = "iron_ore" },
            amount = { default = 1, min = 1, max = 10, vars = { price = 50 } },
            description = "{amount}x = ${amount * price}",
        },
    },
})
-- result = { name = "iron_ore", amount = 3 }
```

A small scroll wheel icon appears on the right side of options that have an amount tracker, indicating the option is scrollable.

---

## Modes

### action (default)

Clicking an option immediately fires its callbacks and closes the menu. The promise resolves with `args`, `value`, or `true`.

```lua
local result = Z.openContext({
    title = "Quick Actions",
    options = {
        { title = "Eat", icon = "info", onSelect = function() print("ate") end },
        { title = "Drink", icon = "info", onSelect = function() print("drank") end },
    },
})
```

---

### select (radio)

Clicking an option highlights it. The player must press **Confirm** to submit. The promise resolves with an array of selected values.

```lua
local selected = Z.openContext({
    title = "Choose a Weapon",
    mode = "select",
    options = {
        { title = "Sword", value = "sword" },
        { title = "Axe", value = "axe" },
        { title = "Bow", value = "bow" },
    },
})
-- selected = { "sword" }
```

---

### multiselect (checkbox)

Clicking toggles selection on/off. Multiple options can be selected. The promise resolves with an array of all selected values.

```lua
local selected = Z.openContext({
    title = "Buy Materials",
    mode = "multiselect",
    options = {
        { title = "Iron Ore", value = "iron" },
        { title = "Coal", value = "coal" },
        { title = "Limestone", value = "limestone" },
    },
})
-- selected = { "iron", "coal" }
```

---

## Sub-menus

Options can navigate to sub-menus. Set `menu` to a registered menu ID or an inline table. A back arrow appears automatically, allowing the player to return to the parent.

```lua
Z.registerContext({
    id = "main_shop",
    title = "Shop",
    options = {
        { title = "Weapons", menu = "sub_weapons" },
        { title = "Materials", menu = "sub_materials" },
    },
})

Z.registerContext({
    id = "sub_weapons",
    title = "Weapons",
    menu = "main_shop",
    options = {
        { title = "Iron Sword", onSelect = function() end },
        { title = "Steel Axe", onSelect = function() end },
    },
})

Z.registerContext({
    id = "sub_materials",
    title = "Materials",
    menu = "main_shop",
    options = {
        { title = "Iron Ore", onSelect = function() end },
    },
})

Z.showContext("main_shop")
```

The `menu` field on sub-menus points back to the parent, enabling the back button to navigate up. Inline menus are also supported:

```lua
Z.openContext({
    title = "Main",
    options = {
        {
            title = "Sub Menu",
            menu = {
                title = "Sub Options",
                options = {
                    { title = "Option A", onSelect = function() end },
                },
            },
        },
    },
})
```

---

## Icons

Icons can be specified by name as a string on any `icon` field. Resolution works in two layers:

1. **Icon Registry** -- SVG icons from MUI and react-icons. These render as crisp vector graphics.
2. **Material Icons** (fallback) -- if the name is not found in the registry, it is treated as a [Material Icons](https://fonts.google.com/icons) font name.

See the [Forms docs icon table](forms.md#registry-icons) for the full list of registry icons.

---

## Full Example

```lua
local function openVendorMenu(vendorIndex, vendorConfig)
    local options = {}

    for i = 1, #vendorConfig.items do
        local item = vendorConfig.items[i]

        options[#options + 1] = {
            title = item.label or item.name,
            description = "{amount}x = ${amount * price}",
            image = Z.getInventoryImagePath(item.name),
            amount = {
                default = 1,
                min = 1,
                max = 10,
                vars = { price = item.price },
            },
            onSelect = function(_, amount)
                local qty = amount or 1
                local totalPrice = qty * item.price
                local success, err = Z.callback.await("my_resource:Purchase", vendorIndex, item.name, qty)

                if success then
                    Z.notify("Purchased %sx %s for $%s", { qty, item.label or item.name, totalPrice })
                elseif err then
                    Z.notify(err)
                end
            end,
        }
    end

    Z.openContext({
        id = "vendor_" .. vendorIndex,
        title = vendorConfig.label,
        icon = "cart",
        options = options,
    })
end
```
