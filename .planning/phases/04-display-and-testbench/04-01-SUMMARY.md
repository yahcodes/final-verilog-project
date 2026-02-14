---
phase: "04"
plan: "01"
subsystem: "display-logging"
tags: ["display", "simulation", "shop", "game_top", "verilog"]
dependency_graph:
  requires: ["03-01", "03-02"]
  provides: ["04-02"]
  affects: ["shop.v", "game_top.v"]
tech_stack:
  added: []
  patterns: ["$display in sequential always block", "conditional ternary in $display format string"]
key_files:
  created: []
  modified:
    - shop.v
    - game_top.v
decisions:
  - "[04-01]: [SHOP] display uses inline subtraction (shop_stock[N]-1) to show post-transaction stock since NBAs are not yet applied when $display executes in same always block"
  - "[04-01]: [PLAY] display placed inside PLAY else block after if(play_valid) closes, so it only fires when play_valid is active"
  - "[04-01]: [TICK] display placed at end of outer non-reset else branch (after both SHOP and PLAY phases), firing on every non-reset posedge clk"
metrics:
  duration: "~1 min"
  completed: "2026-02-14"
  tasks_completed: 2
  tasks_total: 2
---

# Phase 4 Plan 01: Add $display Logging to shop.v and game_top.v Summary

**One-liner:** Three simulation trace statements added — [SHOP] per-buy event log in shop.v, [PLAY] per-action log and [TICK] full-state snapshot in game_top.v.

## What Was Built

### [SHOP] event log (shop.v)

Added inside the `else` (non-reset) branch of the sequential always block, firing whenever `buy_valid` is asserted:

```verilog
if (buy_valid) begin
    $display("[SHOP] Action=%0d Price=%0d Discounted=%0d | %s | Stock=[%0d,%0d,%0d,%0d,%0d]",
        action_number, price_selected, discounted_price,
        purchase_success   ? "SUCCESS" :
        err_invalid_action ? "ERR_INVALID_ACTION" :
        err_credit         ? "ERR_CREDIT" :
        err_out_of_stock   ? "ERR_OUT_OF_STOCK" : "NONE",
        (purchase_success && action_number==0) ? shop_stock[0]-1 : shop_stock[0],
        ...);
end
```

The stock values use inline subtraction to reflect post-transaction state, since non-blocking assignments haven't been applied yet at the time $display executes.

### [PLAY] action log (game_top.v)

Added after the `if (play_valid) begin ... end` block closes, still inside the PLAY phase else block (lines 346-349):

```verilog
if (play_valid) begin
    $display("[PLAY] P%0d Action=%0d dist=%0d",
        turn ? 2 : 1, play_action, distance);
end
```

Fires only when `play_valid` is asserted. Shows the acting player, action code, and current distance.

### [TICK] full-state snapshot (game_top.v)

Added at the tail end of the outer non-reset else branch, after both SHOP and PLAY phase blocks (lines 353-357):

```verilog
$display("[TICK] Phase=%s Turn=P%0d | P1: hp=%0d cr=%0d pos=%0d mv=[%0d,%0d,%0d,%0d,%0d] | P2: hp=%0d cr=%0d pos=%0d mv=[%0d,%0d,%0d,%0d,%0d] | winner=%0d mtw=%0d",
    phase ? "SHOP" : "PLAY", turn ? 2 : 1,
    p1_health, p1_credit, p1_pos, p1_moves[0],...,p1_moves[4],
    p2_health, p2_credit, p2_pos, p2_moves[0],...,p2_moves[4],
    winner, moves_to_win);
```

Fires on every non-reset posedge clk, providing a full state snapshot for tracing.

## Verification

Both compile with zero errors:

```
iverilog -o /dev/null shop.v                   # exit 0
iverilog -o /dev/null shop.v game_top.v        # exit 0
```

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add [SHOP] $display to shop.v | e333909 | shop.v |
| 2 | Add [PLAY] and [TICK] $display to game_top.v | 1baa25e | game_top.v |

## Deviations from Plan

None - plan executed exactly as written.

## Self-Check: PASSED

- shop.v modified: confirmed present and compiles
- game_top.v modified: confirmed present and compiles
- Commits e333909 and 1baa25e: confirmed in git log
