import type { DamageContext, DamageFormula, DamageResult } from "./DamageFormula.js";

export class FixedDamageFormula implements DamageFormula {
  calculate(ctx: DamageContext): DamageResult {
    return {
      amount: Math.max(0, ctx.power),
      damageType: "fixed"
    };
  }
}
