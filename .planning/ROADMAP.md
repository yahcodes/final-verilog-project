# Roadmap: Verilog Fighting Game

## Overview

Build a 3-file plain Verilog simulation (shop.v, game_top.v, tb_game.v) of a turn-based 2-player fighting game graded on correct ModelSim/$display output. The work naturally clusters into four phases: an independent shop module, the FSM game core with attack and movement logic, win detection plus round restart plus discount extra credit, and finally the display logging and testbench that verify everything end-to-end.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Shop Module** - Standalone credit/stock/purchase logic in shop.v
- [ ] **Phase 2: Game Core** - Turn-based FSM, position registers, attack and movement execution
- [ ] **Phase 3: Win, Restart, and Extra Credit** - Win detection, round restart, and discount multiplier
- [ ] **Phase 4: Display and Testbench** - $display logging and comprehensive tb_game.v verification

## Phase Details

### Phase 1: Shop Module
**Goal**: Players can buy moves from an independent shop with correct credit deduction, stock management, and all error conditions handled
**Depends on**: Nothing (first phase)
**Requirements**: SHOP-01, SHOP-02, SHOP-03, SHOP-04, SHOP-05
**Success Criteria** (what must be TRUE):
  1. Asserting buy_valid with ActionNumber 0-4 and sufficient credit/stock decrements credit by the item price and decrements shop stock by 1, and asserts grant_onehot for that move
  2. ActionNumber 5-7 triggers err_invalid_action with no change to credit or inventory
  3. A purchase attempt when credit < item price triggers err_credit with no change to credit or inventory
  4. A purchase attempt when shop stock = 0 triggers err_out_of_stock with no change to credit or inventory
**Plans**: TBD

Plans:
- [ ] 01-01: Implement shop.v with localparams, mux pricing, buy_valid logic, and all error outputs

### Phase 2: Game Core
**Goal**: Two players can take turns executing moves (Kick, Punch, MoveLeft, MoveRight, Wait) with correct distance-based damage, position saturation, inventory enforcement, and turn switching
**Depends on**: Phase 1
**Requirements**: GAME-01, GAME-02, GAME-03, GAME-04, GAME-05, GAME-06, GAME-07, GAME-08
**Success Criteria** (what must be TRUE):
  1. Only the active player (selected by turn signal) can change any state each clock cycle; the inactive player's registers are unaffected
  2. Kick at distance=1 reduces opponent health by 1; Punch at distance=0 reduces opponent health by 2; attacks at wrong distances deal no damage
  3. MoveLeft and MoveRight adjust the active player's position register with saturation (clamped at 0 and 2, no wrap)
  4. Executing any action with that move's counter at 0 triggers an error and changes no state; executing with counter > 0 decrements that move's counter by 1
  5. Wait consumes one Wait counter but leaves all position and health state unchanged
**Plans**: TBD

Plans:
- [ ] 02-01: Implement game_top.v FSM skeleton with PLAY/SHOP phases, health registers, position registers, and turn signal
- [ ] 02-02: Implement attack logic (Kick/Punch with distance check) and movement logic (MoveLeft/MoveRight with saturation) and Wait; wire in move inventory enforcement

### Phase 3: Win, Restart, and Extra Credit
**Goal**: The game detects wins, supports full round restart, and applies a correct discount to the winner's next shop prices based on moves_to_win
**Depends on**: Phase 2
**Requirements**: WIN-01, WIN-02, WIN-03, EC-01, EC-02
**Success Criteria** (what must be TRUE):
  1. When a player's health reaches 0, the phase register immediately transitions to SHOP and the winner register is latched
  2. The moves_to_win counter increments by exactly 1 for each valid move executed during PLAY (invalid/no-op moves do not increment it)
  3. On a start_round pulse, both players' health resets to 3, credit to 500, position to 2, all move inventories to 0, moves_to_win to 0, and phase to PLAY
  4. In the SHOP phase following a win, the winner's shop prices reflect the discount: 20% off (mult=80) for moves_to_win <= 6, 10% off (mult=90) for 7-9, 5% off (mult=95) for 10+; the loser pays full price (mult=100)
**Plans**: TBD

Plans:
- [ ] 03-01: Implement win detection, winner latch, moves_to_win counter, and start_round restart logic in game_top.v
- [ ] 03-02: Implement discount mux in shop.v wired to moves_to_win and winner identity; verify loser always gets mult=100

### Phase 4: Display and Testbench
**Goal**: Every simulation tick and shop event is logged via $display, and tb_game.v exercises all specified scenarios with visible pass/fail output
**Depends on**: Phase 3
**Requirements**: DISP-01, DISP-02, TB-01
**Success Criteria** (what must be TRUE):
  1. After every clock tick, $display prints phase, turn, both players' health, credit, position, and move counters in a readable format
  2. After every shop event, $display prints ActionNumber, price, discounted price, success or specific error type, updated stock, and updated inventory
  3. Simulating tb_game.v in ModelSim/Icarus produces visible output that covers: invalid action error, insufficient credit error, out-of-stock error, movement saturation at both edges, punch at distance 0 dealing 2 damage, kick at distance 1 dealing 1 damage, a full win path with correct winner output, and all three discount bands
**Plans**: TBD

Plans:
- [ ] 04-01: Add all $display statements to shop.v and game_top.v (tick log and shop event log)
- [ ] 04-02: Write tb_game.v with task helpers covering all required scenarios; run full simulation and confirm output

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Shop Module | 0/1 | Not started | - |
| 2. Game Core | 0/2 | Not started | - |
| 3. Win, Restart, and Extra Credit | 0/2 | Not started | - |
| 4. Display and Testbench | 0/2 | Not started | - |
