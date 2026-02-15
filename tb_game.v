`timescale 1ns/1ps
module tb_game;

    // ---- Input registers ----
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
    reg [9:0]  Price0;
    reg [9:0]  Price1;
    reg [9:0]  Price2;
    reg [9:0]  Price3;
    reg [9:0]  Price4;

    // ---- Output wires ----
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

    // ---- Clock generation: 10 ns period ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- DUT instantiation ----
    game_top uut (
        .clk(clk), .rst(rst), .turn(turn), .play_valid(play_valid),
        .play_action(play_action), .buy_valid_p1(buy_valid_p1),
        .buy_code_p1(buy_code_p1), .buy_valid_p2(buy_valid_p2),
        .buy_code_p2(buy_code_p2), .start_round(start_round),
        .Price0(Price0), .Price1(Price1), .Price2(Price2),
        .Price3(Price3), .Price4(Price4),
        .phase(phase), .p1_health(p1_health), .p2_health(p2_health),
        .p1_credit(p1_credit), .p2_credit(p2_credit),
        .p1_pos(p1_pos), .p2_pos(p2_pos), .winner(winner),
        .purchase_success_p1(purchase_success_p1),
        .err_invalid_action_p1(err_invalid_action_p1),
        .err_credit_p1(err_credit_p1),
        .err_out_of_stock_p1(err_out_of_stock_p1),
        .purchase_success_p2(purchase_success_p2),
        .err_invalid_action_p2(err_invalid_action_p2),
        .err_credit_p2(err_credit_p2),
        .err_out_of_stock_p2(err_out_of_stock_p2),
        .err_no_inventory(err_no_inventory),
        .err_wrong_distance(err_wrong_distance)
    );

    // ---- Helper tasks (plain Verilog style) ----
    task buy_p1;
        input [2:0] code;
        begin
            @(negedge clk);              // align to negedge so combinational settles before posedge
            buy_valid_p1 = 1; buy_code_p1 = code;
            @(posedge clk);              // cycle N: shop processes with settled combinational
            @(negedge clk);
            buy_valid_p1 = 0;            // deassert at negedge before cycle N+1
            @(posedge clk);              // cycle N+1: game_top reads grant, updates inventory
        end
    endtask

    task buy_p2;
        input [2:0] code;
        begin
            @(negedge clk);
            buy_valid_p2 = 1; buy_code_p2 = code;
            @(posedge clk);
            @(negedge clk);
            buy_valid_p2 = 0;
            @(posedge clk);
        end
    endtask

    task do_play;
        input       t;
        input [2:0] act;
        begin
            turn = t; play_action = act; play_valid = 1;
            @(posedge clk);
            play_valid = 0;
            @(posedge clk);
        end
    endtask

    task do_reset;
        begin
            rst = 1; @(posedge clk); @(posedge clk);
            rst = 0; @(posedge clk);
        end
    endtask

    task do_start_round;
        begin
            start_round = 1; @(posedge clk);
            start_round = 0; @(posedge clk);
        end
    endtask

    // ---- Main test sequence ----
    initial begin
        // Default signal values
        clk=0; rst=0; turn=0; play_valid=0; play_action=0;
        buy_valid_p1=0; buy_code_p1=0;
        buy_valid_p2=0; buy_code_p2=0;
        start_round=0;
        Price0=100; Price1=120; Price2=50; Price3=50; Price4=30;

        $display("=== TB_GAME START ===");

        // =========================================================
        // GROUP A: Shop error tests + combat tests
        // =========================================================
        $display("--- GROUP A: Error tests + combat ---");
        do_reset;

        // Step 2: Invalid action
        $display("-- TEST 1: Invalid action --");
        buy_p1(3'd5);
        // err_invalid_action fires as combinational in shop.v; visible in [SHOP] log

        // Step 3: 5x Wait (drain stock to 0)
        buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4);
        // P1 credit: 500-150=350. Wait stock: 0.

        // Step 4: Out-of-stock
        $display("-- TEST 2: Out-of-stock --");
        buy_p1(3'd4); // 6th Wait -> ERR_OUT_OF_STOCK

        // Steps 5-7: Buy play inventory
        buy_p1(3'd2);                               // 1x Left. Credit: 350-50=300.
        buy_p1(3'd3); buy_p1(3'd3); buy_p1(3'd3);  // 3x Right. Credit: 300-150=150.
        buy_p1(3'd0);                               // 1x Kick. Credit: 150-100=50.

        // Step 8: Insufficient credit
        $display("-- TEST 3: Insufficient credit --");
        buy_p1(3'd1); // Punch=120, credit=50 -> ERR_CREDIT

        // Steps 9-11: P2 buys
        buy_p2(3'd0); buy_p2(3'd0); // 2x Kick. Credit: 500-200=300.
        buy_p2(3'd1);               // 1x Punch. Credit: 300-120=180.
        buy_p2(3'd2); buy_p2(3'd2); // 2x Left. Credit: 180-100=80.

        // Step 12: Start round
        do_start_round;

        // ---- PLAY PHASE ----
        // Step 13: P1 Left saturation (pos=2, stays 2)
        $display("-- TEST 4: Left saturation --");
        do_play(1'b0, 3'd2); // P1 MoveLeft: pos=2 saturates
        if (p1_pos == 2'd2) $display("PASS [T4]: p1_pos=2 (left sat)");
        else $display("FAIL [T4]: p1_pos=%0d", p1_pos);

        // Steps 14-15: P1 moves right to pos=0
        do_play(1'b0, 3'd3); // p1_pos 2->1
        do_play(1'b0, 3'd3); // p1_pos 1->0

        // Step 16: P1 Right saturation (pos=0, stays 0)
        $display("-- TEST 5: Right saturation --");
        do_play(1'b0, 3'd3); // P1 MoveRight: pos=0 saturates
        if (p1_pos == 2'd0) $display("PASS [T5]: p1_pos=0 (right sat)");
        else $display("FAIL [T5]: p1_pos=%0d", p1_pos);
        // State: P1 pos=0, P2 pos=2. dist=2.

        // Step 17: P2 MoveLeft (pos 2->1), dist=1
        do_play(1'b1, 3'd2);

        // Step 18: P2 Kick at dist=1 -> 1 damage
        $display("-- TEST 7: Kick at dist=1 --");
        do_play(1'b1, 3'd0); // P2 Kick: p1_health 3->2
        if (p1_health == 2'd2) $display("PASS [T7]: kick dealt 1 dmg");
        else $display("FAIL [T7]: p1_health=%0d", p1_health);

        // Step 19: P2 MoveLeft (pos 1->0), dist=0
        do_play(1'b1, 3'd2);

        // Step 20: P2 Punch at dist=0 -> win
        $display("-- TEST 6+8: Punch at dist=0 + Win --");
        do_play(1'b1, 3'd1); // P2 Punch: p1_health 2->0 (2<=2 WIN). P2 wins.
        // mtw=8 (P1:4 moves + P2:4 moves). Band 2 (7-9). mult=90.
        if (winner == 2'b10) $display("PASS [T6+T8]: P2 wins, winner=2");
        else $display("FAIL [T6+T8]: winner=%0b", winner);
        if (phase == 1'b1) $display("PASS: phase=SHOP after win");
        else $display("FAIL: phase=%0b", phase);

        // =========================================================
        // GROUP B: Band 2 discount (mult=90, 10% off)
        // =========================================================
        $display("--- GROUP B: Band 2 discount (mult=90) ---");
        $display("-- TEST 9a: Expecting Discounted=90 in SHOP log --");
        buy_p2(3'd0); // P2 buys Kick: price=100, mult=90 -> discounted=90

        // =========================================================
        // GROUP C: Band 1 discount (<=6 moves, mult=80, 20% off)
        // =========================================================
        $display("--- GROUP C: Band 1 discount (mult=80) ---");
        do_reset;
        buy_p1(3'd1); buy_p1(3'd1); // 2x Punch=240. Credit: 500->260.
        buy_p1(3'd3); buy_p1(3'd3); // 2x Right=100. Credit: 260->160.
        buy_p2(3'd2); buy_p2(3'd2); // P2: 2x Left=100. Credit: 500->400.
        do_start_round;

        do_play(1'b0, 3'd3); // P1 Right: p1_pos 2->1. mtw=1
        do_play(1'b0, 3'd3); // P1 Right: p1_pos 1->0. mtw=2
        do_play(1'b1, 3'd2); // P2 Left: p2_pos 2->1. mtw=3
        do_play(1'b1, 3'd2); // P2 Left: p2_pos 1->0. dist=0. mtw=4
        do_play(1'b0, 3'd1); // P1 Punch: p2_health 3->1. mtw=5
        do_play(1'b0, 3'd1); // P1 Punch: p2_health 1<=2 -> WIN. mtw=6. P1 wins.
        if (winner == 2'b01) $display("PASS [C]: P1 wins, mtw=6 -> band 1");
        else $display("FAIL [C]: winner=%0b", winner);

        $display("-- TEST 9b: Expecting Discounted=80 in SHOP log --");
        buy_p1(3'd0); // P1 buys Kick: price=100, mult=80 -> discounted=80

        // =========================================================
        // GROUP D: Band 3 discount (>=10 moves, mult=95, 5% off)
        // =========================================================
        $display("--- GROUP D: Band 3 discount (mult=95) ---");
        do_reset;
        buy_p1(3'd1); buy_p1(3'd1);               // 2x Punch=240. Credit: 500->260.
        buy_p1(3'd3); buy_p1(3'd3);               // 2x Right=100. Credit: 260->160.
        buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4); buy_p1(3'd4); // 5x Wait=150. Credit: 160->10.
        buy_p2(3'd2); buy_p2(3'd2);               // P2: 2x Left=100. Credit: 500->400.
        buy_p2(3'd4); buy_p2(3'd4); buy_p2(3'd4); buy_p2(3'd4); buy_p2(3'd4); // P2: 5x Wait=150. Credit: 400->250.
        do_start_round;

        do_play(1'b0, 3'd3); // P1 Right: p1_pos 2->1. mtw=1
        do_play(1'b0, 3'd3); // P1 Right: p1_pos 1->0. mtw=2
        do_play(1'b1, 3'd2); // P2 Left: p2_pos 2->1. mtw=3
        do_play(1'b1, 3'd2); // P2 Left: p2_pos 1->0. dist=0. mtw=4
        do_play(1'b0, 3'd4); // P1 Wait. mtw=5
        do_play(1'b0, 3'd4); // P1 Wait. mtw=6
        do_play(1'b0, 3'd4); // P1 Wait. mtw=7
        do_play(1'b0, 3'd4); // P1 Wait. mtw=8
        do_play(1'b0, 3'd4); // P1 Wait. mtw=9
        do_play(1'b1, 3'd4); // P2 Wait. mtw=10
        do_play(1'b0, 3'd1); // P1 Punch: p2_health 3->1. mtw=11
        do_play(1'b0, 3'd1); // P1 Punch: p2_health 1<=2 -> WIN. mtw=12. P1 wins.
        if (winner == 2'b01) $display("PASS [D]: P1 wins, mtw=12 -> band 3");
        else $display("FAIL [D]: winner=%0b", winner);

        $display("-- TEST 9c: Expecting Discounted=95 in SHOP log --");
        buy_p1(3'd0); // P1 buys Kick: price=100, mult=95 -> discounted=95

        $display("=== TB_GAME COMPLETE ===");
        $finish;
    end

endmodule
