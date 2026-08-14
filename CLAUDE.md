# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Potato is a Lord of the Rings Online (LotRO) plugin written in Lua using the game's Turbine API. It provides floating target-tracker HUDs: players pin targets by keybinding, and the plugin displays their name, entity type coloring, CC duration timers, and defeat/target highlighting.

Since 2.1.0 there can be up to five independent windows (`_G.MAX_WINDOWS`), each with its own complete copy of the settings. Window 1 always exists and cannot be removed.

There is no build system, no test runner, and no package manager. The plugin is pure Lua loaded directly by the game engine.

## Where the code lives

One directory, reachable by two paths — `/home/souru/lotro/live_document_folder` is a **symlink** to
`/home/souru/.local/share/Steam/steamapps/compatdata/212500/pfx/drive_c/users/steamuser/Documents/The Lord of the Rings Online`
(the Wine prefix LotRO reads at runtime). Editing through either path edits the same file; there is no copy step.

To test changes, edit, then reload in-game with `/plugins reload Potato`.

## Design reference

`docs/redesign/` holds the 2.0 visual redesign material: `HANDOFF.md` (final colours, sizes and
copy), the two design canvases as HTML, and `PLAN.md` (the phase breakdown, since delivered — its
"Deviations" and "Open questions" sections still describe live behaviour). The handoff HTML is a
design reference, not code to port: everything is recreated with `Turbine.UI.Control` rectangles,
not HTML/CSS.

## Settings model

The single most important thing to know: **there is no single settings table.** `_G.Settings` is the
savefile, and the settings themselves live in `_G.Settings.windows[i]`, one entry per window:

```lua
_G.Settings = {
    colors_nocturne = true,               -- savefile-age migration flag, the only shared key
    windows = { { left = 500, ... }, ... },
}
```

Nothing outside `settings.lua`, `main.lua` and `optionPanel.lua`'s window helpers should touch
`_G.Settings` directly. A window reads `self.settings`; a tooltip reads `self.settings` (the same
table its parent window holds); the options panel reads `self:S()`.

A savefile from 2.x is flat — one window's worth of keys at the top level — and is lifted into
`windows[1]` on load. The migration moves *everything* except `colors_nocturne`, so a key nobody
remembers still ends up in the right place rather than stranded.

## Architecture

**`Potato.plugin`** — XML manifest declaring the entry package (`Potato.main`) and configuration apartment.

**`settings.lua`** — Everything about the savefile. The euro-client number-to-string converters, `_G.DeepCopySettings`, the character/account scope reads and writes, `_G.SaveSettings()` / `_G.SaveGlobalSettings()` / `_G.LoadGlobalSettings()` / `_G.HasGlobalSettings()`, and the defaults: `_G.NormaliseWindow(w)` fills in one window, `_G.NormaliseSettings()` runs the 2.x migration and then normalises every window. Account scope is the user-managed "global" copy driving the options panel's Global tab; `SaveSettings` only auto-writes account scope while no global copy existed at load time.

**`main.lua`** — Entry point. Loads and normalises the settings, then owns the window registry: `_G.PotatoWindows` (parallel to `_G.Settings.windows`), `_G.RebuildWindows()`, `_G.AddWindow(copyIndex)` and `_G.RemoveWindow(index)`. Instantiates `Options` (a `ui.OptionPanel`) and registers `plugin.GetOptionsPanel`.

**`chatParse.lua`** — Hooks `Turbine.Chat.Received`. Filters to `PlayerCombat` and `Death` chat types, parses the line at most once, then fans the result out to every window that wants it — each window has its own `highlight_defeated`, `display_durations`, `cc_skills` and `cc_custom_skills`. The five built-in CC skills live in a static `BUILTIN_CC` table. Uses `ParseCombatChat()` — a large pattern-matching function — to parse combat log text into typed event codes (1=damage, 3=heal, 9=defeat, 17=buff, etc.). Note the return shape differs by event: defeat is `(type, targetName)`, damage and buff are `(type, initiator, targetName, ...)`.

**`targetChanged.lua`** — Hooks `LocalPlayer.TargetChanged`. Calls `TargetChanged(name)` (or `nil`) on every window.

