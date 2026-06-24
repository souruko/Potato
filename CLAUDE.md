# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Potato is a Lord of the Rings Online (LotRO) plugin written in Lua using the game's Turbine API. It provides a floating target-tracker HUD: players pin targets by keybinding, and the plugin displays their name, entity type coloring, CC duration timers, and defeat/target highlighting.

There is no build system, no test runner, and no package manager. The plugin is pure Lua loaded directly by the game engine.

## Two directories

- `/home/souru/lotro/documents_live/plugins/Potato` — the working dev copy (edit here)
- `/home/souru/.local/share/Steam/steamapps/compatdata/212500/pfx/drive_c/users/steamuser/Documents/The Lord of the Rings Online/plugins/Potato` — the path LotRO reads at runtime (inside the Wine prefix)

To test changes in-game, copy edited files from the dev path to the Steam path, then reload the plugin in-game with `/plugins reload Potato`.

## Architecture

**`Potato.plugin`** — XML manifest declaring the entry package (`Potato.main`) and configuration apartment.

**`main.lua`** — Entry point. Loads settings from `Turbine.PluginData` (character scope, falls back to account scope, then defaults). Defines the `_G.Settings` table and `_G.SaveSettings()`. Instantiates the two top-level globals: `Potato` (a `ui.PotatoWindow`) and `Options` (a `ui.OptionPanel`). Also registers `plugin.GetOptionsPanel` so the game shows the settings panel in the plugin manager.

**`chatParse.lua`** — Hooks `Turbine.Chat.Received`. Filters to `PlayerCombat` and `Death` chat types. For defeat events, calls `Potato:DefeatTooltip(name)`. For specific CC skills (Blinding Flash, Riddle, Distracting Shot, Thrum of the Sea, Sign of Power: Righteousness), calls `Potato:DisplayDuration(iconId, seconds, name)`. Uses `ParseCombatChat()` — a large pattern-matching function — to parse combat log text into typed event codes (1=damage, 3=heal, 9=defeat, 17=buff, etc.).

**`targetChanged.lua`** — Hooks `LocalPlayer.TargetChanged`. Calls `Potato:TargetChanged(name)` (or `nil`) on every target change.

**`ui/potatoWindow.lua`** — `PotatoWindow` (extends `Turbine.UI.Window`). Owns a `Turbine.UI.ListBox` of `PotatoTooltip` items. Handles key events for the add-tooltip and clear-dead-tooltips keybindings. `AddTooltip()` inspects the current target, determines entity type (player/item/NPC) by duck-typing the entity object and checking party membership, then adds a `PotatoTooltip`. Delegates `TargetChanged`, `DefeatTooltip`, `DisplayDuration`, and `ApplySettings` calls down to each tooltip. Supports horizontal layout via `SetMaxItemsPerLine` and `SetReverseFill`.

**`ui/potatoTooltip.lua`** — `PotatoTooltip` (extends `Turbine.UI.Control`). One tracker per pinned entity. Shows a frame, an `EntityControl` (game's built-in portrait), a name label, a close button, and optionally a CC duration icon + shrinking progress bar. `Update()` is called every game tick while a duration is active. Colors are driven by entity type and live/dead/targeted state from `_G.Settings`.

**`ui/optionPanel.lua`** — `OptionPanel` shown in the plugin manager. Controls sort mode, horizontal/reverse fill, dimensions, keybinding assignment (via a fullscreen overlay that captures a keypress), highlight-defeated, and display-durations toggles. All changes write immediately to `_G.Settings` and call `_G.SaveSettings()`.

## Turbine API notes

- `import "Turbine.X"` is the module system; `class(Base)` is the OOP helper.
- UI classes are instantiated by calling them directly: `Turbine.UI.Label()`.
- `self:SetWantsUpdates(true)` enables per-frame `Update()` callbacks; disable when not needed.
- `Turbine.Engine.GetGameTime()` returns elapsed game seconds — used for duration countdowns.
- Entity type detection is duck-typed: missing `GetLevel` means item, missing `GetAlignment` means player-like.
- `_G.Settings` colors (e.g. `tooltip_color_item`) are set fresh on every load in `main.lua` and are not persisted — they are constants, not user-configurable.
