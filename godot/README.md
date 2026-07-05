# Godot Battle UI Lab

Open the `godot/` directory with Godot 4.x.

The main scene is:

```text
res://scenes/battle_lab/BattleUiLab.tscn
```

It loads:

```text
res://samples/basic-turn-result.json
```

Use this lab to adjust battle UI timing and component presentation in the same renderer that will be used by the game.

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
