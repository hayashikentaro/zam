import type { BattleEffect } from "../effects/BattleEffect.js";
import type { TargetRule } from "./TargetRule.js";

export type ActionDefinition = {
  id: string;
  nameKey: string;
  targetRule: TargetRule;
  effects: BattleEffect[];
};

export type ActionBook = Map<string, ActionDefinition>;
