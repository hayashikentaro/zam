# Battle Data

This directory stores editable battle data used by TypeScript sample generation.

- `characters.json`: party actor definitions
- `monsters.json`: enemy actor definitions
- `actions.json`: battle action rules converted into an `ActionBook`
- `items.json`: item catalog data, currently loaded as catalog data and reserved for item commands
- `encounters/*.json`: preview encounter setup, commands, turn number, and RNG seed

Godot preview scenes consume generated sample outputs under `godot/samples/`. Regenerate those outputs after changing battle data:

```sh
npm run sample:romancing-preview
```
