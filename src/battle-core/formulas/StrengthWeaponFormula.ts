import type { DamageContext, DamageFormula, DamageResult } from "./DamageFormula.js";

export class StrengthWeaponFormula implements DamageFormula {
  calculate(ctx: DamageContext): DamageResult {
    const variance = ctx.rng.nextInt(-2, 2);
    const raw = ctx.attacker.stats.strength + ctx.power + variance - ctx.defender.stats.defense;
    return {
      amount: Math.max(1, raw),
      damageType: "physical"
    };
  }
}