**`ui/potatoWindow.lua`** — `PotatoWindow(settings, index)` (extends `Turbine.UI.Window`). Owns a `Turbine.UI.ListBox` of `PotatoTooltip` items. `AddTooltip()` inspects the current target, determines entity type (player/item/NPC) by duck-typing the entity object and checking party membership, then adds a `PotatoTooltip`. Delegates `TargetChanged`, `DefeatTooltip`, `DisplayDuration` and `ApplySettings` down to each tooltip. Supports horizontal layout via `SetMaxItemsPerLine` and `SetReverseFill`. `Destroy()` tears the window down when it is removed or the list is rebuilt.

Only **window 1** has `SetWantsKeyEvents(true)`, and `PotatoWindow.KeyDown` (a dot, not a colon) is the plugin's single key handler: it walks `_G.PotatoWindows` and gives the press to **every** window whose own binding matches, without stopping at the first. Sharing a key between windows is a supported setup — one key that clears them all. A window given the same key for both pins with it, matching the order the two have always been checked in. Adding a listener per window instead would make it undefined which one the game delivers to.

**`ui/potatoTooltip.lua`** — `PotatoTooltip` (extends `Turbine.UI.Control`). One tracker per pinned entity. Shows a frame, an `EntityControl` (game's built-in portrait), a name label, a close button, and optionally a CC duration icon + shrinking progress bar. `Update()` is called every game tick while a duration is active. Colors are driven by entity type and live/dead/targeted state from `self.settings`. `Destroy()` stops updates and unbinds the entity's morale events — skipping it leaves a card firing for the rest of the session.

**`ui/theme.lua`** — Design tokens, plus the settings context. `CardMetrics`, `BaseColor`, `TargetColor` and `RailColor` are user settings, and everything derived from them (`CardFill`, `BorderColor`, `TrackColor`, `IsLightCard`, `Ink`, `NameColor`) is too — about 55 call sites. Rather than thread a settings table through all of them, the theme is told which window it answers for: **every method of `PotatoWindow` and `PotatoTooltip` that can be entered from outside the class calls `_G.Theme.Use(self.settings)` first**, and anything they call inherits it. `OptionPanel:RefreshPreviews` does the same for the window being edited. A new externally-reachable method that reads a colour and forgets this will render in another window's palette.

**`ui/optionPanel.lua`** — `OptionPanel` shown in the plugin manager. Six tabs plus a **Windows** list in the rail below them. `self.windowIndex` is the cursor; `self:S()` is the selected window's settings and `self:W()` its window — panes use those, never `_G.Settings`. `SelectWindow` moves the cursor and repaints; `AddWindowClicked` / `RemoveWindowConfirmed` wrap the `main.lua` lifecycle functions. Because the panel is built once and kept, switching window or loading the global copy calls `OptionPanel:RefreshFromSettings()`, which must be extended whenever a new control is added to a pane. `RebuildCustomRows` indexes `self.panes[4]` and `GLOBAL_TAB` is 6 — both break if a tab is added.

## Turbine API notes

- `import "Turbine.X"` is the module system; `class(Base)` is the OOP helper.
- UI classes are instantiated by calling them directly: `Turbine.UI.Label()`.
- `self:SetWantsUpdates(true)` enables per-frame `Update()` callbacks; disable when not needed.
- `Turbine.Engine.GetGameTime()` returns elapsed game seconds — used for duration countdowns.
- Entity type detection is duck-typed: missing `GetLevel` means item, missing `GetAlignment` means player-like.
- `Turbine.PluginData.Load` is only synchronous during plugin load; the account-scope copy is therefore read once and cached in `settings.lua`.
- German and French clients mangle numbers on save, so every number is written as a string and converted back on load. Any new nesting level in the savefile has to survive that round trip.

## Testing without the game

There is no test runner in the repo, but the plugin can be loaded outside the client against a
stubbed Turbine API — enough to catch load-time errors, migration bugs and the multi-window paths
before reloading in game. See the scratchpad harness pattern: stub `Turbine.Shell` / `PluginData` /
`UI`, substitute `class()` (the real `Class.lua` needs `getfenv`, which is Lua 5.1 only), and make
`import` a `dofile` that mirrors globals into the `ui` namespace.
