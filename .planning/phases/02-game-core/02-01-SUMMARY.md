---
phase: 02-game-core
plan: 01
subsystem: game-logic
tags: [verilog, fsm, shop, registers, game-top]

# Dependency graph
requires:
  - phase: 01-shop-module
    provides: shop.v module with buy_valid/credit/grant_onehot interface
provides:
  - game_top.v FSM skeleton with full port interface, registers, and two shop instances
affects: [02-game-core-plan02]

# Tech tracking
tech-stack:
  added: []
  patterns: [plain-verilog-2001, unpacked-reg-arrays, module-instantiation]

key-files:
  created: [game_top.v]
  modified: []

key-decisions:
  - "PHASE_SHOP=1 PHASE_PLAY=0 to reset into shop; start_round flips to play"
  - "credit_next and grant_onehot wires connect shop outputs; credit latched each SHOP cycle"
  - "discount_mult hardcoded to 7'd100 (no discount in phase 2)"
  - "distance computed as 3-bit wire: {1'b0,p1_pos}+{1'b0,p2_pos} to hold range 0..4"

patterns-established:
  - "All shop wire outputs declared as wire in parent, driven by output reg in shop module"
  - "Move counters incremented per grant_onehot bit using 5 individual if-statements"
  - "PLAY stub left empty for Plan 02 to fill in"

# Metrics
duration: 1min
completed: 2026-02-13
---

# Phase 2 Plan 01: Game Top FSM Skeleton Summary

**game_top.v with full port interface, phase FSM (SHOP/PLAY), player registers, and two shop instances wired for credit and move-inventory tracking**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-13T22:51:43Z
- **Completed:** 2026-02-13T22:52:37Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created game_top.v with complete port interface (13 inputs, 18 outputs)
- Phase FSM resets to PHASE_SHOP (1'b1), transitions to PHASE_PLAY (1'b0) on start_round
- All player state registers with correct reset values: health=3, credit=500, pos=2, moves=0
- Two shop instances (shop_p1, shop_p2) instantiated with correct port wiring and discount_mult=7'd100
- SHOP phase latches p1/p2 credit from credit_next and increments move counters via grant_onehot
- PLAY phase stub ready for Plan 02 game logic

## Task Commits

Each task was committed atomically:

1. **Task 1: Create game_top.v module skeleton with registers and shop wiring** - `ff9fe26` (feat)

**Plan metadata:** (committed with docs commit below)

## Files Created/Modified
- `/Users/alireza/Documents/Claude/Yahya/game_top.v` - Full game FSM skeleton: ports, registers, shop instances, SHOP/PLAY phase logic

## Decisions Made
- PHASE_SHOP=1'b1 so module resets into shop on rst, PHASE_PLAY=1'b0 for active round
- distance wire is 3 bits wide ({1'b0,p1_pos}+{1'b0,p2_pos}) to safely hold 0..4 without overflow
- shop credit_out and grant_onehot connected as wires in game_top (output reg inside shop module is valid Verilog)
- discount_mult hardcoded to 7'd100 (full price, no discount for Phase 2)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- game_top.v compiles cleanly with shop.v (iverilog exit 0)
- PLAY stub is in place; Plan 02 can directly fill in combat/movement/win logic
- All registers and move arrays initialized correctly for Plan 02 action processing

---
*Phase: 02-game-core*
*Completed: 2026-02-13*
