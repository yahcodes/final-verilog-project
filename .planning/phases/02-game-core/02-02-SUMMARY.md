---
phase: 02-game-core
plan: 02
subsystem: game-logic
tags: [verilog, fsm, testbench, iverilog, fighting-game]

# Dependency graph
requires:
  - phase: 02-01
    provides: game_top.v skeleton with registers, shop wiring, and PLAY phase stub
  - phase: 01-shop-module
    provides: shop.v module with purchase_success, grant_onehot, credit_out outputs
provides:
  - Complete PLAY phase action logic (Kick, Punch, MoveLeft, MoveRight, Wait)
  - tb_game_core.v testbench verifying all GAME-01 through GAME-08 requirements
affects: [03-win-detection, 04-display]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Inventory-first: check move counter before executing any action"
    - "Two-register pipeline: shop grant_onehot registered in shop, read in game_top on next cycle"
    - "Distance check after inventory decrement: counter decrements even on wrong-distance attempts"
    - "Turn-based isolation: outer if(turn) branch ensures only active player registers are touched"

key-files:
  created: [tb_game_core.v]
  modified: [game_top.v]

key-decisions:
  - "[02-02]: Inventory decremented BEFORE distance check — wrong-distance attacks still consume inventory"
  - "[02-02]: Buy task needs 2 posedge cycles: grant latches in shop on edge N, game_top reads it on edge N+1"
  - "[02-02]: P1 purchase budget 500 exactly: 2xKick(200)+2xPunch(200)+2xMoveRight(100)=500"
  - "[02-02]: P2 purchase budget 120: 2xMoveLeft(100)+1xWait(20)"

patterns-established:
  - "task buy_p1/buy_p2: 2-cycle purchase pattern (assert, posedge, deassert, posedge)"
  - "task do_play: single action, sample #1 after posedge"
  - "task do_reset / do_start: named transitions for readability"

# Metrics
duration: 9min
completed: 2026-02-13
---

# Phase 2 Plan 02: PLAY Phase Action Logic Summary

**PLAY phase complete: inventory-enforced Kick/Punch/MoveLeft/MoveRight/Wait with distance damage and 2-cycle buy pipeline, verified by 24-check testbench covering GAME-01 through GAME-08**

## Performance

- **Duration:** ~9 min
- **Started:** 2026-02-13T23:00:50Z
- **Completed:** 2026-02-13T23:09:58Z
- **Tasks:** 2 of 2
- **Files modified:** 2 (game_top.v modified, tb_game_core.v created)

## Accomplishments
- Replaced PLAY phase stub in game_top.v with complete action logic for all 5 action types
- Implemented inventory check first, then distance check for Kick and Punch
- Testbench verifies all 8 GAME requirements with 24 individual checks (all PASS)
- Discovered and correctly handled the 2-cycle grant pipeline between shop and game_top

## Task Commits

Each task was committed atomically:

1. **Task 1: Implement PLAY phase action logic** - `c5cb7c2` (feat)
2. **Task 2: Write tb_game_core.v** - `04d6017` (feat)

## Files Created/Modified
- `game_top.v` - PLAY phase stub replaced with full Kick/Punch/MoveLeft/MoveRight/Wait logic including inventory enforcement, distance checks, position saturation, and error flags
- `tb_game_core.v` - Testbench covering GAME-01 through GAME-08 with 24 assertions all passing

## Decisions Made
- Inventory decrements before the distance check (wrong-distance attacks consume inventory, confirmed by GAME-08 spec: "Kick/Punch at wrong distance deals no damage but consumes inventory")
- Test budget: P1 buys 2xKick+2xPunch+2xMoveRight=500 (exact budget). Needed 2x Punch to demonstrate both wrong-distance punch (GAME-02) AND correct-distance punch (GAME-04) in same test run.
- The shop module has a 1-cycle pipeline: grant_onehot latches in shop on posedge N, game_top reads it on posedge N+1. Each buy_p1/buy_p2 task waits 2 posedges to ensure the move counter is incremented before proceeding.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Testbench purchase budget exceeded original plan**
- **Found during:** Task 2 (writing testbench)
- **Issue:** Original plan said "2x Kick, 1x Punch, 2x MoveRight, 1x MoveLeft, 1x Wait" for P1 totalling 520 > 500 credits. Also, with 1x Punch it's impossible to test both wrong-distance Punch (GAME-02) and correct-distance Punch (GAME-04) in the same round.
- **Fix:** Changed P1 to buy 2xKick+2xPunch+2xMoveRight=500 (exact budget, drops MoveLeft and extra Wait). Changed P2 to 2xMoveLeft+1xWait=120 to enable P2 reaching pos=0 for the distance=0 punch test.
- **Files modified:** tb_game_core.v
- **Verification:** All 24 test assertions pass, simulation ends with "--- tb_game_core complete ---"
- **Committed in:** 04d6017 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (budget + test sequencing correction)
**Impact on plan:** Fix was necessary for all 8 game requirements to be demonstrable. No scope creep.

## Issues Encountered
- shop.v grant_onehot pipeline delay: the buy task required 2 clock cycles (not 1) per purchase. The shop registers grant_onehot on posedge N; game_top reads it and increments the move counter on posedge N+1. Testbench task correctly handles this with a 2-posedge sequence.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- game_top.v PLAY phase is complete and tested
- All 8 core game mechanics verified (inventory, distance damage, movement, wait, error flags)
- Ready for Phase 3: win detection (health reaches 0 should trigger transition back to SHOP or winner output)
- One known gap: health underflow is not guarded (plan specifies Phase 3 handles win detection)

---
*Phase: 02-game-core*
*Completed: 2026-02-13*

## Self-Check: PASSED

- game_top.v: FOUND
- tb_game_core.v: FOUND
- 02-02-SUMMARY.md: FOUND
- Commit c5cb7c2: FOUND
- Commit 04d6017: FOUND
- iverilog compilation: CLEAN
