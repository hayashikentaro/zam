import { mkdirSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import type { BattleCommand } from "../actions/BattleCommand.js";
import type { BattleState } from "../domain/BattleState.js";
import { BattleEngine } from "../engine/BattleEngine.js";
import {
  createActionBookFromData,
  createBattleStateFromData,
  loadBattleDataCatalog,
  loadEncounterData
} from "../data/BattleData.js";

const ENCOUNTER_PATH = "data/battle/encounters/romancing-style-preview.json";

export function createRomancingStylePreviewState(): BattleState {
  const catalog = loadBattleDataCatalog();
  const encounter = loadEncounterData(ENCOUNTER_PATH);
  return createBattleStateFromData(catalog, encounter);
}

export function createRomancingStylePreviewCommands(): BattleCommand[] {
  return loadEncounterData(ENCOUNTER_PATH).commands;
}

export function createRomancingStylePreviewTurnResult() {
  const catalog = loadBattleDataCatalog();
  const encounter = loadEncounterData(ENCOUNTER_PATH);
  const engine = new BattleEngine(createActionBookFromData(catalog.actions));
  return engine.executeTurn({
    turnNumber: encounter.turnNumber,
    state: createBattleStateFromData(catalog, encounter),
    commands: encounter.commands,
    rngSeed: encounter.rngSeed
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
