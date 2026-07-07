import test from "node:test";
import assert from "node:assert/strict";
import {
  createActionBookFromData,
  createBattleStateFromData,
  loadBattleDataCatalog,
  loadEncounterData
} from "../src/battle-core/data/BattleData.js";
import { BattleEngine } from "../src/battle-core/engine/BattleEngine.js";

test("loads characters, monsters, items, and actions from external battle data", () => {
  const catalog = loadBattleDataCatalog();

  assert.ok(catalog.characters.some((actor) => actor.id === "esper"));
  assert.ok(catalog.monsters.some((actor) => actor.id === "gold_dragon"));
  assert.ok(catalog.items.some((item) => item.id === "potion"));
  assert.ok(catalog.actions.some((action) => action.id === "fire"));
});

test("builds the romancing style preview turn from external battle data", () => {
  const catalog = loadBattleDataCatalog();
  const encounter = loadEncounterData("data/battle/encounters/romancing-style-preview.json");
  const state = createBattleStateFromData(catalog, encounter);
  const engine = new BattleEngine(createActionBookFromData(catalog.actions));

  assert.deepEqual(
    state.actors.map((actor) => actor.id),
    ["hero", "lancer", "esper", "healer", "scout", "gold_dragon"]
  );

  const result = engine.executeTurn({
    turnNumber: encounter.turnNumber,
    state,
    commands: encounter.commands,
    rngSeed: encounter.rngSeed
  });

  const actionStarts = result.events.filter((event) => event.type === "action_start");
  assert.equal(actionStarts[0]?.actorId, "esper");
  assert.ok(result.events.some((event) => event.type === "damage" && event.targetId === "gold_dragon"));
  assert.ok(result.events.some((event) => event.type === "heal" && event.targetId === "healer"));
});
