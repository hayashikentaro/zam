import type { ActionBook } from "./ActionDefinition.js";
import { RequestedSingleTargetRule, SelfTargetRule } from "./TargetRule.js";
import { DamageEffect } from "../effects/DamageEffect.js";
import { HealEffect } from "../effects/HealEffect.js";
import { StatusApplyEffect } from "../effects/StatusApplyEffect.js";
import { MagicFormula } from "../formulas/MagicFormula.js";
import { StrengthWeaponFormula } from "../formulas/StrengthWeaponFormula.js";

export function createDefaultActionBook(): ActionBook {
  return new Map([
    [
      "attack",
      {
        id: "attack",
        nameKey: "attack",
        targetRule: new RequestedSingleTargetRule(),
        effects: [new DamageEffect(6, new StrengthWeaponFormula())]
      }
    ],
    [
      "fire",
      {
        id: "fire",
        nameKey: "fire",
        targetRule: new RequestedSingleTargetRule(),
        effects: [new DamageEffect(10, new MagicFormula())]
      }
    ],
    [
      "cure",
      {
        id: "cure",
        nameKey: "cure",
        targetRule: new SelfTargetRule(),
        effects: [new HealEffect(18)]
      }
    ],
    [
      "poison_sting",
      {
        id: "poison_sting",
        nameKey: "poison_sting",
        targetRule: new RequestedSingleTargetRule(),
        effects: [new DamageEffect(2, new StrengthWeaponFormula()), new StatusApplyEffect("poison")]
      }
    ]
  ]);
}
