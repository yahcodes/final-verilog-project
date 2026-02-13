---
phase: "03"
plan: "01"
subsystem: game_top
tags: [win-detection, moves_to_win, health-underflow-guard, start_round, fsm]
dependency_graph:
  requires: [02-02-SUMMARY]
  provides: [win-detection, moves_to_win-counter, round-restart]
  affects: [game_top.v]
tech_stack:
  added: []
  patterns: [underflow-guard-with-win-jump, atomic-round-reset-on-win]
key_files:
  created: []
  modified:
    - game_top.v
decisions:
  - Win detection fires in same clock cycle as the damaging action (no separate END state)
  - moves_to_win increments on every non-err_no_inventory action (Kick, Punch, Left, Right, Wait for both players)
  - start_round resets only winner and moves_to_win (not health/pos/credit — those were already reset in win handler)
  - Win resets all game state atomically in same always block: phase, winner, health, credit, pos, all move inventories
metrics:
  duration: "~72 seconds"
  completed: "2026-02-13"
  tasks_completed: 1/1
---

# Phase 3 Plan 01: Win Detection, moves_to_win Counter, start_round Restart Summary

Added win detection with health underflow guards, a moves_to_win counter, and start_round reset logic to game_top.v.

## What Was Done

### Changes Applied to game_top.v

**1. Added `moves_to_win` register** (line 53)
```verilog
reg [3:0] moves_to_win;
```

**2. Reset in rst block** (line 128)
```verilog
moves_to_win <= 4'd0;
```

**3-4. P1 Kick and Punch — win-guarded**
Both attack branches now increment `moves_to_win`, then check health threshold before deciding whether to register a win or apply damage:
- Kick: fires at `distance==1`, wins if `p2_health <= 1`, else `p2_health <= p2_health - 1`
- Punch: fires at `distance==0`, wins if `p2_health <= 2`, else `p2_health <= p2_health - 2`

On win: sets `phase=PHASE_SHOP`, `winner=2'b01`, resets health/credit/pos/all moves to initial values atomically.

**5. P1 movement branches (Left, Right, Wait)** — each `else` branch now opens with `moves_to_win <= moves_to_win + 4'd1;`

**6-7. P2 Kick and Punch — win-guarded** (symmetric to P1)
- Kick: `p1_health <= 1` triggers win, `winner=2'b10`
- Punch: `p1_health <= 2` triggers win, `winner=2'b10`

**8. P2 movement branches (Left, Right, Wait)** — same `moves_to_win` increment added.

**9. start_round handler updated**
```verilog
if (start_round) begin
    phase <= PHASE_PLAY;
    winner <= 2'b00;
    moves_to_win <= 4'd0;
end
```

## Compile Verification

```
$ iverilog -o /dev/null shop.v game_top.v
EXIT: 0
```

Zero errors. Zero warnings.

## Key Decisions

**Win detection in same cycle as damaging action:**
The FSM does not have a separate END state. When a lethal hit is applied, the `phase`, `winner`, and all reset signals are latched in the same posedge that processes the action. This keeps the FSM minimal and consistent with the original design note "[Init]: no separate END state; health=0 jumps immediately to SHOP".

**moves_to_win increments on all non-err_no_inventory moves:**
Any action that successfully executes (inventory was available) — including movement and wait — counts toward `moves_to_win`. Only actions that fail with `err_no_inventory` are excluded. This gives a complete move count from round start to win.

**start_round resets winner and moves_to_win only:**
Health, credit, positions, and move inventories were already reset atomically inside the win handler. The start_round handler only clears the per-round bookkeeping (winner, moves_to_win) and transitions to PHASE_PLAY. This avoids double-resetting state that was already reset when the round ended.

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

- FOUND: game_top.v
- FOUND: .planning/phases/03-win-restart-and-extra-credit/03-01-SUMMARY.md
- FOUND: commit 71ee028
