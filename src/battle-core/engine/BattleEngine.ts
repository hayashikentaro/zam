import type { ActionBook } from "../actions/ActionDefinition.js";
import type { BattleCommand } from "../actions/BattleCommand.js";
import { isAlive } from "../domain/ActorState.js";
import {
  cloneBattleState,
  findActor,
  livingActorsByTeam,
  type BattleState
} from "../domain/BattleState.js";
import type { BattleEvent, TurnResult } from "../events/BattleEvent.js";
import { SeededRng } from "../rng/Rng.js";

export type TurnInput = {
  turnNumber: number;
  state: BattleState;
  commands: BattleCommand[];
  rngSeed: number;
};

export class BattleEngine {
  constructor(private readonly actions: ActionBook) {}

  executeTurn(input: TurnInput): TurnResult {
    const state = cloneBattleState(input.state);
    const rng = new SeededRng(input.rngSeed);
    const events: BattleEvent[] = [{ type: "turn_start", turnNumber: input.turnNumber }];

    const orderedCommands = [...input.commands].sort((left, right) => {
      const leftActor = findActor(state, left.actorId);
      const rightActor = findActor(state, right.actorId);
      return rightActor.stats.agility - leftActor.stats.agility;
    });

    for (const command of orderedCommands) {
      const actor = findActor(state, command.actorId);
      if (!isAlive(actor)) {
        continue;
      }

      const action = this.actions.get(command.actionId);
      if (!action) {
        throw new Error(`Action not found: ${command.actionId}`);
      }

      const targets = action.targetRule.selectTargets(state, actor, command.targetIds);
      events.push({
        type: "action_start",
        actorId: actor.id,
        actionId: action.id,
        targetIds: targets.map((target) => target.id)
      });
      events.push({
        type: "message",
        textKey: `action.${action.nameKey}`,
        params: { actor: actor.name }
      });

      for (const target of targets) {
        for (const effect of action.effects) {
          events.push(...effect.apply({ state, source: actor, target, rng }));
        }
      }

      events.push({ type: "action_end", actorId: actor.id, actionId: action.id });

      const partyAlive = livingActorsByTeam(state, "party").length > 0;
      const enemyAlive = livingActorsByTeam(state, "enemy").length > 0;
      if (!partyAlive || !enemyAlive) {
        events.push({ type: "battle_end", winnerTeamId: partyAlive ? "party" : "enemy" });
        break;
      }
    }

    events.push({ type: "turn_end", turnNumber: input.turnNumber });

    return { events, finalState: state };
  }
}
