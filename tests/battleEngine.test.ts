import test from "node:test";
import assert from "node:assert/strict";
import { BattleEngine } from "../src/battle-core/engine/BattleEngine.js";
import { createDefaultActionBook } from "../src/battle-core/actions/defaultActions.js";
import { createBasicBattleState, createBasicTurnCommands } from "../src/battle-core/samples/basicTurn.js";

test("executeTurn resolves commands in agility order and mutates cloned final state", () => {
  const engine = new BattleEngine(createDefaultActionBook());
  const initialState = createBasicBattleState();
  const goblin = initialState.actors.find((actor) => actor.id === "goblin");
  if (goblin) {
    goblin.stats.hp = 99;
    goblin.stats.maxHp = 99;
  }

  const result = engine.executeTurn({
    turnNumber: 1,
    state: initialState,
    commands: createBasicTurnCommands(),
    rngSeed: 12345
  });

  const actionStarts = result.events.filter((event) => event.type === "action_start");
  assert.deepEqual(
    actionStarts.map((event) => event.actorId),
    ["esper", "hero", "goblin"]
  );

  const finalGoblin = result.finalState.actors.find((actor) => actor.id === "goblin");
  assert.equal(finalGoblin?.stats.hp, 55);

  assert.equal(goblin?.stats.hp, 99);
});

test("battle_end is emitted when one side has no living actors", () => {
  const engine = new BattleEngine(createDefaultActionBook());
  const result = engine.executeTurn({
    turnNumber: 1,
    state: createBasicBattleState(),
    commands: createBasicTurnCommands(),
    rngSeed: 12345
  });

  assert.ok(result.events.some((event) => event.type === "death" && event.targetId === "goblin"));
  assert.ok(result.events.some((event) => event.type === "battle_end" && event.winnerTeamId === "party"));
});
