import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createDefaultActionBook } from "../actions/defaultActions.js";
import type { BattleCommand } from "../actions/BattleCommand.js";
import type { BattleState } from "../domain/BattleState.js";
import { BattleEngine } from "../engine/BattleEngine.js";

export function createRomancingStylePreviewState(): BattleState {
  return {
    actors: [
      {
        id: "hero",
        name: "レイ",
        teamId: "party",
        stats: {
          hp: 689,
          maxHp: 689,
          strength: 18,
          defense: 10,
          magic: 3,
          resistance: 7,
          agility: 10
        },
        statusIds: []
      },
      {
        id: "lancer",
        name: "クローディア",
        teamId: "party",
        stats: {
          hp: 366,
          maxHp: 761,
          strength: 15,
          defense: 8,
          magic: 5,
          resistance: 7,
          agility: 12
        },
        statusIds: []
      },
      {
        id: "esper",
        name: "バーバラ",
        teamId: "party",
        stats: {
          hp: 340,
          maxHp: 684,
          strength: 8,
          defense: 6,
          magic: 21,
          resistance: 15,
          agility: 18
        },
        statusIds: []
      },
      {
        id: "healer",
        name: "アルベルト",
        teamId: "party",
        stats: {
          hp: 289,
          maxHp: 685,
          strength: 9,
          defense: 9,
          magic: 16,
          resistance: 13,
          agility: 8
        },
        statusIds: []
      },
      {
        id: "scout",
        name: "アイシャ",
        teamId: "party",
        stats: {
          hp: 228,
          maxHp: 699,
          strength: 13,
          defense: 7,
          magic: 8,
          resistance: 8,
          agility: 13
        },
        statusIds: []
      },
      {
        id: "gold_dragon",
        name: "金竜",
        teamId: "enemy",
        stats: {
          hp: 980,
          maxHp: 980,
          strength: 20,
          defense: 13,
          magic: 8,
          resistance: 11,
          agility: 9
        },
        statusIds: []
      }
    ]
  };
}

export function createRomancingStylePreviewCommands(): BattleCommand[] {
  return [
    { actorId: "hero", actionId: "attack", targetIds: ["gold_dragon"] },
    { actorId: "lancer", actionId: "poison_sting", targetIds: ["gold_dragon"] },
    { actorId: "esper", actionId: "fire", targetIds: ["gold_dragon"] },
    { actorId: "healer", actionId: "cure", targetIds: ["healer"] },
    { actorId: "scout", actionId: "attack", targetIds: ["gold_dragon"] },
    { actorId: "gold_dragon", actionId: "attack", targetIds: ["hero"] }
  ];
}

export function createRomancingStylePreviewTurnResult() {
  const engine = new BattleEngine(createDefaultActionBook());
  return engine.executeTurn({
    turnNumber: 1,
    state: createRomancingStylePreviewState(),
    commands: createRomancingStylePreviewCommands(),
    rngSeed: 67890
  });
}

function runCli(): void {
  const result = createRomancingStylePreviewTurnResult();
  const output = `${JSON.stringify(result, null, 2)}\n`;
  const outputPaths = [
    resolve(process.cwd(), "samples/romancing-style-turn-result.json"),
    resolve(process.cwd(), "godot/samples/romancing-style-turn-result.json")
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
