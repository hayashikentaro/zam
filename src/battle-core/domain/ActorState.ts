import type { Stats } from "./Stats.js";

export type TeamId = "party" | "enemy";

export type ActorState = {
  id: string;
  name: string;
  teamId: TeamId;
  stats: Stats;
  statusIds: string[];
};

export function isAlive(actor: ActorState): boolean {
  return actor.stats.hp > 0;
}
