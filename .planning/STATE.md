# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-13)

**Core value:** Correctly simulate FSM-based 2-player fighting game with shop, in plain Verilog with $display output
**Current focus:** Phase 2 - Game Core (complete)

## Current Position

Phase: 2 of 4 (Game Core)
Plan: 2 of 2 in current phase
Status: Phase complete
Last activity: 2026-02-13 - Completed 02-02-PLAN.md (PLAY phase action logic + testbench)

Progress: [████░░░░░░] 40%

## Performance Metrics

**Velocity:**
- Total plans completed: 3
- Average duration: ~4 min
- Total execution time: ~11 min

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| 01-shop-module | 1/1 | ~1 min | ~1 min |
| 02-game-core   | 2/2 | ~10 min | ~5 min |

**Recent Trend:**
- Last 5 plans: 01-01, 02-01, 02-02
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

### Pending Todos

None.

### Blockers/Concerns

None.

## Session Continuity

Last session: 2026-02-13
Stopped at: Completed 02-02 (PLAY phase action logic + tb_game_core.v)
Resume file: .planning/phases/03-win-detection/ (next phase)
