# Changelog

## [2.0.0] — 2026-07-31

A complete visual redesign of the plugin.

### Added
- The options panel has been rebuilt around five tabs — Layout, Keybindings, Combat, CC timers and Appearance — and no longer scrolls. Each tab has its own Apply and Reset.
- Two ready-made tracker sizes, Comfortable and Compact, alongside the custom width and height you could already set.
- The close button on each tracker can be turned off, if you would rather clear trackers with the keybinding and keep the card clear.
- Keybindings now show the actual key, such as "Ctrl + J", instead of a number.
- Rebinding a key happens inside the options panel instead of taking over the whole screen.
- Numbers are set with minus and plus buttons you can hold down, rather than typed into a box.
- Custom CC skills only take up space once you have added them, and each one has a button to remove it.
- Colours can be picked from a row of presets or set to an exact value.
- The tracker background is one of those colours. Hovered, targeted, defeated and CC-warning cards shade themselves from whichever background you pick, and the text on a card darkens by itself if you choose a light one.
- Live previews on the Layout, Combat and Appearance tabs, so you can see a setting take effect without closing the panel.

### Changed
- Trackers have a new look: a dark card with a coloured stripe down the left edge showing what you are tracking, instead of the whole card being tinted.
- Cards are a fixed height. Turning the CC timer or morale bar on no longer makes your HUD grow or shift.
- A small line under the name says whether the target is an NPC, a fellowship member or an object, and reads "YOUR TARGET" when it is your current target.
- Defeated targets are struck through and marked "DEFEATED" rather than only dimmed.
- The close button is a small red square in the top-right corner that appears when you hover over a card, so it no longer sits over the name, the timer or the morale figure.
- The drag handle is a small strip above the trackers, and can be hidden once you are happy with the position.
- Trackers sit closer together by default.
- Morale that has stopped updating fades to grey after five seconds and stays there, instead of fading gradually over fifteen.
- Colours you had set in an earlier version are reset once to the new palette, since the old ones were picked for the old look.

### Removed
- The CC bar height setting. The bars are now part of the card's fixed height.

## [1.3.0] — 2026-07-17

### Added
- Per-skill CC timer configuration in the options panel: each built-in skill (Blinding Flash, Riddle, Distracting Shot, Thrum of the Sea, SoP: Righteousness) can now be individually enabled/disabled and have its duration overridden
- Five custom CC skill slots: enter any skill name as it appears in the combat log, set a duration, and optionally supply a custom icon ID — matched against the `hit with <skill> on` pattern
- `cc_skills` and `cc_custom_skills` settings tables persisted via `Turbine.PluginData`

### Changed
- Options panel height expanded to accommodate the new CC Timers section
- "Show CC timers" checkbox moved into its own labeled "CC Timers" section
- Defeat auto-remove delay field and its "apply" button moved to the Combat tracking section; CC bar height and warning threshold now have a separate "apply" button

## [1.2.2] — 2026-07-17

### Fixed
- Window and listbox height now accounts for CC timer bar and morale bar rows; previously only `tooltip_height` was used, causing trackers to be clipped when either bar was enabled
- "Index out of range" error when auto-remove defeated delay is > 0; `RemoveTooltip` now guards against removing a tooltip that is no longer in the listbox (e.g. removed by a concurrent tick or the clear-dead keybinding)

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
