`timescale 1ns/1ps
module tb_phase3;

    // ---------------------------------------------------------------
    // Signal declarations
    // ---------------------------------------------------------------
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
    wire [1:0]  p1_health, p2_health;
    wire [9:0]  p1_credit, p2_credit;
    wire [1:0]  p1_pos, p2_pos, winner;
    wire        purchase_success_p1, err_invalid_action_p1;
    wire        err_credit_p1,       err_out_of_stock_p1;
    wire        purchase_success_p2, err_invalid_action_p2;
    wire        err_credit_p2,       err_out_of_stock_p2;
    wire        err_no_inventory, err_wrong_distance;

    integer credit_before;
    integer errors;

    // ---------------------------------------------------------------
    // DUT instantiation
    // ---------------------------------------------------------------
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

    // ---------------------------------------------------------------
    // Clock: 10ns period
    // ---------------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // ---------------------------------------------------------------
    // Helper tasks
    // ---------------------------------------------------------------

    // Buy one item for P1 (2 cycles: buy pulse + latch)
    task do_buy_p1;
        input [2:0] code;
        begin
            buy_valid_p1 = 1'b1;
            buy_code_p1  = code;
            @(posedge clk); #1;
            buy_valid_p1 = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    // Buy one item for P2
    task do_buy_p2;
        input [2:0] code;
        begin
            buy_valid_p2 = 1'b1;
            buy_code_p2  = code;
            @(posedge clk); #1;
            buy_valid_p2 = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    // Execute one PLAY action
    task do_play;
        input       turn_val;
        input [2:0] act;
        begin
            turn        = turn_val;
            play_valid  = 1'b1;
            play_action = act;
            @(posedge clk); #1;
            play_valid  = 1'b0;
        end
    endtask

    // Reset for 2 clock cycles
    task do_reset;
        begin
            rst = 1'b1;
            @(posedge clk);
            @(posedge clk); #1;
            rst = 1'b0;
            @(posedge clk); #1;
        end
    endtask

    // Fire start_round for 1 clock cycle
    task do_start;
        begin
            start_round = 1'b1;
            @(posedge clk); #1;
            start_round = 1'b0;
        end
    endtask

    // ---------------------------------------------------------------
    // Main test body
    // ---------------------------------------------------------------
    initial begin
        // Initialise all inputs
        clk          = 0;
        rst          = 0;
        turn         = 0;
        play_valid   = 0;
        play_action  = 3'd0;
        buy_valid_p1 = 0; buy_code_p1 = 3'd0;
        buy_valid_p2 = 0; buy_code_p2 = 3'd0;
        start_round  = 0;
        Price0 = 10'd100;
        Price1 = 10'd150;
        Price2 = 10'd50;
        Price3 = 10'd50;
        Price4 = 10'd30;
        errors = 0;

        // ==============================================================
        // TEST 1: P1 wins in 6 moves -> discount_mult=80 (band <=6)
        // ==============================================================
        $display("=== TEST 1: P1 wins in 6 moves (mult=80) ===");

        do_reset;

        // SHOP: P1 buys 3x Kick(0), 2x MoveRight(3) (full price, winner=00)
        // P1 cost: 3*100 + 2*50 = 400. p1_credit = 100.
        do_buy_p1(3'd0); // Kick #1
        do_buy_p1(3'd0); // Kick #2
        do_buy_p1(3'd0); // Kick #3
        do_buy_p1(3'd3); // MoveRight #1
        do_buy_p1(3'd3); // MoveRight #2

        // P2 buys 1x MoveLeft(2)
        // P2 cost: 50. p2_credit = 450.
        do_buy_p2(3'd2); // MoveLeft #1

        // Enter PLAY
        do_start;

        // Play sequence (6 moves -> WIN for P1)
        // Move 1: P1 MoveRight -> p1_pos 2->1, mtw=1
        do_play(1'b0, 3'd3);
        // Move 2: P1 MoveRight -> p1_pos 1->0, mtw=2, distance=0+2=2
        do_play(1'b0, 3'd3);
        // Move 3: P2 MoveLeft  -> p2_pos 2->1, mtw=3, distance=0+1=1
        do_play(1'b1, 3'd2);
        // Move 4: P1 Kick      -> distance=1, p2_health 3->2, mtw=4
        do_play(1'b0, 3'd0);
        // Move 5: P1 Kick      -> distance=1, p2_health 2->1, mtw=5
        do_play(1'b0, 3'd0);
        // Move 6: P1 Kick      -> distance=1, p2_health 1->0 -> WIN, mtw=6
        do_play(1'b0, 3'd0);

        // After WIN: phase=SHOP, winner=01, moves_to_win=6
        // Credit reset to 500 for both players
        if (phase !== 1'b1)
            $display("FAIL [T1-a] phase=%b (expected 1=SHOP after win)", phase);
        else
            $display("PASS [T1-a] phase=1 (SHOP) after P1 wins");

        if (winner !== 2'b01)
            $display("FAIL [T1-b] winner=%b (expected 01)", winner);
        else
            $display("PASS [T1-b] winner=01");

        if (p1_credit !== 10'd500)
            $display("FAIL [T1-c] p1_credit=%0d (expected 500 after win reset)", p1_credit);
        else
            $display("PASS [T1-c] p1_credit=500 after win reset");

        // P1 buys item 0 (Price0=100) with discount_mult=80
        // Expected cost = 100*80/100 = 80 -> p1_credit = 500-80 = 420
        credit_before = p1_credit;
        do_buy_p1(3'd0);

        if ((credit_before - p1_credit) !== 80)
            $display("FAIL [T1-d] credit delta=%0d (expected 80, mult=80)", credit_before - p1_credit);
        else
            $display("PASS [T1-d] credit delta=80 (discount mult=80 for 6-move win)");

        // ==============================================================
        // TEST 2: start_round resets phase and winner
        // ==============================================================
        $display("=== TEST 2: start_round resets state ===");

        do_start;

        if (phase !== 1'b0)
            $display("FAIL [T2-a] phase=%b (expected 0=PLAY after start_round)", phase);
        else
            $display("PASS [T2-a] phase=0 (PLAY) after start_round");

        if (winner !== 2'b00)
            $display("FAIL [T2-b] winner=%b (expected 00 after start_round)", winner);
        else
            $display("PASS [T2-b] winner=00 after start_round");

        // ==============================================================
        // TEST 3: P1 wins in 8 moves -> discount_mult=90 (band 7-9)
        // ==============================================================
        $display("=== TEST 3: P1 wins in 8 moves (mult=90) ===");

        do_reset;

        // SHOP: P1 buys 3x Kick(0), 2x MoveRight(3), 1x Wait(4)
        // P1 cost: 3*100 + 2*50 + 1*30 = 430. p1_credit = 70.
        do_buy_p1(3'd0); // Kick #1
        do_buy_p1(3'd0); // Kick #2
        do_buy_p1(3'd0); // Kick #3
        do_buy_p1(3'd3); // MoveRight #1
        do_buy_p1(3'd3); // MoveRight #2
        do_buy_p1(3'd4); // Wait #1

        // P2 buys 1x MoveLeft(2), 1x Wait(4)
        // P2 cost: 50+30 = 80. p2_credit = 420.
        do_buy_p2(3'd2); // MoveLeft
        do_buy_p2(3'd4); // Wait

        do_start;

        // Play sequence (8 moves -> WIN for P1)
        // Move 1: P1 MoveRight -> p1_pos 2->1, mtw=1
        do_play(1'b0, 3'd3);
        // Move 2: P1 MoveRight -> p1_pos 1->0, mtw=2, distance=0+2=2
        do_play(1'b0, 3'd3);
        // Move 3: P2 MoveLeft  -> p2_pos 2->1, mtw=3, distance=0+1=1
        do_play(1'b1, 3'd2);
        // Move 4: P1 Wait      -> mtw=4
        do_play(1'b0, 3'd4);
        // Move 5: P2 Wait      -> mtw=5
        do_play(1'b1, 3'd4);
        // Move 6: P1 Kick      -> distance=1, p2_health 3->2, mtw=6
        do_play(1'b0, 3'd0);
        // Move 7: P1 Kick      -> distance=1, p2_health 2->1, mtw=7
        do_play(1'b0, 3'd0);
        // Move 8: P1 Kick      -> distance=1, p2_health 1->0 -> WIN, mtw=8
        do_play(1'b0, 3'd0);

        // After WIN: phase=SHOP, winner=01, moves_to_win=8
        if (winner !== 2'b01)
            $display("FAIL [T3-a] winner=%b (expected 01)", winner);
        else
            $display("PASS [T3-a] winner=01");

        if (phase !== 1'b1)
            $display("FAIL [T3-b] phase=%b (expected 1=SHOP after win)", phase);
        else
            $display("PASS [T3-b] phase=1 (SHOP) after P1 wins in 8 moves");

        // P1 buys item 0 with discount_mult=90 (moves_to_win=8, band 7-9)
        // Expected cost = 100*90/100 = 90 -> p1_credit = 500-90 = 410
        credit_before = p1_credit;
        do_buy_p1(3'd0);

        if ((credit_before - p1_credit) !== 90)
            $display("FAIL [T3-c] credit delta=%0d (expected 90, mult=90)", credit_before - p1_credit);
        else
            $display("PASS [T3-c] credit delta=90 (discount mult=90 for 8-move win)");

        // ==============================================================
        // TEST 4: P1 wins in 12 moves -> discount_mult=95 (band >=10)
        // ==============================================================
        $display("=== TEST 4: P1 wins in 12 moves (mult=95) ===");

        do_reset;

        // SHOP: P1 buys 3x Kick(0), 2x MoveRight(3), 3x Wait(4)
        // P1 cost: 3*100 + 2*50 + 3*30 = 300+100+90 = 490. p1_credit = 10.
        do_buy_p1(3'd0); // Kick #1
        do_buy_p1(3'd0); // Kick #2
        do_buy_p1(3'd0); // Kick #3
        do_buy_p1(3'd3); // MoveRight #1
        do_buy_p1(3'd3); // MoveRight #2
        do_buy_p1(3'd4); // Wait #1
        do_buy_p1(3'd4); // Wait #2
        do_buy_p1(3'd4); // Wait #3

        // P2 buys 1x MoveLeft(2), 3x Wait(4)
        // P2 cost: 50 + 3*30 = 140. p2_credit = 360.
        do_buy_p2(3'd2); // MoveLeft
        do_buy_p2(3'd4); // Wait #1
        do_buy_p2(3'd4); // Wait #2
        do_buy_p2(3'd4); // Wait #3

        do_start;

        // Play sequence (12 moves -> WIN for P1, moves_to_win=12)
        // Move  1: P1 MoveRight -> p1_pos 2->1, mtw=1
        do_play(1'b0, 3'd3);
        // Move  2: P1 MoveRight -> p1_pos 1->0, mtw=2, distance=0+2=2
        do_play(1'b0, 3'd3);
        // Move  3: P2 MoveLeft  -> p2_pos 2->1, mtw=3, distance=0+1=1
        do_play(1'b1, 3'd2);
        // Move  4: P1 Wait      -> mtw=4
        do_play(1'b0, 3'd4);
        // Move  5: P2 Wait      -> mtw=5
        do_play(1'b1, 3'd4);
        // Move  6: P1 Wait      -> mtw=6
        do_play(1'b0, 3'd4);
        // Move  7: P2 Wait      -> mtw=7
        do_play(1'b1, 3'd4);
        // Move  8: P1 Wait      -> mtw=8 (last P1 wait)
        do_play(1'b0, 3'd4);
        // Move  9: P2 Wait      -> mtw=9 (last P2 wait)
        do_play(1'b1, 3'd4);
        // Move 10: P1 Kick      -> distance=1, p2_health 3->2, mtw=10
        do_play(1'b0, 3'd0);
        // Move 11: P1 Kick      -> distance=1, p2_health 2->1, mtw=11
        do_play(1'b0, 3'd0);
        // Move 12: P1 Kick      -> distance=1, p2_health 1->0 -> WIN, mtw=12
        do_play(1'b0, 3'd0);

        // After WIN: phase=SHOP, winner=01, moves_to_win=12
        if (winner !== 2'b01)
            $display("FAIL [T4-a] winner=%b (expected 01)", winner);
        else
            $display("PASS [T4-a] winner=01");

        if (phase !== 1'b1)
            $display("FAIL [T4-b] phase=%b (expected 1=SHOP after win)", phase);
        else
            $display("PASS [T4-b] phase=1 (SHOP) after P1 wins in 12 moves");

        // P1 buys item 0 with discount_mult=95 (moves_to_win=12, band >=10)
        // Expected cost = 100*95/100 = 95 -> p1_credit = 500-95 = 405
        credit_before = p1_credit;
        do_buy_p1(3'd0);

        if ((credit_before - p1_credit) !== 95)
            $display("FAIL [T4-c] credit delta=%0d (expected 95, mult=95)", credit_before - p1_credit);
        else
            $display("PASS [T4-c] credit delta=95 (discount mult=95 for 12-move win)");

        // ==============================================================
        // TEST 5: P2 wins in 6 moves -> P2 gets mult=80, P1 gets mult=100
        // ==============================================================
        $display("=== TEST 5: P2 wins in 6 moves (P2 mult=80, P1 mult=100) ===");

        do_reset;

        // SHOP: P2 buys 3x Kick(0), 2x MoveLeft(2)
        // P2 cost: 3*100 + 2*50 = 400. p2_credit = 100.
        do_buy_p2(3'd0); // Kick #1
        do_buy_p2(3'd0); // Kick #2
        do_buy_p2(3'd0); // Kick #3
        do_buy_p2(3'd2); // MoveLeft #1
        do_buy_p2(3'd2); // MoveLeft #2

        // P1 buys 1x MoveRight(3)
        // P1 cost: 50. p1_credit = 450.
        do_buy_p1(3'd3); // MoveRight #1
        do_buy_p1(3'd3); // MoveRight #2

        do_start;

        // Play sequence (6 moves -> WIN for P2)
        // Move 1: P1 MoveRight -> p1_pos 2->1, mtw=1
        do_play(1'b0, 3'd3);
        // Move 2: P1 MoveRight -> p1_pos 1->0, mtw=2, distance=0+2=2
        do_play(1'b0, 3'd3);
        // Move 3: P2 MoveLeft  -> p2_pos 2->1, mtw=3, distance=0+1=1
        do_play(1'b1, 3'd2);
        // Move 4: P2 Kick      -> distance=1, p1_health 3->2, mtw=4
        do_play(1'b1, 3'd0);
        // Move 5: P2 Kick      -> distance=1, p1_health 2->1, mtw=5
        do_play(1'b1, 3'd0);
        // Move 6: P2 Kick      -> distance=1, p1_health 1->0 -> WIN, mtw=6
        do_play(1'b1, 3'd0);

        // After WIN: phase=SHOP, winner=10, moves_to_win=6
        if (winner !== 2'b10)
            $display("FAIL [T5-a] winner=%b (expected 10)", winner);
        else
            $display("PASS [T5-a] winner=10");

        if (phase !== 1'b1)
            $display("FAIL [T5-b] phase=%b (expected 1=SHOP after win)", phase);
        else
            $display("PASS [T5-b] phase=1 (SHOP) after P2 wins");

        // P2 buys item 0 with discount_mult=80 (winner=10, moves_to_win=6 <=6)
        // Expected cost = 100*80/100 = 80 -> p2_credit = 500-80 = 420
        credit_before = p2_credit;
        do_buy_p2(3'd0);

        if ((credit_before - p2_credit) !== 80)
            $display("FAIL [T5-c] P2 credit delta=%0d (expected 80, mult=80)", credit_before - p2_credit);
        else
            $display("PASS [T5-c] P2 credit delta=80 (discount mult=80 for P2 win)");

        // P1 buys item 0 with discount_mult=100 (loser, full price)
        // Expected cost = 100*100/100 = 100 -> p1_credit = 500-100 = 400
        credit_before = p1_credit;
        do_buy_p1(3'd0);

        if ((credit_before - p1_credit) !== 100)
            $display("FAIL [T5-d] P1 credit delta=%0d (expected 100, loser full price)", credit_before - p1_credit);
        else
            $display("PASS [T5-d] P1 credit delta=100 (loser pays full price)");

        // ==============================================================
        // Summary
        // ==============================================================
        $display("--- tb_phase3 complete ---");
        $finish;
    end

endmodule
