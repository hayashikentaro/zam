import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { BattleEngine } from "../engine/BattleEngine.js";
import { createDefaultActionBook } from "../actions/defaultActions.js";
import type { BattleState } from "../domain/BattleState.js";
import type { BattleCommand } from "../actions/BattleCommand.js";

export function createBasicBattleState(): BattleState {
  return {
    actors: [
      {
        id: "hero",
        name: "にんげん おとこ",
        teamId: "party",
        stats: {
          hp: 43,
          maxHp: 58,
          strength: 12,
          defense: 6,
          magic: 3,
          resistance: 4,
          agility: 8
        },
        statusIds: []
      },
      {
        id: "esper",
        name: "エスパー ギャル",
        teamId: "party",
        stats: {
          hp: 31,
          maxHp: 42,
          strength: 5,
          defense: 4,
          magic: 13,
          resistance: 9,
          agility: 11
        },
        statusIds: []
      },
      {
        id: "goblin",
        name: "ゴブリン",
        teamId: "enemy",
        stats: {
          hp: 30,
          maxHp: 30,
          strength: 8,
          defense: 3,
          magic: 0,
          resistance: 2,
          agility: 6
        },
        statusIds: []
      }
    ]
  };
}

export function createBasicTurnCommands(): BattleCommand[] {
  return [
    { actorId: "hero", actionId: "attack", targetIds: ["goblin"] },
    { actorId: "esper", actionId: "fire", targetIds: ["goblin"] },
    { actorId: "goblin", actionId: "attack", targetIds: ["hero"] }
  ];
}

export function createBasicTurnResult() {
  const engine = new BattleEngine(createDefaultActionBook());
  return engine.executeTurn({
    turnNumber: 1,
    state: createBasicBattleState(),
    commands: createBasicTurnCommands(),
    rngSeed: 12345
  });
}

function runCli(): void {
  const result = createBasicTurnResult();
  const output = `${JSON.stringify(result, null, 2)}\n`;
  const outputPaths = [
    resolve(process.cwd(), "samples/basic-turn-result.json"),
    resolve(process.cwd(), "godot/samples/basic-turn-result.json")
  ];

  for (const outputPath of outputPaths) {
    mkdirSync(dirname(outputPath), { recursive: true });
    writeFileSync(outputPath, output);
    console.log(`Wrote ${outputPath}`);
  }
}

if (process.argv[1] === fileURLToPath(import.meta.url)) {
  runCli();
}
