# Phase 3: Win, Restart, and Extra Credit - Context

**Gathered:** 2026-02-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Add win detection (health=0 → SHOP), winner latching, moves_to_win counter, round restart via start_round, and discount multiplier wiring to existing game_top.v and shop.v. No new ports or modules — only game_top.v and shop.v are modified.

</domain>

<decisions>
## Implementation Decisions

### Win detection timing
- Win detection happens IN THE SAME clock cycle as the damaging move (same posedge always block)
- When opponent health would reach ≤ 0 from an attack, apply win logic immediately:
  - phase → PHASE_SHOP
  - winner latched (2'b01 = P1 won if p2 health dies; 2'b10 = P2 won if p1 health dies)
  - Health underflow guard: check if health ≤ damage BEFORE subtracting (e.g., for Kick: if p2_health == 2'd1, for Punch: if p2_health <= 2'd2)
  - On win: health → 3, credit → 500, pos → 2, moves → 0 for BOTH players (entering SHOP fresh)
  - moves_to_win: do NOT reset at win detection — preserve it through SHOP for discount calculation

### start_round behavior
- start_round fires from INSIDE SHOP to transition to PLAY
- start_round does: phase → PHASE_PLAY, winner → 2'b00, moves_to_win → 0
- Health, credit, pos, and moves are NOT reset by start_round — they were already reset at win detection
- Moves bought in SHOP carry into PLAY (this is the point of the SHOP phase)

### moves_to_win counting rule
- Increment moves_to_win by 1 for EVERY move where err_no_inventory did NOT fire (inventory was consumed)
- Wrong-distance attacks count (inventory consumed, even though no damage)
- Saturated moves count (inventory consumed, even though position didn't change)
- Wait counts (inventory consumed)
- err_no_inventory moves do NOT count (no inventory consumed, no state change)
- Source: PDF section 4 — "هر سیکل PLAY که اکشن معتبر باشد" (each PLAY cycle where the action is valid)

### Discount multiplier
- Discount applies ONLY in the SHOP phase immediately following the win (one round only)
- After start_round fires (winner reset to 2'b00), both players get mult=100 in next SHOP
- Multiplier selection based on moves_to_win at time of win:
  - moves_to_win ≤ 6: mult = 7'd80 (20% off)
  - moves_to_win 7–9: mult = 7'd90 (10% off)
  - moves_to_win ≥ 10: mult = 7'd95 (5% off)
- Only the WINNER gets the discount; loser always gets mult = 7'd100
- Implementation: add wires p1_discount_mult[6:0] and p2_discount_mult[6:0] to game_top.v; wire them to shop instances in place of hardcoded 7'd100

### winner register
- Resets to 2'b00 on start_round (start of each new round)
- Encoding: 2'b00 = no winner (in progress), 2'b01 = P1 won, 2'b10 = P2 won

### Claude's Discretion
- Exact start_round implementation (combinational mux approach or inline in sequential block)
- Whether moves_to_win resets to 0 at win detection or ONLY at start_round (either works since discount only needs it stable through SHOP)
- Health underflow guard approach (compare before decrement, or use separate win check)
- Simultaneous 0-health: game is turn-based so both players cannot reach 0 simultaneously; no special handling needed

</decisions>

<specifics>
## Specific Ideas

- PDF section 4 confirms: "بجای رفتن به END باید مستقیماً وارد SHOP شود" (instead of END state, must enter SHOP directly) — no separate game-over state
- FSM chain per PDF: A → B → C → D(SHOP) → A → … (state D = SHOP, state A = start of PLAY)
- PDF: "در SHOP بازیکن دوباره اعتبار اولیه (۵۰۰ واحد) را خواهد داشت" = credit resets to 500 when entering SHOP
- Discount mux is a combinational block in game_top.v, not in shop.v — shop.v already accepts discount_mult as input

</specifics>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-win-restart-and-extra-credit*
*Context gathered: 2026-02-13*
