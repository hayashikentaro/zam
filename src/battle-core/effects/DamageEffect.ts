import { clampHp } from "../domain/Stats.js";
import type { BattleEvent } from "../events/BattleEvent.js";
import type { DamageFormula } from "../formulas/DamageFormula.js";
import type { BattleEffect, EffectContext } from "./BattleEffect.js";

export class DamageEffect implements BattleEffect {
  constructor(
    private readonly power: number,
    private readonly formula: DamageFormula
  ) {}

  apply(ctx: EffectContext): BattleEvent[] {
    if (ctx.target.stats.hp <= 0) {
      return [{ type: "miss", sourceId: ctx.source.id, targetId: ctx.target.id, reason: "target_dead" }];
    }

    const result = this.formula.calculate({
      attacker: ctx.source,
      defender: ctx.target,
      power: this.power,
      rng: ctx.rng
    });
    const hpBefore = ctx.target.stats.hp;
    const hpAfter = clampHp(hpBefore - result.amount, ctx.target.stats.maxHp);
    ctx.target.stats.hp = hpAfter;

    const events: BattleEvent[] = [
      {
        type: "damage",
        sourceId: ctx.source.id,
        targetId: ctx.target.id,
        amount: hpBefore - hpAfter,
        damageType: result.damageType,
        hpBefore,
        hpAfter
      }
    ];

    if (hpBefore > 0 && hpAfter === 0) {
      events.push({ type: "death", targetId: ctx.target.id });
    }

    return events;
  }
}
