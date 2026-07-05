import type { ActorState } from "../domain/ActorState.js";
import type { BattleState } from "../domain/BattleState.js";
import type { BattleEvent } from "../events/BattleEvent.js";
import type { Rng } from "../rng/Rng.js";

export type EffectContext = {
  state: BattleState;
  source: ActorState;
  target: ActorState;
  rng: Rng;
};

export interface BattleEffect {
  apply(ctx: EffectContext): BattleEvent[];
}
