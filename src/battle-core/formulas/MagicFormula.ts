import type { DamageContext, DamageFormula, DamageResult } from "./DamageFormula.js";

export class MagicFormula implements DamageFormula {
  calculate(ctx: DamageContext): DamageResult {
    const variance = ctx.rng.nextInt(-3, 3);
    const raw = ctx.attacker.stats.magic * 2 + ctx.power + variance - ctx.defender.stats.resistance;
    return {
      amount: Math.max(1, raw),
      damageType: "magic"
    };
  }
}
