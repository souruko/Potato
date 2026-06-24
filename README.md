# Potato

A floating target-tracker HUD for Lord of the Rings Online. Pin targets by keybinding during combat and monitor their state — defeat, current target highlight, CC timers — at a glance.

## Features

- **Pin any target** with a configurable keybind; tracked entities persist until manually removed or cleared
- **Entity type coloring** — players, NPCs, and interactable items each get a distinct background color
- **Targeted highlight** — the tracker for your currently selected target turns yellow
- **Defeat highlight** — trackers turn gray when the entity dies; optional auto-remove after a configurable delay
- **CC duration timers** — shrinking progress bar with countdown for supported crowd-control skills (see below)
- **CC warning** — bar turns red when time remaining drops below a configurable threshold
- **Flexible layout** — vertical or horizontal fill, reverse fill order, configurable per-tracker size and spacing
- **Sort modes** — no sort or alphabetical by name
- **Drag handle** — reposition the HUD anywhere on screen

## Supported CC skills

| Class | Skill | Duration |
|---|---|---|
| Lore-master | Blinding Flash | 30 s |
| Burglar | Riddle | 30 s |
| Hunter | Distracting Shot | 35 s |
| Mariner | Thrum of the Sea | 25 s |
| Lore-master | Sign of Power: Righteousness | 15 s |

Timers are parsed from the combat log (`PlayerCombat` and `Death` channels). They trigger on the hit message, so the displayed duration is the base skill duration and does not account for partial resists or diminishing returns.

## Installation

1. Copy the `Potato` folder into your LotRO plugins directory:
   `Documents\The Lord of the Rings Online\plugins\Potato\`
2. In-game, open the Plugin Manager (`/plugins`) and load **Potato**.
3. The plugin prints a reminder to set your keybinding on first load.

## Usage

### Keybindings

Set both keybindings from the options panel (Plugin Manager → Potato → settings):

- **Add tracker** — targets the currently selected entity and pins a tracker card
- **Clear trackers** — removes all tracker cards (or only defeated ones if "only clear defeated" is enabled)

Click **Set key: add tracker** or **Set key: clear tracker**, then press any key or modifier combination. Press Escape to cancel.

### Options panel sections

**Position** — toggle a drag handle to reposition the HUD.

**Layout** — sort order (no sort / alphabetical), fill direction (vertical/horizontal), reverse fill.

**Tooltip size** — tracker width, height, spacing between trackers, maximum number of trackers. Click **apply size** to commit changes.

**Keybindings** — assign add and clear keys; toggle whether the clear key is active; toggle "only clear defeated" mode.

**Combat tracking**
- *Highlight defeated* — gray out tracker cards on defeat
- *Show CC timers* — enable the duration bar and countdown label
- *CC warning threshold* — seconds remaining at which the bar turns red (default 5)
- *Auto-remove defeated* — seconds after defeat before the tracker is automatically removed (0 = disabled)

Click **apply** to commit threshold and delay changes.

**Appearance** — set background colors (0–255 RGB) for player, NPC, and item trackers. Click **apply colors** to commit.

### Reloading

After copying updated files:

```
/plugins unload Potato
```

Settings are saved per-character and fall back to account scope when no character save exists.

## File structure

```
Potato/
  Potato.plugin        manifest (name, version, entry package)
  main.lua             entry point; loads/saves settings; instantiates window and options panel
  chatParse.lua        combat log hook; parses defeat and CC hit events
  targetChanged.lua    target-change hook; highlights the active tracker
  ui/
    potatoWindow.lua   main HUD window; owns the list of tracker cards
    potatoTooltip.lua  individual tracker card; renders name, portrait, CC bar
    optionPanel.lua    settings panel shown in the Plugin Manager
```
