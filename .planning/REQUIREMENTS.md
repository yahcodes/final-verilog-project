# Requirements: Verilog Fighting Game

**Defined:** 2026-02-13
**Core Value:** Correctly simulate FSM-based 2-player fighting game with shop, in plain Verilog with $display output

## v1 Requirements

### Shop Module

- [ ] **SHOP-01**: Player can attempt to buy a move by asserting buy_valid with ActionNumber[2:0] (0–4 are valid items)
- [ ] **SHOP-02**: ActionNumber 5–7 triggers err_invalid_action; credit and inventory unchanged
- [ ] **SHOP-03**: If credit < item price, triggers err_credit; credit and inventory unchanged
- [ ] **SHOP-04**: If shop stock for item = 0, triggers err_out_of_stock; credit and inventory unchanged
- [ ] **SHOP-05**: Successful purchase decrements credit by item price, decrements shop stock by 1, asserts grant_onehot for that move

### Game Core

- [ ] **GAME-01**: Game is turn-based; only the active player (selected by turn signal) can change state each clock
- [ ] **GAME-02**: Each player's position encoded as distance from center (0=at edge, 2=far); stored in 2-bit register
- [ ] **GAME-03**: Kick (action 0) at distance=1 deals 1 damage to opponent health
- [ ] **GAME-04**: Punch (action 1) at distance=0 deals 2 damage to opponent health
- [ ] **GAME-05**: MoveLeft (action 2) and MoveRight (action 3) adjust position with saturation (no wrap)
- [ ] **GAME-06**: Wait (action 4) leaves all state unchanged but consumes the move
- [ ] **GAME-07**: Using any action with move counter = 0 triggers error; no state changes, no counter decrement
- [ ] **GAME-08**: Using a valid action with inventory > 0 decrements that move's counter by 1

### Win and Round Restart

- [ ] **WIN-01**: When any player's health reaches 0, phase immediately transitions to SHOP; winner register latched
- [ ] **WIN-02**: moves_to_win counter increments by 1 for each valid move executed during PLAY phase
- [ ] **WIN-03**: On start_round pulse: both players' health → 3, credit → 500, position → 2, move inventories → 0, moves_to_win → 0, phase → PLAY

### Extra Credit

- [ ] **EC-01**: Winner's discount for next SHOP: moves_to_win ≤ 6 → 20% off (mult=80), 7–9 → 10% off (mult=90), else → 5% off (mult=95)
- [ ] **EC-02**: Discount applied via multiplier in shop module; loser always pays full price (mult=100)

### Display / Testbench

- [ ] **DISP-01**: $display after every clock tick shows: phase, turn, health, credit, position, move counters for both players
- [ ] **DISP-02**: $display on shop events shows: ActionNumber, price, discounted price, success or specific error, updated stock and inventory
- [ ] **TB-01**: Testbench covers: invalid action, insufficient credit, out-of-stock, movement saturation, punch at distance 0, kick at distance 1, win path with correct winner output, discount bands

## v2 Requirements

### Enhancements

- **V2-01**: Alternate which player goes first each new round
- **V2-02**: Persistent move inventory across rounds (carryover)

## Out of Scope

| Feature | Reason |
|---------|--------|
| SystemVerilog features | Plain Verilog per course level |
| Graphical/waveform-only verification | $display is primary output |
| More than 2 players | Spec is fixed at 2 |
| Network or external I/O | Simulation only |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHOP-01 | Phase 1 | Pending |
| SHOP-02 | Phase 1 | Pending |
| SHOP-03 | Phase 1 | Pending |
| SHOP-04 | Phase 1 | Pending |
| SHOP-05 | Phase 1 | Pending |
| GAME-01 | Phase 2 | Pending |
| GAME-02 | Phase 2 | Pending |
| GAME-03 | Phase 2 | Pending |
| GAME-04 | Phase 2 | Pending |
| GAME-05 | Phase 2 | Pending |
| GAME-06 | Phase 2 | Pending |
| GAME-07 | Phase 2 | Pending |
| GAME-08 | Phase 2 | Pending |
| WIN-01 | Phase 3 | Pending |
| WIN-02 | Phase 3 | Pending |
| WIN-03 | Phase 3 | Pending |
| EC-01 | Phase 3 | Pending |
| EC-02 | Phase 3 | Pending |
| DISP-01 | Phase 4 | Pending |
| DISP-02 | Phase 4 | Pending |
| TB-01 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 21 total
- Mapped to phases: 21
- Unmapped: 0 ✓

---
*Requirements defined: 2026-02-13*
*Last updated: 2026-02-13 after initial definition*
