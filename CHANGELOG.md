# Changelog

## [1.2.1] — 2026-07-07

### Added
- Morale bar staleness gradient: bar stays green for 5 s after the last morale update, then fades to gray over the following 10 s, and locks on gray at 15 s — giving a visual indication that the displayed value may be stale (morale only updates when someone in the group has the entity targeted)

## [1.2.0] — 2026-06-27

### Added
- Morale bar row on each tracker card: shows a live `XX%` label and a proportional green fill bar, updated every game tick via `entity:GetMorale()` / `entity:GetMaxMorale()`; toggled by "show morale bar" checkbox in Combat tracking options
- Morale bar appears as a dedicated row below the CC timer bar (or directly below the name area when CC timers are disabled); total card height expands to accommodate it
- Morale bar is hidden automatically for entities that do not expose morale (e.g. items); visibility is determined each tick from live data rather than shown unconditionally
- Targeted highlight color is now configurable in the Appearance section alongside the player/NPC/item colors (default yellow)

### Changed
- Tracker card outer size now always includes `tooltip_spacing` on both the bottom and right, so the gap between cards is equal in both directions regardless of fill mode
- 2 px gap added between the CC skill icon and the duration bar
- Fixed tracker cards being clipped on the right in vertical fill mode by widening the window and listbox to match item width

## [1.1.2] — 2026-06-26

### Added
- Configurable CC duration bar height (`duration_bar_height`, default 20 px) — set in Combat tracking options and applied via the "apply" button
- When "show CC timers" is enabled, the bar height is added as dedicated space below the tracker card name area, so the bar is never clipped

### Changed
- Duration bar now has a 2 px gap between itself and the bottom card border
- Countdown label font reduced from Verdana 14 to Verdana 12 to better fit smaller bar heights

## [1.1.1] — 2026-06-24

### Added
- Configurable background colors for player, NPC, and item tracker cards (RGB 0–255 inputs with "apply colors" button)
- CC warning threshold setting — duration bar turns red when time remaining falls below the configured value (default 5 s)
- Auto-remove defeated delay — tracker cards are removed automatically a configurable number of seconds after defeat (0 = disabled)
- "Only clear defeated" option for the clear keybinding — limits the clear action to defeated trackers only

### Changed
- Keybinding capture now uses a full-screen overlay dialog instead of blocking in-place
- Tracker layout settings (width, height, spacing, max count) and combat settings now require an explicit "apply" click rather than taking effect on each keystroke
- Options panel reorganized into labeled sections: Position, Layout, Tooltip size, Keybindings, Combat tracking, Appearance

## [1.1.0] — 2026-06-24

### Added
- Horizontal fill mode — trackers grow left-to-right instead of top-to-bottom
- Reverse fill order option
- CC duration timers: shrinking progress bar, skill icon, and countdown label overlaid on the tracker card
- Support for Mariner Thrum of the Sea (25 s) and LM Sign of Power: Righteousness (15 s) in addition to existing CC skills
- `_G.ShowAnchor()` helper exposed for drag-handle toggle from the options panel

### Changed
- `PotatoTooltip:Update()` now also handles the defeat auto-remove countdown so a single update loop covers both CC timers and defeat delays
- Settings fall back from character scope to account scope on first load

## [1.0.0] — 2026-06-24

Initial release.

### Features
- Floating HUD window (`PotatoWindow`) with a scrollable list of pinned tracker cards
- Per-target tracker cards (`PotatoTooltip`) showing entity portrait, name, and a close button
- Entity type detection (player / NPC / item) with distinct background colors
- Targeted highlight (yellow) and defeat highlight (gray) driven by combat log and target-change events
- CC duration tracking for Lore-master Blinding Flash (30 s), Burglar Riddle (30 s), and Hunter Distracting Shot (35 s)
- Keybinding assignment for add-tracker and clear-trackers actions
- Settings persisted via `Turbine.PluginData` at character and account scope
- Options panel registered with the Plugin Manager
- Alphabetical sort mode
