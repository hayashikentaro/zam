import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import type { ActionBook, ActionDefinition } from "../actions/ActionDefinition.js";
import type { BattleCommand } from "../actions/BattleCommand.js";
import { RequestedSingleTargetRule, SelfTargetRule } from "../actions/TargetRule.js";
import type { ActorState, TeamId } from "../domain/ActorState.js";
import type { BattleState } from "../domain/BattleState.js";
import type { Stats } from "../domain/Stats.js";
import type { BattleEffect } from "../effects/BattleEffect.js";
import { DamageEffect } from "../effects/DamageEffect.js";
import { HealEffect } from "../effects/HealEffect.js";
import { StatusApplyEffect } from "../effects/StatusApplyEffect.js";
import { FixedDamageFormula } from "../formulas/FixedDamageFormula.js";
import { MagicFormula } from "../formulas/MagicFormula.js";
import { StrengthWeaponFormula } from "../formulas/StrengthWeaponFormula.js";

export type ActorData = {
  id: string;
  name: string;
  stats: Stats;
  statusIds?: string[];
};

export type DamageEffectData = {
  type: "damage";
  power: number;
  formula: "fixed" | "magic" | "strength_weapon";
};

export type HealEffectData = {
  type: "heal";
  amount: number;
};

export type StatusApplyEffectData = {
  type: "status_apply";
  statusId: string;
};

export type EffectData = DamageEffectData | HealEffectData | StatusApplyEffectData;

export type ActionData = {
  id: string;
  nameKey: string;
  targetRule: "requested_single" | "self";
  effects: EffectData[];
};

export type ItemData = {
  id: string;
  name: string;
  targetRule: "requested_single" | "self";
  effects: EffectData[];
};

export type EncounterData = {
  partyActorIds: string[];
  enemyActorIds: string[];
  commands: BattleCommand[];
  rngSeed: number;
  turnNumber: number;
};

export type BattleDataCatalog = {
  characters: ActorData[];
  monsters: ActorData[];
  actions: ActionData[];
  items: ItemData[];
};

export function loadBattleDataCatalog(rootDir = process.cwd()): BattleDataCatalog {
  return {
    characters: readJson(resolve(rootDir, "data/battle/characters.json")),
    monsters: readJson(resolve(rootDir, "data/battle/monsters.json")),
    actions: readJson(resolve(rootDir, "data/battle/actions.json")),
    items: readJson(resolve(rootDir, "data/battle/items.json"))
  };
}

export function loadEncounterData(path: string, rootDir = process.cwd()): EncounterData {
  return readJson(resolve(rootDir, path));
}

export function createBattleStateFromData(
  catalog: Pick<BattleDataCatalog, "characters" | "monsters">,
  encounter: Pick<EncounterData, "partyActorIds" | "enemyActorIds">
): BattleState {
  return {
    actors: [
      ...encounter.partyActorIds.map((actorId) => createActorState(findActorData(catalog.characters, actorId), "party")),
      ...encounter.enemyActorIds.map((actorId) => createActorState(findActorData(catalog.monsters, actorId), "enemy"))
    ]
  };
}

export function createActionBookFromData(actions: ActionData[]): ActionBook {
  return new Map(actions.map((action) => [action.id, createActionDefinition(action)]));
}

function readJson<T>(path: string): T {
  return JSON.parse(readFileSync(path, "utf8")) as T;
}

function findActorData(actors: ActorData[], actorId: string): ActorData {
  const actor = actors.find((candidate) => candidate.id === actorId);
  if (!actor) {
    throw new Error(`Actor data not found: ${actorId}`);
  }
  return actor;
}

function createActorState(actor: ActorData, teamId: TeamId): ActorState {
  return {
    id: actor.id,
    name: actor.name,
    teamId,
    stats: { ...actor.stats },
    statusIds: [...(actor.statusIds ?? [])]
  };
}

function createActionDefinition(action: ActionData): ActionDefinition {
  return {
    id: action.id,
    nameKey: action.nameKey,
    targetRule: createTargetRule(action.targetRule),
    effects: action.effects.map(createEffect)
  };
}

function createTargetRule(targetRule: ActionData["targetRule"]) {
  switch (targetRule) {
    case "requested_single":
      return new RequestedSingleTargetRule();
    case "self":
      return new SelfTargetRule();
  }
}

function createEffect(effect: EffectData): BattleEffect {
  switch (effect.type) {
    case "damage":
      return new DamageEffect(effect.power, createDamageFormula(effect.formula));
    case "heal":
      return new HealEffect(effect.amount);
    case "status_apply":
      return new StatusApplyEffect(effect.statusId);
  }
}

function createDamageFormula(formula: DamageEffectData["formula"]) {
  switch (formula) {
    case "fixed":
      return new FixedDamageFormula();
    case "magic":
      return new MagicFormula();
    case "strength_weapon":
      return new StrengthWeaponFormula();
  }
}
