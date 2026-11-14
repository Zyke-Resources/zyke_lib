# Contributing

Thanks for helping out. Most pull requests add support for another resource (an inventory, fuel, appearance, death system and so on). Following this page gets yours merged as it is, instead of rebuilt by us.

## Before You Start

- **One change per pull request.** One integration or one fix. A pull request that adds three integrations waits on the slowest one.
- **Work from the resource's official docs**, not from another library or an old version. Link the docs page for every export or event you use in the pull request description.
- **Check which side it runs on.** A client event can't be triggered from server code, and the reverse. The docs usually say; when they don't, say so in the pull request.
- **Adding a whole new category** (a kind of system zyke_lib doesn't detect yet)? Ask in our [Discord](https://discord.zykeresources.com) first, as it touches the loader.

## Adding Support for a Resource

The files for each category are listed under [Adding Compatibility](README.md#adding-compatibility) in the README. For a new resource in an existing category:

1. Add its resource name to the list in `systems/<category>.lua`. The order is the auto-detection order, so put it after any resource it provides or wraps.
2. Add its name to the `Options:` comment of that category in `dependency_override.lua`.
3. Add a branch for it in each function under `functions/` that the category uses, next to the existing ones:

    ```lua
    if (AppearanceSystem == "rcore_clothing") then
        TriggerEvent("rcore_clothing:openChangingRoom")

        return true
    end
    ```

4. Update the README where that function or category is documented.

Keep a value one resource needs (a unit, a fuel type, an event name) inside its own branch. Never change a shared default that every other resource also uses.

## Code Style

Match the file you are editing. The rules we see broken most:

- Four spaces, no tabs. No trailing whitespace, also on blank lines.
- Double quotes for strings.
- Parentheses around `if` and `while` conditions: `if (not ped) then return end`.
- Short guard clauses on one line, stacked without blank lines between them.
- A blank line before a `return` that follows other code, and after an `end` when more code follows.
- `local` variables and functions in `camelCase`.
- Lua files end right after the last character, with no final newline. Turn off "insert final newline" in your editor for these files.
- Inside zyke_lib, call other helpers through `Functions.*`. `Z.*` is what other resources use.
- Don't add a function that only passes its arguments on to another one.
- Use `pcall` only around a resource that may not be running at all, never to hide errors.

### LuaDoc and Comments

A new or changed function gets LuaDoc with types for its parameters and returns:

```lua
-- Opens the appearance resource's menu of the player's saved outfits
---@return boolean opened @ False when the appearance resource has no outfit menu to open
function Functions.appearance.openWardrobe()
```

- Optional parameters are marked on the name: `---@param amount? integer`, not `integer?`.
- Spaces around `|` in union types: `string | table`.
- Normal comments use two dashes; three dashes are for LuaDoc only.
- Comment on why, edge cases and FiveM quirks. Don't comment what the code already says.

### Text Players See

Notifications, labels, prompts and other player-facing text go through locale keys. Add the key to **every** file in `locales/` with a real translation for that language, not an English copy.

## Commits

- Subject in the form `type(context): message`, where the type is `feat`, `fix`, `chore` or `refactor`: `feat(appearance): open the rcore_clothing changing room as the wardrobe`.
- One commit per change. Squash "fix typo" commits before opening the pull request.
- Don't bump the version in `fxmanifest.lua`; we do that at release time.
- Run `git diff --check` before you commit; it catches trailing whitespace.

## The Pull Request

Write in the description:

- what it adds or fixes;
- the resource and the version you tested with, plus your framework;
- a link to the docs for each export or event you call;
- how you tested it in-game.

If something still needs a small change, we may fold it into our own commit instead of asking you. You are credited as co-author either way.
