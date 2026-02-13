---
phase: 02-game-core
verified: 2026-02-13T00:00:00Z
status: passed
score: 8/8 must-haves verified
---

# Phase 2: Game Core Verification Report

**Phase Goal:** Two players can take turns executing moves (Kick, Punch, MoveLeft, MoveRight, Wait) with correct distance-based damage, position saturation, inventory enforcement, and turn switching
**Verified:** 2026-02-13
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Kick at distance=1 reduces opponent health by 1 | VERIFIED | game_top.v:158-159: `if (distance == 3'd1) p2_health <= p2_health - 2'd1;` (P1) and line 207-208 (P2). Simulation PASS [GAME-03b]: p2_health goes 3→2 after P1 kick at distance=1 |
| 2 | Punch at distance=0 reduces opponent health by 2 | VERIFIED | game_top.v:169-170: `if (distance == 3'd0) p2_health <= p2_health - 2'd2;` (P1) and line 218-219 (P2). Simulation PASS [GAME-04b]: p2_health goes 2→0 after P1 punch at distance=0 |
| 3 | Kick/Punch at wrong distance deals no damage but consumes inventory | VERIFIED | game_top.v:157-162: inventory decremented before distance check; `else err_wrong_distance <= 1'b1` on mismatch. Simulation PASS [GAME-02a,b]: wrong-distance kick fires err_wrong_distance, p2_health=3 unchanged; counter depleted (PASS [GAME-08a]) |
| 4 | MoveLeft/MoveRight adjust position with saturation at 0 and 2 | VERIFIED | game_top.v:180 `if (p1_pos < 2'd2) p1_pos <= p1_pos + 2'd1;` (P1 Left, saturates at 2); line 188 `if (p1_pos > 2'd0) p1_pos <= p1_pos - 2'd1;` (P1 Right, saturates at 0). Mirrored for P2 (lines 229, 237). Simulation PASS [GAME-05a,b]: P1 pos goes 2→1→0 on two MoveRight actions |
| 5 | Saturated moves still consume inventory | VERIFIED | Saturation is an if-guard on position only; the `p1_moves[N] <= p1_moves[N] - 4'd1` decrement occurs unconditionally inside the `else` (inventory > 0) branch, before the positional guard. Counter always decrements when inventory > 0, even if position is already clamped |
| 6 | Wait consumes Wait counter, changes no other state | VERIFIED | game_top.v:191-196: ACT_WAIT branch decrements p1_moves[4] only — no health or position writes. P2 mirrored at lines 240-245. Simulation PASS [GAME-06a,b,c]: err_no_inventory=0, health/pos unchanged after P2 Wait |
| 7 | Action with move counter=0 triggers err_no_inventory, no state change | VERIFIED | game_top.v:154-156: `if (p1_moves[0] == 4'd0) err_no_inventory <= 1'b1;` with no state writes in that branch (pattern applied to all 5 actions for both players). Simulation PASS [GAME-07a,b,c]: err_no_inventory=1, p2_health=3, p1_pos=p2_pos=2 all unchanged |
| 8 | Only active player's state changes; inactive player unaffected | VERIFIED | game_top.v:151: outer `if (turn == 1'b0)` / `else` branch — P1 branch (lines 151-199) contains zero writes to p2_moves, p2_pos, or p1_health; P2 branch (lines 200-249) contains zero writes to p1_moves, p1_pos, or p2_health. Verified by static grep. Simulation PASS [GAME-01a,b]: p2_pos=2 and p2_health=3 unchanged during P1 MoveRight |

**Score:** 8/8 truths verified

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `game_top.v` | Complete PLAY phase action logic; contains ACT_KICK | VERIFIED | 257 lines, no stubs/TODOs, no SystemVerilog keywords, exports `module game_top`, full PLAY logic for all 5 actions both players |
| `tb_game_core.v` | Phase 2 verification testbench; contains `tb_game_core` | VERIFIED | 426 lines, 24 assertions, all PASS, ends with `--- tb_game_core complete ---`; covers GAME-01 through GAME-08 |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| game_top.v PLAY block | p1_moves/p2_moves counters | inventory check before action execution | WIRED | `if (pN_moves[i] == 4'd0) err_no_inventory` pattern at lines 154-193 (P1) and 203-242 (P2) — fires before any state write |
| game_top.v PLAY block | distance wire | distance check for Kick/Punch | WIRED | `wire [2:0] distance = {1'b0,p1_pos}+{1'b0,p2_pos}` at line 55; used in `if (distance == 3'd1)` (Kick) and `if (distance == 3'd0)` (Punch) at lines 158, 169, 207, 218 |
| game_top.v SHOP phase | shop grant_onehot | move counter increment | WIRED | `if (p1_grant_onehot[i]) p1_moves[i] <= p1_moves[i] + 4'd1` for all 5 moves (lines 135-144) |
| turn input | P1/P2 branch selector | `if (turn == 1'b0)` | WIRED | Line 151; all state writes correctly isolated behind this condition |

---

### Requirements Coverage

| Requirement | Status | Notes |
|-------------|--------|-------|
| GAME-01: Only active player state changes | SATISFIED | Turn isolation verified by static analysis and simulation |
| GAME-02: Wrong-distance attacks raise err_wrong_distance, no damage | SATISFIED | Both Kick and Punch confirmed by PASS [GAME-02a,b,c,d] |
| GAME-03: Kick at distance=1 deals 1 damage | SATISFIED | PASS [GAME-03b] |
| GAME-04: Punch at distance=0 deals 2 damage | SATISFIED | PASS [GAME-04b] |
| GAME-05: Position saturates at 0 and 2 | SATISFIED | Saturation guards present for all four move directions; PASS [GAME-05a,b] |
| GAME-06: Wait leaves health/position unchanged | SATISFIED | PASS [GAME-06a,b,c] |
| GAME-07: Counter=0 triggers err_no_inventory, no state change | SATISFIED | PASS [GAME-07a,b,c] |
| GAME-08: Valid action decrements that move's counter by 1 | SATISFIED | Counter exhaustion demonstrated by PASS [GAME-08a,b,c,d] |

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| None | — | — | No TODOs, stubs, placeholder returns, or console-log-only handlers found in game_top.v or tb_game_core.v |

---

### Human Verification Required

None. All phase 2 truths are mechanically verifiable via simulation and static analysis. The testbench runs to completion with 0 errors and the simulation output is deterministic.

---

### Compilation and Simulation Results

```
iverilog -o /dev/null shop.v game_top.v        -> Exit 0 (clean)
iverilog + vvp tb_game_core                    -> 24/24 assertions PASS
                                               -> "--- tb_game_core complete ---"
                                               -> Exit 0
```

No SystemVerilog keywords in game_top.v (verified by grep).
No $display statements in game_top.v (TB-only output).

---

### Gaps Summary

None. All 8 must-have truths verified. The phase goal is fully achieved: two players can take turns executing all five move types with correct distance-based damage, position saturation clamped at 0 and 2, inventory enforcement (err_no_inventory on zero counter), and strict turn isolation ensuring only the active player's state changes each clock cycle.

**Known non-gaps (scoped to later phases):**
- Health underflow guard (wrap-around at 0) deferred to Phase 3 win detection — explicitly noted in plan and summary as intentional
- moves_to_win counter not present — Phase 3 scope
- $display logging not present in game_top.v — Phase 4 scope

---

_Verified: 2026-02-13_
_Verifier: Claude (gsd-verifier)_
