`timescale 1ns/1ps
module tb_shop;

    // DUT connections
    reg        clk, rst, buy_valid;
    reg  [2:0] action_number;
    reg  [9:0] credit_in;
    reg  [6:0] discount_mult;
    reg  [9:0] Price0, Price1, Price2, Price3, Price4;
    wire       purchase_success, err_invalid_action, err_credit, err_out_of_stock;
    wire [9:0] credit_out;
    wire [4:0] grant_onehot;

    // Instantiate DUT
    shop dut (
        .clk(clk),              .rst(rst),              .buy_valid(buy_valid),
        .action_number(action_number),                  .credit_in(credit_in),
        .discount_mult(discount_mult),
        .Price0(Price0),        .Price1(Price1),        .Price2(Price2),
        .Price3(Price3),        .Price4(Price4),
        .purchase_success(purchase_success),
        .err_invalid_action(err_invalid_action),
        .err_credit(err_credit),
        .err_out_of_stock(err_out_of_stock),
        .credit_out(credit_out),
        .grant_onehot(grant_onehot)
    );

    // Clock: 10 ns period (posedge every 5 ns)
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        // --------------------------------------------------------
        // Setup: prices, reset, no purchase
        // --------------------------------------------------------
        rst           = 1;
        buy_valid     = 0;
        discount_mult = 7'd100;         // no discount
        Price0        = 10'd120;        // Kick
        Price1        = 10'd200;        // Punch
        Price2        = 10'd50;         // Left
        Price3        = 10'd50;         // Right
        Price4        = 10'd10;         // Wait
        credit_in     = 10'd1000;
        action_number = 3'd0;

        // Hold reset for 2 cycles
        repeat(2) @(posedge clk); #1;
        rst = 0;
        // One more cycle to settle after reset (stock is now 5 for each item)
        @(posedge clk); #1;

        // --------------------------------------------------------
        // TEST A: Invalid action (action_number = 6 → err_invalid_action)
        // --------------------------------------------------------
        action_number = 3'd6;
        buy_valid     = 1;
        @(posedge clk); #1;
        $display("TEST A: err_invalid_action=%b (expect 1), purchase_success=%b (expect 0), credit_out=%0d (expect 1000)",
                 err_invalid_action, purchase_success, credit_out);
        buy_valid = 0;
        @(posedge clk); #1;

        // --------------------------------------------------------
        // TEST B: Insufficient credit — Punch costs 200, credit = 50
        // --------------------------------------------------------
        action_number = 3'd1;
        credit_in     = 10'd50;
        buy_valid     = 1;
        @(posedge clk); #1;
        $display("TEST B: err_credit=%b (expect 1), err_invalid_action=%b (expect 0), purchase_success=%b (expect 0), credit_out=%0d (expect 50)",
                 err_credit, err_invalid_action, purchase_success, credit_out);
        buy_valid     = 0;
        credit_in     = 10'd1000;       // restore credit for next tests
        @(posedge clk); #1;

        // --------------------------------------------------------
        // TEST C: Successful purchase — Kick costs 120, credit = 1000
        //   Expected: credit_out = 1000 - 120 = 880, grant_onehot = 00001
        // --------------------------------------------------------
        action_number = 3'd0;
        credit_in     = 10'd1000;
        buy_valid     = 1;
        @(posedge clk); #1;
        $display("TEST C: purchase_success=%b (expect 1), credit_out=%0d (expect 880), grant_onehot=%b (expect 00001)",
                 purchase_success, credit_out, grant_onehot);
        // Pass updated credit back (simulate game_top storing credit_out)
        buy_valid = 0;
        credit_in = credit_out;         // 880
        @(posedge clk); #1;

        // --------------------------------------------------------
        // TEST D: Out of stock — drain remaining 4 Kick stock
        //   (stock[0] was 5, Test C bought one → 4 remain)
        // --------------------------------------------------------

        // Purchase 2 of 5
        action_number = 3'd0; buy_valid = 1;
        @(posedge clk); #1;
        buy_valid = 0; credit_in = credit_out;  // 760
        @(posedge clk); #1;

        // Purchase 3 of 5
        action_number = 3'd0; buy_valid = 1;
        @(posedge clk); #1;
        buy_valid = 0; credit_in = credit_out;  // 640
        @(posedge clk); #1;

        // Purchase 4 of 5
        action_number = 3'd0; buy_valid = 1;
        @(posedge clk); #1;
        buy_valid = 0; credit_in = credit_out;  // 520
        @(posedge clk); #1;

        // Purchase 5 of 5 — stock[0] goes to 0
        action_number = 3'd0; buy_valid = 1;
        @(posedge clk); #1;
        buy_valid = 0; credit_in = credit_out;  // 400
        @(posedge clk); #1;

        // 6th attempt: stock[0] = 0 → err_out_of_stock
        action_number = 3'd0; buy_valid = 1;
        @(posedge clk); #1;
        $display("TEST D: err_out_of_stock=%b (expect 1), purchase_success=%b (expect 0), credit_out=%0d (expect 400)",
                 err_out_of_stock, purchase_success, credit_out);
        buy_valid = 0;
        @(posedge clk); #1;

        // --------------------------------------------------------
        // TEST E: Discount verification — discount_mult = 80 (20% off)
        //   Kick: (120 * 80) / 100 = 96 → credit_out = 1000 - 96 = 904
        // --------------------------------------------------------
        // Reset DUT to restore stock
        rst = 1;
        repeat(2) @(posedge clk); #1;
        rst = 0;
        @(posedge clk); #1;

        credit_in     = 10'd1000;
        discount_mult = 7'd80;
        action_number = 3'd0;
        buy_valid     = 1;
        @(posedge clk); #1;
        $display("TEST E: purchase_success=%b (expect 1), credit_out=%0d (expect 904), grant_onehot=%b (expect 00001)",
                 purchase_success, credit_out, grant_onehot);
        buy_valid = 0;
        @(posedge clk); #1;

        // --------------------------------------------------------
        $display("--- tb_shop complete ---");
        $finish;
    end

endmodule
