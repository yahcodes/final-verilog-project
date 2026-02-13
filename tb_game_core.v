`timescale 1ns/1ps

// Testbench for game_top — verifies GAME-01 through GAME-08
//
// Purchase plan:
//   P1: 2x Kick(200) + 2x Punch(200) + 2x MoveRight(100) = 500
//   P2: 2x MoveLeft(100) + 1x Wait(20) = 120
//
// Play sequence summary:
//   P1 MoveRight x2:   pos 2->1->0                          GAME-05, GAME-01
//   P1 Kick at dist=2: err_wrong_distance, counter 2->1     GAME-02
//   P2 MoveLeft #1:    P2 pos 2->1, dist = 0+1 = 1
//   P1 Kick at dist=1: p2_health 3->2, counter 1->0         GAME-03
//   P1 Punch at dist=1:err_wrong_distance, counter 2->1     GAME-02 (punch)
//   P2 MoveLeft #2:    P2 pos 1->0, dist = 0+0 = 0
//   P1 Punch at dist=0:p2_health 2->0, counter 1->0         GAME-04
//   P2 Wait #1:        no state change, counter 1->0        GAME-06
//   P2 Wait #2:        err_no_inventory                     GAME-07
//   P1 Kick (ctr=0):   err_no_inventory                     GAME-08
//   P1 Punch (ctr=0):  err_no_inventory                     GAME-08

module tb_game_core;

    reg        clk;
    reg        rst;
    reg        turn;
    reg        play_valid;
    reg [2:0]  play_action;
    reg        buy_valid_p1;
    reg [2:0]  buy_code_p1;
    reg        buy_valid_p2;
    reg [2:0]  buy_code_p2;
    reg        start_round;
    reg [9:0]  Price0, Price1, Price2, Price3, Price4;

    wire        phase;
    wire [1:0]  p1_health;
    wire [1:0]  p2_health;
    wire [9:0]  p1_credit;
    wire [9:0]  p2_credit;
    wire [1:0]  p1_pos;
    wire [1:0]  p2_pos;
    wire [1:0]  winner;
    wire        purchase_success_p1;
    wire        err_invalid_action_p1;
    wire        err_credit_p1;
    wire        err_out_of_stock_p1;
    wire        purchase_success_p2;
    wire        err_invalid_action_p2;
    wire        err_credit_p2;
    wire        err_out_of_stock_p2;
    wire        err_no_inventory;
    wire        err_wrong_distance;

    game_top dut (
        .clk                  (clk),
        .rst                  (rst),
        .turn                 (turn),
        .play_valid           (play_valid),
        .play_action          (play_action),
        .buy_valid_p1         (buy_valid_p1),
        .buy_code_p1          (buy_code_p1),
        .buy_valid_p2         (buy_valid_p2),
        .buy_code_p2          (buy_code_p2),
        .start_round          (start_round),
        .Price0               (Price0),
        .Price1               (Price1),
        .Price2               (Price2),
        .Price3               (Price3),
        .Price4               (Price4),
        .phase                (phase),
        .p1_health            (p1_health),
        .p2_health            (p2_health),
        .p1_credit            (p1_credit),
        .p2_credit            (p2_credit),
        .p1_pos               (p1_pos),
        .p2_pos               (p2_pos),
        .winner               (winner),
        .purchase_success_p1  (purchase_success_p1),
        .err_invalid_action_p1(err_invalid_action_p1),
        .err_credit_p1        (err_credit_p1),
        .err_out_of_stock_p1  (err_out_of_stock_p1),
        .purchase_success_p2  (purchase_success_p2),
        .err_invalid_action_p2(err_invalid_action_p2),
        .err_credit_p2        (err_credit_p2),
        .err_out_of_stock_p2  (err_out_of_stock_p2),
        .err_no_inventory     (err_no_inventory),
        .err_wrong_distance   (err_wrong_distance)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // buy_p1: buy one item for P1.
    // The shop latches grant_onehot on posedge N; game_top sees it on posedge N+1.
    // Two posedge cycle: assert buy_valid for first, deassert for second.
    task buy_p1;
        input [2:0] action;
        begin
            @(negedge clk); buy_valid_p1 = 1; buy_code_p1 = action;
            @(posedge clk);
            @(negedge clk); buy_valid_p1 = 0;
            @(posedge clk); #1;
        end
    endtask

    task buy_p2;
        input [2:0] action;
        begin
            @(negedge clk); buy_valid_p2 = 1; buy_code_p2 = action;
            @(posedge clk);
            @(negedge clk); buy_valid_p2 = 0;
            @(posedge clk); #1;
        end
    endtask

    // do_play: issue one PLAY action, sample outputs 1ns after posedge
    task do_play;
        input        t;
        input [2:0]  action;
        begin
            @(negedge clk); turn = t; play_action = action; play_valid = 1;
            @(posedge clk); #1;
            @(negedge clk); play_valid = 0;
        end
    endtask

    // do_reset: hold rst=1 for 2 posedges, then deassert
    task do_reset;
        begin
            @(negedge clk); rst = 1;
            @(posedge clk); @(posedge clk);
            @(negedge clk); rst = 0; #1;
        end
    endtask

    // do_start: pulse start_round for 1 posedge to enter PLAY
    task do_start;
        begin
            @(negedge clk); start_round = 1;
            @(posedge clk); #1;
            @(negedge clk); start_round = 0; #1;
        end
    endtask

    integer errors;

    initial begin
        errors       = 0;
        rst          = 1;
        turn         = 0;
        play_valid   = 0;
        play_action  = 3'd0;
        buy_valid_p1 = 0;
        buy_code_p1  = 3'd0;
        buy_valid_p2 = 0;
        buy_code_p2  = 3'd0;
        start_round  = 0;
        Price0 = 10'd100; // Kick
        Price1 = 10'd100; // Punch
        Price2 = 10'd50;  // MoveLeft
        Price3 = 10'd50;  // MoveRight
        Price4 = 10'd20;  // Wait

        // ==============================================================
        // GAME-07: err_no_inventory fires when move counter == 0
        // Enter PLAY with zero inventory, attempt a Kick
        // ==============================================================
        $display("=== GAME-07: no-inventory error before purchase ===");
        do_reset;
        do_start;

        do_play(1'b0, 3'd0); // P1 ACT_KICK, p1_moves[0]=0

        if (err_no_inventory !== 1'b1) begin
            $display("FAIL [GAME-07a] err_no_inventory=%b (expected 1)", err_no_inventory);
            errors = errors + 1;
        end else
            $display("PASS [GAME-07a] err_no_inventory=1 on kick with empty inventory");

        if (p2_health !== 2'd3) begin
            $display("FAIL [GAME-07b] p2_health=%0d (expected 3, unchanged)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-07b] p2_health=3 unchanged after no-inventory kick");

        if (p1_pos !== 2'd2 || p2_pos !== 2'd2) begin
            $display("FAIL [GAME-07c] positions p1=%0d p2=%0d (expected 2,2)", p1_pos, p2_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-07c] positions unchanged: p1=2 p2=2");

        // ==============================================================
        // Purchase round
        // P1: 2x Kick + 2x Punch + 2x MoveRight = 500 (exact budget)
        // P2: 2x MoveLeft + 1x Wait = 120
        // ==============================================================
        $display("=== Purchasing moves ===");
        do_reset; // back to SHOP, all counters zeroed

        buy_p1(3'd0); // Kick #1    p1_moves[0]=1
        buy_p1(3'd0); // Kick #2    p1_moves[0]=2
        buy_p1(3'd1); // Punch #1   p1_moves[1]=1
        buy_p1(3'd1); // Punch #2   p1_moves[1]=2
        buy_p1(3'd3); // MoveRight  p1_moves[3]=1
        buy_p1(3'd3); // MoveRight  p1_moves[3]=2

        buy_p2(3'd2); // MoveLeft#1 p2_moves[2]=1
        buy_p2(3'd2); // MoveLeft#2 p2_moves[2]=2
        buy_p2(3'd4); // Wait       p2_moves[4]=1

        $display("Purchases done: p1_credit=%0d p2_credit=%0d. Entering PLAY.",
                 p1_credit, p2_credit);
        do_start;

        // ==============================================================
        // GAME-05 + GAME-01: MoveRight adjusts position; inactive player unaffected
        // P1 pos: 2 -> 1 -> 0
        // ==============================================================
        $display("=== GAME-05 + GAME-01: position movement, player isolation ===");

        do_play(1'b0, 3'd3); // P1 ACT_RIGHT, pos 2->1

        if (p1_pos !== 2'd1) begin
            $display("FAIL [GAME-05a] p1_pos=%0d (expected 1)", p1_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-05a] p1_pos=1 after first MoveRight");

        if (p2_pos !== 2'd2) begin
            $display("FAIL [GAME-01a] p2_pos=%0d (expected 2, P2 is inactive)", p2_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-01a] p2_pos=2 unchanged (inactive player unaffected)");

        if (p2_health !== 2'd3) begin
            $display("FAIL [GAME-01b] p2_health=%0d (expected 3, P2 is inactive)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-01b] p2_health=3 unchanged during P1 move");

        do_play(1'b0, 3'd3); // P1 ACT_RIGHT, pos 1->0

        if (p1_pos !== 2'd0) begin
            $display("FAIL [GAME-05b] p1_pos=%0d (expected 0)", p1_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-05b] p1_pos=0 after second MoveRight");

        // ==============================================================
        // GAME-02: Kick at wrong distance — no damage, but inventory consumed
        // P1 at pos=0, P2 at pos=2 -> distance=2. Kick needs distance=1.
        // ==============================================================
        $display("=== GAME-02: Kick at wrong distance ===");

        do_play(1'b0, 3'd0); // P1 ACT_KICK at distance=2

        if (err_wrong_distance !== 1'b1) begin
            $display("FAIL [GAME-02a] err_wrong_distance=%b (expected 1, kick at dist=2)", err_wrong_distance);
            errors = errors + 1;
        end else
            $display("PASS [GAME-02a] err_wrong_distance=1 on kick at distance=2");

        if (p2_health !== 2'd3) begin
            $display("FAIL [GAME-02b] p2_health=%0d (expected 3, no damage)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-02b] p2_health=3 unchanged after wrong-distance kick");

        // ==============================================================
        // GAME-03: Kick at correct distance (distance=1) — deals 1 damage
        // P2 MoveLeft #1: pos 2->1. distance = p1_pos(0) + p2_pos(1) = 1
        // ==============================================================
        $display("=== GAME-03: Kick at correct distance ===");

        do_play(1'b1, 3'd2); // P2 ACT_LEFT, pos 2->1

        if (p2_pos !== 2'd1) begin
            $display("FAIL [GAME-03a] p2_pos=%0d (expected 1 after P2 MoveLeft)", p2_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-03a] p2_pos=1 after P2 MoveLeft");

        do_play(1'b0, 3'd0); // P1 ACT_KICK at distance=1

        if (p2_health !== 2'd2) begin
            $display("FAIL [GAME-03b] p2_health=%0d (expected 2, kick at dist=1 deals 1 damage)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-03b] p2_health=2 after kick at distance=1");

        if (err_wrong_distance !== 1'b0) begin
            $display("FAIL [GAME-03c] err_wrong_distance=%b (expected 0)", err_wrong_distance);
            errors = errors + 1;
        end else
            $display("PASS [GAME-03c] err_wrong_distance=0 on successful kick");

        // ==============================================================
        // GAME-02 (punch): Punch at wrong distance — no damage, inventory consumed
        // P1 at pos=0, P2 at pos=1 -> distance=1. Punch needs distance=0.
        // ==============================================================
        $display("=== GAME-02: Punch at wrong distance ===");

        do_play(1'b0, 3'd1); // P1 ACT_PUNCH at distance=1

        if (err_wrong_distance !== 1'b1) begin
            $display("FAIL [GAME-02c] err_wrong_distance=%b (expected 1, punch at dist=1)", err_wrong_distance);
            errors = errors + 1;
        end else
            $display("PASS [GAME-02c] err_wrong_distance=1 on punch at distance=1");

        if (p2_health !== 2'd2) begin
            $display("FAIL [GAME-02d] p2_health=%0d (expected 2, no damage)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-02d] p2_health=2 unchanged after wrong-distance punch");

        // ==============================================================
        // GAME-04: Punch at distance=0 — deals 2 damage
        // P2 MoveLeft #2: pos 1->0. distance = p1_pos(0) + p2_pos(0) = 0.
        // ==============================================================
        $display("=== GAME-04: Punch at distance=0 ===");

        do_play(1'b1, 3'd2); // P2 ACT_LEFT, pos 1->0

        if (p2_pos !== 2'd0) begin
            $display("FAIL [GAME-04a] p2_pos=%0d (expected 0 after P2 MoveLeft)", p2_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-04a] p2_pos=0 after P2 MoveLeft");

        do_play(1'b0, 3'd1); // P1 ACT_PUNCH at distance=0

        if (p2_health !== 2'd0) begin
            $display("FAIL [GAME-04b] p2_health=%0d (expected 0, punch at dist=0 deals 2 damage)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-04b] p2_health=0 after punch at distance=0 (2 damage)");

        if (err_wrong_distance !== 1'b0) begin
            $display("FAIL [GAME-04c] err_wrong_distance=%b (expected 0)", err_wrong_distance);
            errors = errors + 1;
        end else
            $display("PASS [GAME-04c] err_wrong_distance=0 on successful punch");

        // ==============================================================
        // GAME-06: Wait — no health/position change, counter decrements
        // ==============================================================
        $display("=== GAME-06: Wait action ===");

        do_play(1'b1, 3'd4); // P2 ACT_WAIT, counter=1

        if (err_no_inventory !== 1'b0) begin
            $display("FAIL [GAME-06a] err_no_inventory=%b (expected 0, P2 had 1 Wait)", err_no_inventory);
            errors = errors + 1;
        end else
            $display("PASS [GAME-06a] err_no_inventory=0 on P2 Wait");

        if (p1_health !== 2'd3 || p2_health !== 2'd0) begin
            $display("FAIL [GAME-06b] health changed on Wait: p1=%0d p2=%0d (expected 3,0)", p1_health, p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-06b] health unchanged after P2 Wait (p1=3, p2=0)");

        if (p1_pos !== 2'd0 || p2_pos !== 2'd0) begin
            $display("FAIL [GAME-06c] positions changed on Wait: p1=%0d p2=%0d (expected 0,0)", p1_pos, p2_pos);
            errors = errors + 1;
        end else
            $display("PASS [GAME-06c] positions unchanged after P2 Wait");

        do_play(1'b1, 3'd4); // P2 ACT_WAIT again, counter=0

        if (err_no_inventory !== 1'b1) begin
            $display("FAIL [GAME-06d] err_no_inventory=%b (expected 1, counter exhausted)", err_no_inventory);
            errors = errors + 1;
        end else
            $display("PASS [GAME-06d] err_no_inventory=1 when P2 Wait counter=0");

        // ==============================================================
        // GAME-08: Inventory decrement — verify counters decrease per use
        // P1 kicked twice (GAME-02a: wrong dist, GAME-03b: correct dist). Counter=0.
        // P1 punched twice (GAME-02c: wrong dist, GAME-04b: correct dist). Counter=0.
        // ==============================================================
        $display("=== GAME-08: Inventory decrement and exhaustion ===");

        do_play(1'b0, 3'd0); // P1 ACT_KICK, counter=0

        if (err_no_inventory !== 1'b1) begin
            $display("FAIL [GAME-08a] err_no_inventory=%b (expected 1, kick counter=0)", err_no_inventory);
            errors = errors + 1;
        end else
            $display("PASS [GAME-08a] err_no_inventory=1 when P1 kick counter=0");

        if (p2_health !== 2'd0) begin
            $display("FAIL [GAME-08b] p2_health=%0d (expected 0, unchanged)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-08b] p2_health=0 unchanged on no-inventory kick");

        do_play(1'b0, 3'd1); // P1 ACT_PUNCH, counter=0

        if (err_no_inventory !== 1'b1) begin
            $display("FAIL [GAME-08c] err_no_inventory=%b (expected 1, punch counter=0)", err_no_inventory);
            errors = errors + 1;
        end else
            $display("PASS [GAME-08c] err_no_inventory=1 when P1 punch counter=0");

        if (p2_health !== 2'd0) begin
            $display("FAIL [GAME-08d] p2_health=%0d (expected 0, unchanged)", p2_health);
            errors = errors + 1;
        end else
            $display("PASS [GAME-08d] p2_health=0 unchanged on no-inventory punch");

        // ==============================================================
        // Summary
        // ==============================================================
        if (errors == 0)
            $display("--- tb_game_core complete ---");
        else
            $display("--- tb_game_core FAILED: %0d error(s) ---", errors);

        $finish;
    end

endmodule
