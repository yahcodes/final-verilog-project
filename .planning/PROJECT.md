# Verilog Fighting Game

## What This Is

A 2-player turn-based fighting game implemented in Verilog for a Logic Circuits (مدارهای منطقی) end-of-term project. Two players occupy 3 tiles each on a shared battlefield, using FSM-based position states. Players buy moves from an independent Shop module, then take turns executing attacks (Kick, Punch) and movements (MoveLeft, MoveRight, Wait) against each other until one player's health hits zero.

## Core Value

The game must simulate correctly in ModelSim/Icarus with $display output that clearly shows every state change — shop purchases, move execution, health changes, and win detection. This is what gets graded.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Shop module (`shop.v`): independent per player, handles credit, stock, pricing via mux, purchase success/error logic
- [ ] Game top module (`game_top.v`): FSM with PLAY/SHOP phases, health registers, position registers, move inventory counters, turn switching
- [ ] Player FSM: each player has 3 position states (POS0/POS1/POS2) + SHOP state; positions encode distance from center
- [ ] Move inventory: players must buy moves before using them; usage decrements counter; zero-count = error
- [ ] Attack logic: Kick deals -1 at distance 1, Punch deals -2 at distance 0; distance = p1_pos + p2_pos
- [ ] Win detection: health reaches 0 → winner output asserted, transition to SHOP
- [ ] Extra credit — Round restart: SHOP phase resets health/credit/position/moves_to_win on start_round pulse
- [ ] Extra credit — Win discount: moves_to_win counter drives discount mux (≤6→20%, 7-9→10%, else→5%) applied to winner's prices next SHOP
- [ ] Testbench (`tb_game.v`): covers shop errors, movement saturation, punch/kick distance scenarios, win path, discount bands
- [ ] $display logging: prints phase, turn, health, credit, position, move counters after every action or purchase

### Out of Scope

- SystemVerilog features (interfaces, classes, assertions) — plain Verilog only per course level
- Graphical output — simulation only
- Networking or multi-file synthesis targets
- More than 2 players

## Context

- Course: Logic Circuits (مدارهای منطقی), Professor Dr. Sara Ershadi-Nasab, Fall 1404
- Target simulator: ModelSim or Icarus Verilog
- Code must look like strong 3rd-year student work: clean localparams, proper module boundaries, good $display — not over-engineered
- The PDF spec is the ground truth; the markdown PRD in `verilog/verilog_prd_implementation_plan.md` has already resolved ambiguities (distance encoding, action mapping, discount multipliers)

## Constraints

- **Style**: Plain Verilog (not SystemVerilog) — `reg`, `wire`, `always @(posedge clk)`, `task` for TB helpers
- **Bit widths**: health 2-bit (0–3), credit 10-bit (0–500+), position 2-bit (0–2), move counters 4-bit
- **Module count**: exactly 3 files — `shop.v`, `game_top.v`, `tb_game.v`

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Distance = p1_pos + p2_pos | Avoids global coordinate overlap issue; makes distance 0 reachable | — Pending |
| Action codes: 0=Kick, 1=Punch, 2=MoveLeft, 3=MoveRight, 4=Wait | Aligns shop items 0–4 with move types | — Pending |
| No separate END state | Spec says jump to SHOP immediately when health hits 0 | — Pending |
| Move inventory resets to 0 on round restart | Most natural; avoids carryover ambiguity | — Pending |

---
*Last updated: 2026-02-13 after initialization*
