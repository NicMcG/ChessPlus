// Written by tools/make_rule_set.gd: every rule set the referee knows, by version.

import r_6ab1c86a6654 from "./rules/6ab1c86a6654.json" with { type: "json" };

export const RULE_SETS: Record<string, RuleSetData> = {
  "6ab1c86a6654": r_6ab1c86a6654 as unknown as RuleSetData,
};

import type { RuleSetData } from "./referee.ts";
