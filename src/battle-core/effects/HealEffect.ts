import { clampHp } from "../domain/Stats.js";
import type { BattleEvent } from "../events/BattleEvent.js";
import type { BattleEffect, EffectContext } from "./BattleEffect.js";

export class HealEffect implements BattleEffect {
  constructor(private readonly amount: number) {}

  apply(ctx: EffectContext): BattleEvent[] {
    const hpBefore = ctx.target.stats.hp;
    const hpAfter = clampHp(hpBefore + this.amount, ctx.target.stats.maxHp);
    ctx.target.stats.hp = hpAfter;

    return [
      {
        type: "heal",
        sourceId: ctx.source.id,
        targetId: ctx.target.id,
        amount: hpAfter - hpBefore,
        hpBefore,
        hpAfter
      }
    ];
  }
}
