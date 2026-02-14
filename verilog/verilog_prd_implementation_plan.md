Below is a clean **PRD + implementation plan** for the Verilog project spec in your PDF fileciteturn0file0, written at the level of a strong 3rd-year CS student who wants an A+. I’m going to make a few explicit design choices where the PDF is ambiguous, and I’ll flag them so you can keep or change them.

---

## 1) PRD (Product Requirements Document)

### 1.1 Goal
Build a **2-player turn-based fighting game** in Verilog using:
- **Two player FSMs** (positions as states)
- A **Shop** per player (independent, no shared signals/state)
- **Counters/registers** for credits, health, move inventory, shop stock
- Clear **error reporting** + `$display` logging after purchases and moves

### 1.2 Core Gameplay Requirements (from spec)
**Players and positions**
- Two players, each has **3 tiles** on their own side. (Illustration shows `A B C | G F E`.)  
- Each player can only move within their own 3 tiles.
- Game is **turn-based** using `Turn`. Only the active player’s input affects state that clock.

**Health**
- Each player starts with **3 health**.
- Game ends when a player’s health reaches **0**.
- If a move causes damage, the health decrement happens **in the same clock tick** the move executes.

**Moves (5 total)**
- `Kick`: if “distance” = 1 → opponent health −= 1  
- `Punch`: if “distance” = 0 → opponent health −= 2  
- `Move left`: reposition only (no damage)  
- `Move right`: reposition only (no damage)  
- `Wait`: no change (no damage)

**Move inventory**
- Players must **buy moves** first.
- Each move has a **counter per player** (how many times you can use it).
- If the player tries a move with counter = 0 → **error** and nothing changes.

### 1.3 Shop Requirements
Each player has an independent Shop module.

**Credit**
- Each player starts with **500 credit**.
- On successful purchase: credit decreases by item price.
- If purchase fails: credit and inventory do not change.

**ActionNumber**
- `ActionNumber[2:0]` selects item:
  - `0..4` valid items
  - `5..7` invalid → error “invalid action”, no purchase

**Pricing**
- There are 5 price inputs: `Price0..Price4`
- Use a mux driven by `ActionNumber` to get selected price.

**Shop stock**
- Each of the 5 items has a **shop stock counter**:
  - On successful purchase: shop stock of that item decrements by 1
  - If stock is 0: cannot buy, error “out of stock”

**Purchase success conditions**
Purchase happens only if all are true:
1) Action valid (0..4)  
2) Player credit ≥ item price  
3) Shop stock > 0  

Outputs:
- `success_purchase`
- Error flags: invalid action, insufficient credit, out of stock

**Important extra behavior (implied by gameplay)**
A successful purchase must also **increase the player’s move inventory counter** for that move. (Otherwise “buying moves” has no effect.)

### 1.4 Extra Credit (Round restart + discount)
Add a `SHOP` state into the cycle so the game becomes:

**Start in SHOP → PLAY until someone wins → SHOP → start new round → ...**

Key rules:
- **No separate END state**. If someone reaches 0 health at any point, jump directly to SHOP and start a new round from there.
- In SHOP, **reset** (synchronously with clock + enable):
  - both players’ health back to 3
  - credit back to 500
  - positions back to start
  - (recommended) reset player move inventories to 0 unless your instructor expects carryover (most likely reset)

**Discount**
Track number of **valid moves until win** with a counter (call it `moves_to_win`).
When someone wins, compute discount for winner in the next SHOP:
- win in ≤ 6 moves → **20%** off  
- win in 7..9 moves → **10%** off  
- otherwise → **5%** off  

Discount applies **only in SHOP** on prices for the winner.

### 1.5 Display / Logging Requirements
Use `$display` to print:
- each player: health, credit, position, move inventory counts
- shop: item prices, shop stock counters, attempted purchases, success/error
- after each move or purchase: print what changed + error messages

### 1.6 Assumptions (you can change)
These are the main ambiguities and the cleanest student-level choices:

**A) Action code mapping (recommended)**
Use the 5 valid codes as:
- `0 = Kick`
- `1 = Punch`
- `2 = MoveLeft`
- `3 = MoveRight`
- `4 = Wait`
- `5..7 = invalid`

This aligns perfectly with “5 shop items” and “5 moves”.

**B) Distance definition (to make Punch distance=0 possible)**
If you use global positions `A..G`, the players never overlap, so distance 0 would never happen.  
So define distance as:

> Encode each player’s position as “steps away from the center edge”.  
> Left player: `C=0, B=1, A=2`  
> Right player: `G=0, F=1, E=2`  
> Then `distance = p1_pos + p2_pos`.

This makes:
- both at edge (C and G) → distance 0 → Punch works
- one step apart → distance 1 → Kick works

This is the most consistent interpretation with the spec’s Kick/Punch distances.

---

## 2) System Design (module-level plan)

