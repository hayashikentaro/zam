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
res://samples/basic-turn-result.json
```

Use this lab to adjust battle UI timing and component presentation in the same renderer that will be used by the game.

Use `RomancingStyleBattlePreview` to tune a 16-bit side-view battle layout: a large enemy on the left, party formation on the right, top action banners, command/status windows, generated placeholder pixel sprites, hit flashes, and floating damage numbers. The placeholder sprites are generated in GDScript so this prototype does not depend on copied reference art.

Regenerate the current placeholder PNG sprites with:

```sh
/Applications/Godot_mono.app/Contents/MacOS/Godot --headless --path godot --script res://tools/generate_battle_lab_assets.gd
```

Current controls:

- `Replay`: replay the sample event timeline.

Current adjustable script parameters on `BattleUiLab`:

- `event_delay`
- `damage_delay`
- `flash_duration`

When the TypeScript sample protocol changes, regenerate the root sample:

```sh
npm run sample:turn
```

This writes both `samples/basic-turn-result.json` and `godot/samples/basic-turn-result.json`.
