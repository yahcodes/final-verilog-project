---
phase: 04-display-and-testbench
plan: 02
status: complete
completed: 2026-02-15
---

# Summary: 04-02 — tb_game.v

## What was done

Wrote `tb_game.v` exercising all 8 TB-01 scenarios with explicit PASS/FAIL output.

## Simulation output (key lines)

```
=== TB_GAME START ===
--- GROUP A: Error tests + combat ---
-- TEST 1: Invalid action --
[SHOP] Action=5 Price=0 Discounted=0 | ERR_INVALID_ACTION | Stock=[5,5,5,5,5]
[SHOP] Action=4 ... SUCCESS | Stock=[5,5,5,5,4]  (x5 drains Wait stock)
-- TEST 2: Out-of-stock --
[SHOP] Action=4 Price=30 Discounted=30 |   ERR_OUT_OF_STOCK | Stock=[5,5,5,5,0]
-- TEST 3: Insufficient credit --
[SHOP] Action=1 Price=120 Discounted=120 |         ERR_CREDIT | Stock=[4,5,4,2,0]
-- TEST 4: Left saturation --
PASS [T4]: p1_pos=2 (left sat)
-- TEST 5: Right saturation --
PASS [T5]: p1_pos=0 (right sat)
-- TEST 7: Kick at dist=1 --
PASS [T7]: kick dealt 1 dmg
-- TEST 6+8: Punch at dist=0 + Win --
PASS [T6+T8]: P2 wins, winner=2
PASS: phase=SHOP after win
--- GROUP B: Band 2 discount (mult=90) ---
[SHOP] Action=0 Price=100 Discounted=90 | SUCCESS
--- GROUP C: Band 1 discount (mult=80) ---
PASS [C]: P1 wins, mtw=6 -> band 1
[SHOP] Action=0 Price=100 Discounted=80 | SUCCESS
--- GROUP D: Band 3 discount (mult=95) ---
PASS [D]: P1 wins, mtw=12 -> band 3
[SHOP] Action=0 Price=100 Discounted=95 | SUCCESS
=== TB_GAME COMPLETE ===
```

## Verification results

| Requirement | Result |
|-------------|--------|
| ERR_INVALID_ACTION visible | ✓ |
| ERR_CREDIT visible | ✓ |
| ERR_OUT_OF_STOCK visible | ✓ |
| p1_pos=2 after MoveLeft at pos=2 (saturation) | PASS |
| p1_pos=0 after MoveRight at pos=0 (saturation) | PASS |
| Kick at dist=1 deals 1 damage | PASS |
| Punch at dist=0 + full win path | PASS |
| winner=2 and phase=SHOP after win | PASS |
| Discounted=90 (band 2, mtw=8) | ✓ |
| Discounted=80 (band 1, mtw=6) | ✓ |
| Discounted=95 (band 3, mtw=12) | ✓ |
| Simulation completes (TB_GAME COMPLETE) | ✓ |
| FAIL lines | 0 |
| PASS lines | 7 |

## Key implementation notes

- **buy_p1/buy_p2 tasks drive at `@(negedge clk)`** before asserting buy_valid. This ensures the combinational block in shop.v (which computes purchase_success, err_credit, etc.) has settled before the sequential always @(posedge clk) fires its $display. Avoids the "NONE" outcome race condition.
- **buy_valid pulsed for exactly 1 clock cycle** — deasserted at negedge before the settle posedge — preventing double-purchases.
- **PASS/FAIL checks use `if/else $display`** — Verilog string ternary `condition ? "STRING_A" : "STRING_B"` zero-pads and prints as binary integers; if/else is the correct approach.
- All group sequences verified: credit arithmetic, stock depletion, inventory counts all match plan exactly.
