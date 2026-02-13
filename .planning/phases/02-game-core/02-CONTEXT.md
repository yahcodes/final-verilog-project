# Phase 2: Game Core - Context

**Gathered:** 2026-02-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Implement `game_top.v` — the top-level module that holds all game registers, instantiates both shop modules, runs the PLAY/SHOP FSM, processes player actions (Kick, Punch, MoveLeft, MoveRight, Wait), enforces move inventory, applies damage at the correct distances, and manages position with saturation. Win detection and round restart (`start_round`) are Phase 3 — this phase builds the structure they'll hook into.

</domain>

<decisions>
## Implementation Decisions

### Movement direction semantics
- MoveLeft = move to the left tile on screen (screen-absolute, per PDF spec)
- MoveRight = move to the right tile on screen (screen-absolute)
- Effect on pos encoding (distance from center, 0=edge, 2=far):
  - P1 (left side): MoveLeft → pos++ (away from center), MoveRight → pos-- (toward center)
  - P2 (right side): MoveLeft → pos-- (toward center), MoveRight → pos++ (away from center)
- Saturation: pos clamps at [0, 2], no wrap
- Saturated move still executes (consumes inventory) even if position doesn't change

### Turn policy
- `turn` is an **external input** port on game_top.v — the testbench drives it
- game_top.v only executes the active player's action (ignores inactive player inputs)
- Turn is NOT toggled internally by game_top.v; TB advances it only after a valid move executes
- Consequence: if a move fails (no inventory), TB does NOT flip turn — same player tries again

### game_top.v port interface
**Inputs:**
- `clk`, `rst`
- `turn` — 0=P1 active, 1=P2 active (TB-driven)
- `play_valid` — asserted for 1 cycle when active player wants to execute a move
- `play_action[2:0]` — action code for active player (shared, turn-muxed)
- `buy_valid_p1`, `buy_code_p1[2:0]` — P1 shop purchase
- `buy_valid_p2`, `buy_code_p2[2:0]` — P2 shop purchase
- `start_round` — Phase 3 will add this; stub input for now
- Prices: `Price0`–`Price4` [9:0] (shared for both shops, per spec)

**Outputs:**
- `phase` — current FSM phase (0=PLAY, 1=SHOP or use localparams)
- `p1_health[1:0]`, `p2_health[1:0]`
- `p1_credit[9:0]`, `p2_credit[9:0]`
- `p1_pos[1:0]`, `p2_pos[1:0]`
- `winner[1:0]` — Phase 3 latches this; output 0 until then
- Shop error passthrough: `err_invalid_action_p1/p2`, `err_credit_p1/p2`, `err_out_of_stock_p1/p2`, `purchase_success_p1/p2`
- Play errors: `err_no_inventory` (active player tried move with counter=0), `err_wrong_distance` (Kick/Punch used at wrong distance — move still consumed, no damage)

### PLAY error outputs
- Claude's discretion on exact naming; single shared flags (active player's status), turn disambiguates
- `err_no_inventory`: active player's action_code counter = 0 → no state change, no decrement
- `err_wrong_distance`: Kick not at distance=1, or Punch not at distance=0 → move consumed, no damage applied

### Starting phase
- On `rst`: `phase` = SHOP (buy moves first, then play)
- SHOP → PLAY transition: triggered by `start_round` pulse (Phase 3 will drive this from TB)
- For Phase 2 testing, TB will assert `start_round` manually to enter PLAY

### FSM states
- `PHASE_SHOP = 1'b1`, `PHASE_PLAY = 1'b0` (1-bit phase register, or use localparams)
- In SHOP: shop purchases process; play_action ignored
- In PLAY: shop purchases ignored; play_action + play_valid drives game logic
- PLAY→SHOP transition: when a player's health reaches 0 (Phase 3 implements this; in Phase 2, can leave PLAY→SHOP path as a stub)

### Register widths (confirmed from PRD)
- Health: `[1:0]` — values 0..3
- Credit: `[9:0]` — up to 1023
- Position: `[1:0]` — values 0..2
- Move counters `p1_moves[0:4]`, `p2_moves[0:4]`: `[3:0]` — bought in single digits
- `moves_to_win`: `[3:0]` — increments once per valid PLAY move (Phase 3 uses this)
- `winner`: `[1:0]` — 2'b00=none, 2'b01=P1, 2'b10=P2

### Shop wiring
- Two `shop` instances: `shop_p1` and `shop_p2`
- Both receive shared Price0–Price4
- `grant_onehot[4:0]` from each shop increments the respective player's move counter for that action
- `credit_out` from each shop feeds back to game_top's credit register each cycle (pass-through on no purchase)
- discount_mult: hardcoded to 7'd100 in Phase 2; Phase 3 wires in moves_to_win-based discount

</decisions>

<specifics>
## Specific Ideas

- PDF specifies SHOP as a state in the FSM for each player: states A, B, C, D(SHOP) for P1; E, F, G, D(SHOP) for P2 — game_top wraps both into a single `phase` register
- PDF: "Game over is no longer a separate state — health=0 → directly SHOP" (no END state, confirmed)
- PDF: Prices and shop quantities can be set in the testbench initially
- Distance computation: `distance = p1_pos + p2_pos` (combinational, each tick)

</specifics>

<deferred>
## Deferred Ideas

- Win detection + health=0 → SHOP transition — Phase 3
- `start_round` full reset logic (health→3, credit→500, pos→2, moves→0) — Phase 3
- `moves_to_win` incrementing and discount multiplier computation — Phase 3
- `$display` logging — Phase 4
- V2-01: Alternate first player each round — v2 backlog
- V2-02: Persistent move inventory across rounds — v2 backlog

</deferred>

---

*Phase: 02-game-core*
*Context gathered: 2026-02-13*
