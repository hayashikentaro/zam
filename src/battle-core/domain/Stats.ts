export type Stats = {
  hp: number;
  maxHp: number;
  strength: number;
  defense: number;
  magic: number;
  resistance: number;
  agility: number;
};

export function clampHp(value: number, maxHp: number): number {
  return Math.max(0, Math.min(maxHp, value));
}
