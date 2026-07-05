import type { BattleState } from "../domain/BattleState.js";

export type BattleEvent =
  | { type: "turn_start"; turnNumber: number }
  | { type: "action_start"; actorId: string; actionId: string; targetIds: string[] }
  | { type: "message"; textKey: string; params?: Record<string, string | number> }
  | {
      type: "damage";
      sourceId: string;
      targetId: string;
      amount: number;
      damageType: string;
      hpBefore: number;
      hpAfter: number;
    }
  | {
      type: "heal";
      sourceId: string;
      targetId: string;
      amount: number;
      hpBefore: number;
      hpAfter: number;
    }
  | { type: "miss"; sourceId: string; targetId: string; reason: string }
  | { type: "status_applied"; sourceId: string; targetId: string; statusId: string }
  | { type: "death"; targetId: string }
  | { type: "action_end"; actorId: string; actionId: string }
  | { type: "turn_end"; turnNumber: number }
  | { type: "battle_end"; winnerTeamId: string };

export type TurnResult = {
  events: BattleEvent[];
  finalState: BattleState;
};
