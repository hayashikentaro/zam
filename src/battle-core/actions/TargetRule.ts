import type { ActorState } from "../domain/ActorState.js";
import type { BattleState } from "../domain/BattleState.js";
import { livingActorsByTeam } from "../domain/BattleState.js";

export interface TargetRule {
  selectTargets(state: BattleState, actor: ActorState, requestedTargetIds: string[]): ActorState[];
}

export class RequestedSingleTargetRule implements TargetRule {
  selectTargets(state: BattleState, actor: ActorState, requestedTargetIds: string[]): ActorState[] {
    const requested = state.actors.find((candidate) => candidate.id === requestedTargetIds[0]);
    if (requested && requested.stats.hp > 0) {
      return [requested];
    }

    const opponentTeam = actor.teamId === "party" ? "enemy" : "party";
    return livingActorsByTeam(state, opponentTeam).slice(0, 1);
  }
}

export class SelfTargetRule implements TargetRule {
  selectTargets(_state: BattleState, actor: ActorState): ActorState[] {
    return [actor];
  }
}