### 2.1 Top-level module: `game_top`
Responsible for:
- Instantiating **Shop1** and **Shop2**
- Holding registers:
  - `p1_health`, `p2_health` (2 bits enough for 0..3)
  - `p1_credit`, `p2_credit` (10 bits enough for 0..500+)
  - `p1_pos`, `p2_pos` (2 bits for 0..2)
  - `p1_moves[0..4]`, `p2_moves[0..4]` (counters)
  - `turn` (0 = P1, 1 = P2)
  - `phase` (`SHOP` vs `PLAY`)
  - `moves_to_win` (at least 4 bits; up to ~15 is fine)
  - `winner` (2 bits: none, p1, p2)
  - `discount_mult_p1`, `discount_mult_p2` (100, 95, 90, 80)

### 2.2 Shop module: `shop`
One per player, must be independent.

**Inputs**
- `clk, rst`
- `buy_valid`
- `actionNumber[2:0]`
- `credit_in[9:0]`
- `discount_mult` (e.g., 100, 95, 90, 80)
- `Price0..Price4` (10-bit)
- `shop_reset` (pulse when entering SHOP to reset shop stock if required)

**Internal**
- `shop_stock[0..4]` counters
- `price_selected` mux
- `discounted_price = (price_selected * discount_mult) / 100`

**Outputs**
- `purchase_success`
- `err_invalid_action`
- `err_credit`
- `err_out_of_stock`
- `credit_out`
- `grant_onehot[4:0]` (which move to add to player inventory on success)

> Note: `grant_onehot` is the clean interface: top-level increments player move counters based on it.

### 2.3 Player “FSM” (can be explicit or implicit)
The spec asks for 2 FSMs. The cleanest way:

- Keep each player position as a **state register** (`p_pos`)
- During PLAY, on the player’s turn, update `p_pos` according to movement actions
- Treat SHOP as a separate `phase` (or add SHOP as a 4th state)

Either is acceptable, but if you want it to look like “FSM homework”, do:

```text
State encoding per player: {POS0, POS1, POS2, SHOP}
POS0 = closest edge (C or G)
POS1 = middle (B or F)
POS2 = far start (A or E)
SHOP = shop state
```

Then transitions:
- `SHOP --start_round--> POS2`
- `POS* --win_detected--> SHOP`
- Movement actions adjust POS index with saturation at 0..2

---

## 3) Implementation Plan (step-by-step, A+ level)

### Step 0: Define encodings and constants (do this first)
Create `localparam` constants in a shared header or inside modules:

```verilog
localparam ACT_KICK  = 3'd0;
localparam ACT_PUNCH = 3'd1;
localparam ACT_LEFT  = 3'd2;
localparam ACT_RIGHT = 3'd3;
localparam ACT_WAIT  = 3'd4;
```

Discount multipliers:
- `100`, `95`, `90`, `80`

Initials:
- `INIT_HEALTH = 3`
- `INIT_CREDIT = 500`
- `INIT_POS = 2` (A/E are farthest from center)

### Step 1: Implement `shop.v` standalone and test it
**Goal:** verify purchase logic is perfect before integrating.

**Shop combinational logic**
1) `valid_action = (actionNumber <= 4)`
2) `price_selected = mux(Price0..Price4)`
3) `price_final = (price_selected * discount_mult) / 100`
4) `enough_credit = (credit_in >= price_final)`
5) `in_stock = (shop_stock[actionNumber] > 0)` (only if valid)

**Success**
`purchase_success = buy_valid & valid_action & enough_credit & in_stock`

**On posedge clk**
If `purchase_success`:
- `credit_out <= credit_in - price_final`
- `shop_stock[actionNumber] <= shop_stock[actionNumber] - 1`
- `grant_onehot[actionNumber] <= 1` for that cycle (else 0)

Else:
- `credit_out <= credit_in` (or just output credit_in and update credit in top-level)

**Errors**
If `buy_valid` but not success:
- invalid action if not valid
- else credit error if not enough credit
- else out-of-stock error

**Standalone shop testbench**
Write a small TB that:
- sets prices
- sets stock to known numbers (like 2 each)
- tries:
  - invalid action 6
  - valid action but too expensive
  - valid action but stock=0
  - valid success (check credit decrements, stock decrements, grant pulses)

If this passes, integration is easy.

### Step 2: Implement gameplay registers + move inventory counters
In `game_top`:
- Add `p1_moves[0..4]`, `p2_moves[0..4]` counters.
- When Shop outputs `grant_onehot`, increment the corresponding `p_moves[i]`.

Example rule:
- If `shop1_grant_onehot[i]` is 1 on a clock edge → `p1_moves[i]++`

### Step 3: Implement PLAY action consumption and validation
During PLAY, on each clock:
1) Identify active player by `turn`.
2) Check action validity:
   - `action_code <= 4`
   - `active_moves[action_code] > 0`
3) If invalid:
   - set `err_invalid_action` or `err_no_inventory`
   - do not change positions/health
4) If valid:
   - decrement `active_moves[action_code]--`
   - apply movement or attack effects
   - increment `moves_to_win++`

### Step 4: Implement movement logic (with side-specific meaning)
Because left/right directions are screen-relative:

