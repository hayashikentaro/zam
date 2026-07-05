import type { ActorState, TeamId } from "./ActorState.js";
import { isAlive } from "./ActorState.js";

export type BattleState = {
  actors: ActorState[];
};

export function findActor(state: BattleState, actorId: string): ActorState {
  const actor = state.actors.find((candidate) => candidate.id === actorId);
  if (!actor) {
    throw new Error(`Actor not found: ${actorId}`);
  }
  return actor;
}

export function livingActorsByTeam(state: BattleState, teamId: TeamId): ActorState[] {
  return state.actors.filter((actor) => actor.teamId === teamId && isAlive(actor));
}

export function cloneBattleState(state: BattleState): BattleState {
  return {
    actors: state.actors.map((actor) => ({
      ...actor,
      stats: { ...actor.stats },
      statusIds: [...actor.statusIds]
    }))
  };
}
