# Godot Battle UI Lab

Open the `godot/` directory with Godot 4.x.

The component-oriented lab scene is:

```text
res://scenes/battle_lab/BattleUiLab.tscn
```

The pixel battle presentation preview scene is:

```text
res://scenes/battle_lab/RomancingStyleBattlePreview.tscn
```

It loads:

```text
res://samples/romancing-style-turn-result.json
```

Use this lab to adjust battle UI timing and component presentation in the same renderer that will be used by the game.

Use `RomancingStyleBattlePreview` to tune a 16-bit side-view battle layout: a large enemy on the left, party formation on the right, top action banners, command/status windows, generated placeholder pixel sprites, hit flashes, and floating damage numbers. The placeholder sprites are generated in GDScript so this prototype does not depend on copied reference art.

Presentation data lives in `res://data/battle_lab/actor-presentations.json` for actor placement and anchors, `res://data/battle_lab/action-presentations.json` for command labels, action banners, and effect choices, and `res://data/battle_lab/ui-settings.json` for preview layout, timing, colors, fonts, and field drawing settings.

Regenerate the current placeholder PNG sprites and idle frames with:

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path godot --script res://tools/generate_battle_lab_assets.gd
```

Current controls:

- `Replay`: replay the sample event timeline.

Current adjustable script parameters on `BattleUiLab`:

- `event_delay`
- `damage_delay`
- `flash_duration`

When the TypeScript sample protocol changes, regenerate the root samples:

```sh
npm run sample:turn
npm run sample:romancing-preview
```

These write tracked outputs under both `samples/` and `godot/samples/`.
