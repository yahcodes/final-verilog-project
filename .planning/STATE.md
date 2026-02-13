# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** Correctly simulate FSM-based 2-player fighting game with shop, in plain Verilog with $display output
**Current focus:** Phase 3 - Win, Restart, and Extra Credit

## Current Position

Phase: 3 of 4 (Win, Restart, and Extra Credit)
Plan: 1 of 2 in current phase
Status: In progress
Last activity: 2026-02-13 - Completed 03-01 (win detection, moves_to_win counter, start_round restart)

Progress: [█████░░░░░] 50%

## Performance Metrics

**Velocity:**
- Total plans completed: 4
- Average duration: ~3 min
- Total execution time: ~12 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-shop-module | 1/1 | ~1 min | ~1 min |
| 02-game-core   | 2/2 | ~10 min | ~5 min |
| 03-win-restart | 1/2 | ~1 min | ~1 min |

**Recent Trend:**
- Last 5 plans: 01-01, 02-01, 02-02, 03-01
- Trend: on track

*Updated after each plan completion*

## Accumulated Context

### Decisions

Decisions are logged in PROJECT.md Key Decisions table.
Recent decisions affecting current work:

- [Init]: distance = p1_pos + p2_pos (avoids global coordinate overlap; makes distance 0 reachable)
- [Init]: action codes 0=Kick, 1=Punch, 2=MoveLeft, 3=MoveRight, 4=Wait (aligns shop items 0-4 with move types)
- [Init]: no separate END state; health=0 jumps immediately to SHOP
- [Init]: move inventory resets to 0 on round restart (no carryover)
- [02-01]: PHASE_SHOP=1'b1, PHASE_PLAY=1'b0 so rst drops into shop
- [02-01]: distance wire is 3 bits to hold range 0..4 without overflow
- [02-01]: shop credit_next/grant_onehot connected as wires in game_top
- [02-01]: discount_mult hardcoded to 7'd100 for Phase 2 (no discount)
- [02-02]: inventory decremented BEFORE distance check (wrong-distance attacks still consume inventory)
- [02-02]: buy task requires 2 posedge cycles (grant latches in shop on edge N, game_top reads on edge N+1)
- [02-02]: health underflow not guarded in PLAY phase (Phase 3 handles win detection)
- [03-01]: win detection fires in same cycle as damaging action (no separate END state)
- [03-01]: moves_to_win increments on every non-err_no_inventory action (all 5 types, both players)
- [03-01]: start_round resets only winner and moves_to_win (health/credit/pos/moves reset in win handler)
- [03-01]: win handler resets all state atomically in same always block

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-13
Stopped at: Completed 03-01 (win detection, moves_to_win, start_round restart)
Resume file: .planning/phases/03-win-restart-and-extra-credit/03-02-PLAN.md
