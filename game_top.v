module game_top (
    input  wire        clk,
    input  wire        rst,
    input  wire        turn,
    input  wire        play_valid,
    input  wire [2:0]  play_action,
    input  wire        buy_valid_p1,
    input  wire [2:0]  buy_code_p1,
    input  wire        buy_valid_p2,
    input  wire [2:0]  buy_code_p2,
    input  wire        start_round,
    input  wire [9:0]  Price0,
    input  wire [9:0]  Price1,
    input  wire [9:0]  Price2,
    input  wire [9:0]  Price3,
    input  wire [9:0]  Price4,

    output reg         phase,
    output reg  [1:0]  p1_health,
    output reg  [1:0]  p2_health,
    output reg  [9:0]  p1_credit,
    output reg  [9:0]  p2_credit,
    output reg  [1:0]  p1_pos,
    output reg  [1:0]  p2_pos,
    output reg  [1:0]  winner,

    output wire        purchase_success_p1,
    output wire        err_invalid_action_p1,
    output wire        err_credit_p1,
    output wire        err_out_of_stock_p1,

    output wire        purchase_success_p2,
    output wire        err_invalid_action_p2,
    output wire        err_credit_p2,
    output wire        err_out_of_stock_p2,

    output reg         err_no_inventory,
    output reg         err_wrong_distance
);

    localparam PHASE_PLAY = 1'b0;
    localparam PHASE_SHOP = 1'b1;
    localparam ACT_KICK  = 3'd0;
    localparam ACT_PUNCH = 3'd1;
    localparam ACT_LEFT  = 3'd2;
    localparam ACT_RIGHT = 3'd3;
    localparam ACT_WAIT  = 3'd4;

    // Move inventory registers (unpacked arrays)
    reg [3:0] p1_moves [0:4];
    reg [3:0] p2_moves [0:4];

    reg [3:0] moves_to_win;

    reg [6:0] p1_discount_mult;
    reg [6:0] p2_discount_mult;

    // Combinational: distance between players
    wire [2:0] distance;
    assign distance = {1'b0, p1_pos} + {1'b0, p2_pos};

    // Internal wires for shop outputs
    wire [9:0] p1_credit_next;
    wire [9:0] p2_credit_next;
    wire [4:0] p1_grant_onehot;
    wire [4:0] p2_grant_onehot;

    // Combinational discount multiplier mux
    always @(*) begin
        if (winner == 2'b01) begin
            if      (moves_to_win <= 4'd6)  p1_discount_mult = 7'd80;
            else if (moves_to_win <= 4'd9)  p1_discount_mult = 7'd90;
            else                            p1_discount_mult = 7'd95;
            p2_discount_mult = 7'd100;
        end else if (winner == 2'b10) begin
            p1_discount_mult = 7'd100;
            if      (moves_to_win <= 4'd6)  p2_discount_mult = 7'd80;
            else if (moves_to_win <= 4'd9)  p2_discount_mult = 7'd90;
            else                            p2_discount_mult = 7'd95;
        end else begin
            p1_discount_mult = 7'd100;
            p2_discount_mult = 7'd100;
        end
    end

    // Player 1 shop instance
    shop shop_p1 (
        .clk              (clk),
        .rst              (rst),
        .buy_valid        (buy_valid_p1),
        .action_number    (buy_code_p1),
        .credit_in        (p1_credit),
        .discount_mult    (p1_discount_mult),
        .Price0           (Price0),
        .Price1           (Price1),
        .Price2           (Price2),
        .Price3           (Price3),
        .Price4           (Price4),
        .purchase_success (purchase_success_p1),
        .err_invalid_action(err_invalid_action_p1),
        .err_credit       (err_credit_p1),
        .err_out_of_stock (err_out_of_stock_p1),
        .credit_out       (p1_credit_next),
        .grant_onehot     (p1_grant_onehot)
    );

    // Player 2 shop instance
    shop shop_p2 (
        .clk              (clk),
        .rst              (rst),
        .buy_valid        (buy_valid_p2),
        .action_number    (buy_code_p2),
        .credit_in        (p2_credit),
        .discount_mult    (p2_discount_mult),
        .Price0           (Price0),
        .Price1           (Price1),
        .Price2           (Price2),
        .Price3           (Price3),
        .Price4           (Price4),
        .purchase_success (purchase_success_p2),
        .err_invalid_action(err_invalid_action_p2),
        .err_credit       (err_credit_p2),
        .err_out_of_stock (err_out_of_stock_p2),
        .credit_out       (p2_credit_next),
        .grant_onehot     (p2_grant_onehot)
    );

    // Sequential FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            phase              <= PHASE_SHOP;
            p1_health          <= 2'd3;
            p2_health          <= 2'd3;
            p1_credit          <= 10'd500;
            p2_credit          <= 10'd500;
            p1_pos             <= 2'd2;
            p2_pos             <= 2'd2;
            p1_moves[0]        <= 4'd0;
            p1_moves[1]        <= 4'd0;
            p1_moves[2]        <= 4'd0;
            p1_moves[3]        <= 4'd0;
            p1_moves[4]        <= 4'd0;
            p2_moves[0]        <= 4'd0;
            p2_moves[1]        <= 4'd0;
            p2_moves[2]        <= 4'd0;
            p2_moves[3]        <= 4'd0;
            p2_moves[4]        <= 4'd0;
            winner             <= 2'b00;
            moves_to_win       <= 4'd0;
            err_no_inventory   <= 1'b0;
            err_wrong_distance <= 1'b0;
        end else begin

            if (phase == PHASE_SHOP) begin
                // Latch updated credit from shop modules
                p1_credit <= p1_credit_next;
                p2_credit <= p2_credit_next;
                // Increment move counters from grant_onehot
                if (p1_grant_onehot[0]) p1_moves[0] <= p1_moves[0] + 4'd1;
                if (p1_grant_onehot[1]) p1_moves[1] <= p1_moves[1] + 4'd1;
                if (p1_grant_onehot[2]) p1_moves[2] <= p1_moves[2] + 4'd1;
                if (p1_grant_onehot[3]) p1_moves[3] <= p1_moves[3] + 4'd1;
                if (p1_grant_onehot[4]) p1_moves[4] <= p1_moves[4] + 4'd1;
                if (p2_grant_onehot[0]) p2_moves[0] <= p2_moves[0] + 4'd1;
                if (p2_grant_onehot[1]) p2_moves[1] <= p2_moves[1] + 4'd1;
                if (p2_grant_onehot[2]) p2_moves[2] <= p2_moves[2] + 4'd1;
                if (p2_grant_onehot[3]) p2_moves[3] <= p2_moves[3] + 4'd1;
                if (p2_grant_onehot[4]) p2_moves[4] <= p2_moves[4] + 4'd1;
                // SHOP -> PLAY transition
                if (start_round) begin
                    phase <= PHASE_PLAY;
                    winner <= 2'b00;
                    moves_to_win <= 4'd0;
                end
            end else begin // PHASE_PLAY
                err_no_inventory   <= 1'b0;
                err_wrong_distance <= 1'b0;
                if (play_valid) begin
                    if (turn == 1'b0) begin // P1 active
                        case (play_action)
                            ACT_KICK: begin
                                if (p1_moves[0] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p1_moves[0] <= p1_moves[0] - 4'd1;
                                    if (distance == 3'd1) begin
                                        if (p2_health <= 2'd1) begin
                                            phase <= PHASE_SHOP;
                                            winner <= 2'b01;
                                            p1_health <= 2'd3;
                                            p2_health <= 2'd3;
                                            p1_credit <= 10'd500;
                                            p2_credit <= 10'd500;
                                            p1_pos <= 2'd2;
                                            p2_pos <= 2'd2;
                                            p1_moves[0] <= 4'd0; p1_moves[1] <= 4'd0; p1_moves[2] <= 4'd0; p1_moves[3] <= 4'd0; p1_moves[4] <= 4'd0;
                                            p2_moves[0] <= 4'd0; p2_moves[1] <= 4'd0; p2_moves[2] <= 4'd0; p2_moves[3] <= 4'd0; p2_moves[4] <= 4'd0;
                                        end else begin
                                            p2_health <= p2_health - 2'd1;
                                        end
                                    end else begin
                                        err_wrong_distance <= 1'b1;
                                    end
                                end
                            end
                            ACT_PUNCH: begin
                                if (p1_moves[1] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p1_moves[1] <= p1_moves[1] - 4'd1;
                                    if (distance == 3'd0) begin
                                        if (p2_health <= 2'd2) begin
                                            phase <= PHASE_SHOP;
                                            winner <= 2'b01;
                                            p1_health <= 2'd3;
                                            p2_health <= 2'd3;
                                            p1_credit <= 10'd500;
                                            p2_credit <= 10'd500;
                                            p1_pos <= 2'd2;
                                            p2_pos <= 2'd2;
                                            p1_moves[0] <= 4'd0; p1_moves[1] <= 4'd0; p1_moves[2] <= 4'd0; p1_moves[3] <= 4'd0; p1_moves[4] <= 4'd0;
                                            p2_moves[0] <= 4'd0; p2_moves[1] <= 4'd0; p2_moves[2] <= 4'd0; p2_moves[3] <= 4'd0; p2_moves[4] <= 4'd0;
                                        end else begin
                                            p2_health <= p2_health - 2'd2;
                                        end
                                    end else begin
                                        err_wrong_distance <= 1'b1;
                                    end
                                end
                            end
                            ACT_LEFT: begin
                                if (p1_moves[2] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p1_moves[2] <= p1_moves[2] - 4'd1;
                                    if (p1_pos < 2'd2) p1_pos <= p1_pos + 2'd1;
                                end
                            end
                            ACT_RIGHT: begin
                                if (p1_moves[3] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p1_moves[3] <= p1_moves[3] - 4'd1;
                                    if (p1_pos > 2'd0) p1_pos <= p1_pos - 2'd1;
                                end
                            end
                            ACT_WAIT: begin
                                if (p1_moves[4] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p1_moves[4] <= p1_moves[4] - 4'd1;
                                end
                            end
                            default: ; // invalid action, do nothing
                        endcase
                    end else begin // P2 active
                        case (play_action)
                            ACT_KICK: begin
                                if (p2_moves[0] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p2_moves[0] <= p2_moves[0] - 4'd1;
                                    if (distance == 3'd1) begin
                                        if (p1_health <= 2'd1) begin
                                            phase <= PHASE_SHOP;
                                            winner <= 2'b10;
                                            p1_health <= 2'd3;
                                            p2_health <= 2'd3;
                                            p1_credit <= 10'd500;
                                            p2_credit <= 10'd500;
                                            p1_pos <= 2'd2;
                                            p2_pos <= 2'd2;
                                            p1_moves[0] <= 4'd0; p1_moves[1] <= 4'd0; p1_moves[2] <= 4'd0; p1_moves[3] <= 4'd0; p1_moves[4] <= 4'd0;
                                            p2_moves[0] <= 4'd0; p2_moves[1] <= 4'd0; p2_moves[2] <= 4'd0; p2_moves[3] <= 4'd0; p2_moves[4] <= 4'd0;
                                        end else begin
                                            p1_health <= p1_health - 2'd1;
                                        end
                                    end else begin
                                        err_wrong_distance <= 1'b1;
                                    end
                                end
                            end
                            ACT_PUNCH: begin
                                if (p2_moves[1] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p2_moves[1] <= p2_moves[1] - 4'd1;
                                    if (distance == 3'd0) begin
                                        if (p1_health <= 2'd2) begin
                                            phase <= PHASE_SHOP;
                                            winner <= 2'b10;
                                            p1_health <= 2'd3;
                                            p2_health <= 2'd3;
                                            p1_credit <= 10'd500;
                                            p2_credit <= 10'd500;
                                            p1_pos <= 2'd2;
                                            p2_pos <= 2'd2;
                                            p1_moves[0] <= 4'd0; p1_moves[1] <= 4'd0; p1_moves[2] <= 4'd0; p1_moves[3] <= 4'd0; p1_moves[4] <= 4'd0;
                                            p2_moves[0] <= 4'd0; p2_moves[1] <= 4'd0; p2_moves[2] <= 4'd0; p2_moves[3] <= 4'd0; p2_moves[4] <= 4'd0;
                                        end else begin
                                            p1_health <= p1_health - 2'd2;
                                        end
                                    end else begin
                                        err_wrong_distance <= 1'b1;
                                    end
                                end
                            end
                            ACT_LEFT: begin
                                if (p2_moves[2] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p2_moves[2] <= p2_moves[2] - 4'd1;
                                    if (p2_pos > 2'd0) p2_pos <= p2_pos - 2'd1;
                                end
                            end
                            ACT_RIGHT: begin
                                if (p2_moves[3] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p2_moves[3] <= p2_moves[3] - 4'd1;
                                    if (p2_pos < 2'd2) p2_pos <= p2_pos + 2'd1;
                                end
                            end
                            ACT_WAIT: begin
                                if (p2_moves[4] == 4'd0) begin
                                    err_no_inventory <= 1'b1;
                                end else begin
                                    moves_to_win <= moves_to_win + 4'd1;
                                    p2_moves[4] <= p2_moves[4] - 4'd1;
                                end
                            end
                            default: ; // invalid action, do nothing
                        endcase
                    end
                end
            end

        end
    end

endmodule
