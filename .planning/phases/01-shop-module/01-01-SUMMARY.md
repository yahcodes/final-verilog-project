---
phase: 01-shop-module
plan: 01
status: complete
---

## What Was Built

### shop.v — Standalone per-player shop module

**File:** `shop.v` (project root)

**Port list (Phase 2 instantiation reference):**

| Direction | Width | Name             | Description                              |
|-----------|-------|------------------|------------------------------------------|
| input     | 1     | clk              | System clock (posedge)                   |
| input     | 1     | rst              | Synchronous reset (active-high posedge)  |
| input     | 1     | buy_valid        | Asserted for one cycle to request a buy  |
| input     | [2:0] | action_number    | 0=Kick 1=Punch 2=Left 3=Right 4=Wait     |
| input     | [9:0] | credit_in        | Player credit before purchase            |
| input     | [6:0] | discount_mult    | Price multiplier: 100=none, 80=20% off   |
| input     | [9:0] | Price0           | Price for Kick                           |
| input     | [9:0] | Price1           | Price for Punch                          |
| input     | [9:0] | Price2           | Price for Left                           |
| input     | [9:0] | Price3           | Price for Right                          |
| input     | [9:0] | Price4           | Price for Wait                           |
| output    | 1     | purchase_success | Combinational: 1 when purchase proceeds  |
| output    | 1     | err_invalid_action | Combinational: action_number > 4       |
| output    | 1     | err_credit       | Combinational: insufficient credit       |
| output    | 1     | err_out_of_stock | Combinational: stock depleted            |
| output    | [9:0] | credit_out       | Registered: updated credit after purchase|
| output    | [4:0] | grant_onehot     | Registered: one-hot pulse for granted action|

**Phase 2 instantiation snippet:**
```verilog
shop shop_p1 (
    .clk(clk), .rst(rst), .buy_valid(p1_buy_valid),
    .action_number(p1_action_number), .credit_in(p1_credit),
    .discount_mult(discount_mult),
    .Price0(Price0), .Price1(Price1), .Price2(Price2),
    .Price3(Price3), .Price4(Price4),
    .purchase_success(p1_purchase_success),
    .err_invalid_action(p1_err_invalid_action),
    .err_credit(p1_err_credit),
    .err_out_of_stock(p1_err_out_of_stock),
    .credit_out(p1_credit_next),
    .grant_onehot(p1_grant_onehot)
);
```

### Internal structure

- **shop_stock [0:4]** — 4-bit unpacked array; initialized to 5 on reset, decremented on each successful purchase
- **Combinational always @(*)**
  - Price mux (case on action_number, default = 0)
  - Discount: `price_tmp[16:0] = {7'd0, price_selected} * {10'd0, discount_mult}; discounted_price = price_tmp / 100`
  - 17-bit intermediate prevents overflow (max product = 1023 × 127 = 129,921 < 2^17)
  - Stock check uses a case statement (avoids out-of-bounds array indexing for action_number 5–7)
  - Error priority: err_invalid_action > err_credit > err_out_of_stock
- **Sequential always @(posedge clk or posedge rst)**
  - Reset: all stock → 5, grant_onehot → 0, credit_out → credit_in
  - On purchase_success: decrement stock, update credit_out, pulse grant_onehot (1 cycle) via case
  - Otherwise: grant_onehot → 0, credit_out → credit_in (pass-through)

### Key design decisions

1. **17-bit intermediate** for discount avoids 10-bit multiplication overflow
2. **Case statement for in_stock** instead of direct `shop_stock[action_number]` index — prevents out-of-bounds access when action_number = 5/6/7
3. **grant_onehot via case** in sequential block — avoids ambiguous overlapping non-blocking assignments to the same reg
4. **credit_out is pass-through** on non-purchase cycles so game_top can always latch it each cycle

---

## Simulation Output

```
TEST A: err_invalid_action=1 (expect 1), purchase_success=0 (expect 0), credit_out=1000 (expect 1000)
TEST B: err_credit=1 (expect 1), err_invalid_action=0 (expect 0), purchase_success=0 (expect 0), credit_out=50 (expect 50)
TEST C: purchase_success=1 (expect 1), credit_out=880 (expect 880), grant_onehot=00001 (expect 00001)
TEST D: err_out_of_stock=1 (expect 1), purchase_success=0 (expect 0), credit_out=400 (expect 400)
TEST E: purchase_success=1 (expect 1), credit_out=904 (expect 904), grant_onehot=00001 (expect 00001)
--- tb_shop complete ---
```

All 5 tests pass. Compiled and simulated with Icarus Verilog 12.0.

---

## Deviations from Plan

| Item | Plan | Actual | Reason |
|------|------|--------|--------|
| Test C credit_in | Plan body says 500 (expect 380), plan note says reset to 1000 | Used credit_in=1000 → credit_out=880 | Plan note takes priority; avoids running negative in drain loop |
| in_stock guard | Ternary `valid_action ? shop_stock[action_number] > 0 : 0` | Case statement over 5 indices | Avoids out-of-bounds simulation access for action_number 5–7 |
| grant_onehot assignment | `grant_onehot <= 0; grant_onehot[action_number] <= 1` | Case statement for full-word assignment | Avoids overlapping NBA ambiguity on same reg |

---

## Verification Checklist

- [x] `iverilog -o /dev/null shop.v` exits 0
- [x] All 5 test lines match expected values; ends with `--- tb_shop complete ---`
- [x] No SystemVerilog keywords (`logic`, `always_comb`, `always_ff`) in shop.v
- [x] No `$display` in shop.v
- [x] shop.v standalone (no `include`, no hardcoded prices)
- [x] SHOP-01 through SHOP-05 verified
