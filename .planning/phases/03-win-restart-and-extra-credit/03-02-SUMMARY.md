---
phase: 03
plan: 02
subsystem: game_top discount mux + Phase 3 testbench
tags: [discount, multiplier, testbench, verification, shop, verilog]
dependency_graph:
  requires: [03-01 (win detection, moves_to_win, start_round)]
  provides: [discount mux wired to shop instances, tb_phase3.v]
  affects: [game_top.v, tb_phase3.v]
tech_stack:
  added: []
  patterns:
    - combinational always @(*) mux for winner-based discount routing
    - two-phase buy task (posedge: shop latches; next posedge: game_top latches)
key_files:
  created:
    - tb_phase3.v
  modified:
    - game_top.v
decisions:
  - Test 4 uses 3x Wait for P1 (plan specified 4x but 3x100+2x50+4x30=520>500 credit budget; fixed to 3x)
  - Test 5 P1 buys 2x MoveRight in SHOP to have a consistent play sequence driving distance to 1
metrics:
  duration: "~5 min"
  completed: "2026-02-13"
---

# Phase 3 Plan 02: Discount Mux in game_top.v + tb_phase3.v Verification Testbench Summary

**One-liner:** Wired winner-based discount multiplier mux (80/90/95/100) into game_top.v shop instances and verified all three discount bands plus loser full-price via tb_phase3.v simulation.

## What Was Done

### Task 1: Discount mux added to game_top.v

Two registers added:
```verilog
reg [6:0] p1_discount_mult;
reg [6:0] p2_discount_mult;
```

Combinational always block computes discount based on `winner` and `moves_to_win`:
- `winner==01`: P1 gets 80/90/95 by band, P2 gets 100
- `winner==10`: P2 gets 80/90/95 by band, P1 gets 100
- no winner: both 100

Both shop instances updated: `discount_mult(7'd100)` replaced with `discount_mult(p1_discount_mult)` / `discount_mult(p2_discount_mult)`.

Compile verification: `iverilog -o /dev/null shop.v game_top.v` — zero errors.

### Task 2: tb_phase3.v created

Five test scenarios, 16 PASS/FAIL checks total. All 16 pass.

## Simulation Output

```
=== TEST 1: P1 wins in 6 moves (mult=80) ===
PASS [T1-a] phase=1 (SHOP) after P1 wins
PASS [T1-b] winner=01
PASS [T1-c] p1_credit=500 after win reset
PASS [T1-d] credit delta=80 (discount mult=80 for 6-move win)
=== TEST 2: start_round resets state ===
PASS [T2-a] phase=0 (PLAY) after start_round
PASS [T2-b] winner=00 after start_round
=== TEST 3: P1 wins in 8 moves (mult=90) ===
PASS [T3-a] winner=01
PASS [T3-b] phase=1 (SHOP) after P1 wins in 8 moves
PASS [T3-c] credit delta=90 (discount mult=90 for 8-move win)
=== TEST 4: P1 wins in 12 moves (mult=95) ===
PASS [T4-a] winner=01
PASS [T4-b] phase=1 (SHOP) after P1 wins in 12 moves
PASS [T4-c] credit delta=95 (discount mult=95 for 12-move win)
=== TEST 5: P2 wins in 6 moves (P2 mult=80, P1 mult=100) ===
PASS [T5-a] winner=10
PASS [T5-b] phase=1 (SHOP) after P2 wins
PASS [T5-c] P2 credit delta=80 (discount mult=80 for P2 win)
PASS [T5-d] P1 credit delta=100 (loser pays full price)
--- tb_phase3 complete ---
```

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed Test 4 credit budget overflow**
- **Found during:** Writing Test 4 play scenario
- **Issue:** Plan specified P1 buys 4x Wait(Price4=30) alongside 3x Kick(100) + 2x MoveRight(50). Total = 300+100+120 = 520 which exceeds the 500 credit budget. The buy for the 4th Wait would fail with err_credit.
- **Fix:** Changed to 3x Wait for P1 (cost = 300+100+90=490) and 3x Wait for P2 (instead of 2x). This still produces exactly 12 moves_to_win (moves_to_win=12 >= 10, discount band 95 correct). Play sequence: 2 P1 MoveRight + 1 P2 MoveLeft + alternating 3 P1 Wait/3 P2 Wait + 3 P1 Kick = 12 moves total.
- **Files modified:** tb_phase3.v
- **Commit:** ba84918

## Self-Check: PASSED

All files and commits verified:
- FOUND: tb_phase3.v
- FOUND: game_top.v (modified)
- FOUND: 03-02-SUMMARY.md
- FOUND: commit 7c66928 (feat(03-02): add discount mux)
- FOUND: commit ba84918 (feat(03-02): add tb_phase3.v)
