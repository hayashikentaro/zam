import type { ActorState } from "../domain/ActorState.js";
import type { Rng } from "../rng/Rng.js";

export type DamageContext = {
  attacker: ActorState;
  defender: ActorState;
  power: number;
  rng: Rng;
};

export type DamageResult = {
  amount: number;
  damageType: string;
};

export interface DamageFormula {
  calculate(ctx: DamageContext): DamageResult;
}