Let positions be “distance from center”:
- `p_pos = 0` means at edge (C/G)
- `p_pos = 2` means far (A/E)

Then:
- For **P1 (left side)**:
  - `MoveRight` means toward center → `p1_pos = max(p1_pos - 1, 0)`
  - `MoveLeft` means away → `p1_pos = min(p1_pos + 1, 2)`
- For **P2 (right side)**:
  - `MoveLeft` means toward center → `p2_pos = max(p2_pos - 1, 0)`
  - `MoveRight` means away → `p2_pos = min(p2_pos + 1, 2)`

Wait: no change.

No need to throw an error if pushing into a wall. Just saturate and still consume the move (simple + defensible).

### Step 5: Implement distance + attack rules
Compute combinationally each tick:
- `distance = p1_pos + p2_pos` (0..4)

When active player uses Kick/Punch:
- If `Kick` and `distance == 1` → opponent health −= 1
- If `Punch` and `distance == 0` → opponent health −= 2
- Else no damage

Health saturates at 0:
- `new_health = (health <= dmg) ? 0 : (health - dmg)`

### Step 6: Turn switching
At the end of each PLAY tick:
- `turn <= ~turn;`
Unless you want to freeze on invalid input (not required). The spec just says Turn decides who moves, not that invalid freezes.

### Step 7: Win detection + transition to SHOP
After applying damage:
- If opponent health becomes 0:
  - `winner <= active_player`
  - compute discount multiplier from `moves_to_win`
  - transition `phase <= SHOP`
  - (optional) keep `winner` latched so SHOP knows who gets discount

Discount logic (combinational when setting winner):
- if `moves_to_win <= 6` → mult = 80  
- else if `moves_to_win <= 9` → mult = 90  
- else → mult = 95  

Assign:
- winner mult = above
- loser mult = 100

### Step 8: SHOP phase behavior (extra credit)
In SHOP:
- Allow purchases for P1 and P2 independently each clock.
- Provide an input `start_round` from TB. When `start_round==1` on a rising edge:
  - reset health both to 3
  - reset credits to 500
  - reset positions to start (2)
  - reset `moves_to_win` to 0
  - set `turn` to P1 (or alternate each round if you want)
  - move `phase <= PLAY`

This matches the PDF’s “reset with enable at leaving SHOP” idea.

### Step 9: `$display` logging (make it “assignment-ready”)
On every posedge clk:
- Print `phase`, `turn`, positions, health, credit
- If in SHOP and buy_valid, print:
  - attempted code, selected price, discounted price, success/errors
  - updated shop stock
  - updated move inventory
- If in PLAY, print:
  - action code, whether it was valid, whether inventory existed
  - distance, whether hit landed
  - health changes
  - move counters after decrement

This is where you get the “A+ polish”.

---

## 4) Suggested Testbench Plan (what you should simulate)

### TB structure idea
Implement helper tasks (even in plain Verilog you can use `task`):
- `task buy_p1(code);` and `task buy_p2(code);`
- `task do_move(code);` (feeds action code for current turn)

### Test 1: Shop correctness
- Set prices: Kick=120, Punch=200, Left=50, Right=50, Wait=10
- Give stock 1 or 2 each
- Attempt:
  - invalid code 6 (expect invalid error)
  - too expensive (expect credit error)
  - buy until stock 0 then try again (expect out-of-stock)
  - successful purchases update credit and grant move counters

### Test 2: Movement boundaries
- Buy several left/right moves
- Move beyond edge and confirm saturation

### Test 3: Punch distance=0 scenario
- Move both players to edge (`p1_pos=0`, `p2_pos=0`)
- Buy Punch for active player
- Apply Punch: confirm −2 health

### Test 4: Kick distance=1 scenario
- Put players so `p1_pos+p2_pos==1`
- Apply Kick: confirm −1 health

### Test 5: Win path + discount bands
Create 3 scenarios:
1) winner in ≤6 valid moves → confirm 20% off in SHOP
2) winner in 7..9 valid moves → confirm 10% off
3) winner later → confirm 5% off

In SHOP after win:
- try buying same item for winner and loser and show winner pays less.

---

## 5) “Minimal interface” you can hand to Codex/Claude
If you want the easiest coding prompt, tell it to implement these files:

1) `shop.v`  
2) `game_top.v`  
3) `tb_game.v`

And use these top-level signals:

**Inputs**
- `clk, rst`
- `buy_valid_p1, buy_code_p1[2:0]`
- `buy_valid_p2, buy_code_p2[2:0]`
- `start_round`
- `play_action[2:0]` (applies to current `turn` during PLAY)

**Outputs**
- `phase` (SHOP/PLAY)
- `turn`
- `p1_health, p2_health`
- `p1_credit, p2_credit`
- `p1_pos, p2_pos`
- `winner`
- error flags (shop + play)

This separation makes the TB straightforward and avoids messy “shared input buses”.

---

If you want, paste your preferred **price values** and **initial shop stock values** (even rough), and I’ll convert the PRD above into a very explicit “signal-by-signal spec” (like a rubric checklist) so whoever codes it can’t misinterpret anything.
