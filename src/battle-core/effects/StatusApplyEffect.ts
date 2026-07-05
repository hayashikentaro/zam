import type { BattleEvent } from "../events/BattleEvent.js";
import type { BattleEffect, EffectContext } from "./BattleEffect.js";

export class StatusApplyEffect implements BattleEffect {
  constructor(private readonly statusId: string) {}

  apply(ctx: EffectContext): BattleEvent[] {
    if (!ctx.target.statusIds.includes(this.statusId)) {
      ctx.target.statusIds.push(this.statusId);
    }

    return [
      {
        type: "status_applied",
        sourceId: ctx.source.id,
        targetId: ctx.target.id,
        statusId: this.statusId
      }
    ];
  }
}
