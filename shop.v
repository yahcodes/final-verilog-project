module shop (
    input  wire        clk,
    input  wire        rst,
    input  wire        buy_valid,
    input  wire [2:0]  action_number,
    input  wire [9:0]  credit_in,
    input  wire [6:0]  discount_mult,
    input  wire [9:0]  Price0,
    input  wire [9:0]  Price1,
    input  wire [9:0]  Price2,
    input  wire [9:0]  Price3,
    input  wire [9:0]  Price4,
    output reg         purchase_success,
    output reg         err_invalid_action,
    output reg         err_credit,
    output reg         err_out_of_stock,
    output reg  [9:0]  credit_out,
    output reg  [4:0]  grant_onehot
);

    localparam ACT_KICK  = 3'd0;
    localparam ACT_PUNCH = 3'd1;
    localparam ACT_LEFT  = 3'd2;
    localparam ACT_RIGHT = 3'd3;
    localparam ACT_WAIT  = 3'd4;

    reg [3:0] shop_stock [0:4];

    reg [9:0]  price_selected;
    reg [9:0]  discounted_price;
    reg [16:0] price_tmp;
    reg        valid_action;
    reg        enough_credit;
    reg        in_stock;

    // ----------------------------------------------------------------
    // Combinational block
    // ----------------------------------------------------------------
    always @(*) begin
        // Price mux
        case (action_number)
            3'd0:    price_selected = Price0;
            3'd1:    price_selected = Price1;
            3'd2:    price_selected = Price2;
            3'd3:    price_selected = Price3;
            3'd4:    price_selected = Price4;
            default: price_selected = 10'd0;
        endcase

        // Discount: (price * discount_mult) / 100
        // Use 17-bit intermediate to avoid overflow (max = 1023 * 127 = 129921 < 2^17)
        price_tmp        = {7'd0, price_selected} * {10'd0, discount_mult};
        discounted_price = price_tmp / 17'd100;

        // Action validity
        valid_action = (action_number <= 3'd4);

        // Stock check — use case to avoid out-of-bounds array indexing
        case (action_number)
            3'd0:    in_stock = (shop_stock[0] > 4'd0);
            3'd1:    in_stock = (shop_stock[1] > 4'd0);
            3'd2:    in_stock = (shop_stock[2] > 4'd0);
            3'd3:    in_stock = (shop_stock[3] > 4'd0);
            3'd4:    in_stock = (shop_stock[4] > 4'd0);
            default: in_stock = 1'b0;
        endcase

        // Credit sufficiency
        enough_credit = (credit_in >= discounted_price);

        // Purchase success: all conditions met
        purchase_success = buy_valid & valid_action & enough_credit & in_stock;

        // Error signals — mutually exclusive, priority: invalid > credit > out_of_stock
        err_invalid_action = buy_valid & ~valid_action;
        err_credit         = buy_valid &  valid_action & ~enough_credit;
        err_out_of_stock   = buy_valid &  valid_action &  enough_credit & ~in_stock;
    end

    // ----------------------------------------------------------------
    // Sequential state updates
    // ----------------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shop_stock[0] <= 4'd5;
            shop_stock[1] <= 4'd5;
            shop_stock[2] <= 4'd5;
            shop_stock[3] <= 4'd5;
            shop_stock[4] <= 4'd5;
            grant_onehot  <= 5'b00000;
            credit_out    <= credit_in;
        end else begin
            if (purchase_success) begin
                credit_out                <= credit_in - discounted_price;
                shop_stock[action_number] <= shop_stock[action_number] - 4'd1;
                // One-hot grant pulse for this action (action_number is 0-4 here)
                case (action_number)
                    3'd0:    grant_onehot <= 5'b00001;
                    3'd1:    grant_onehot <= 5'b00010;
                    3'd2:    grant_onehot <= 5'b00100;
                    3'd3:    grant_onehot <= 5'b01000;
                    3'd4:    grant_onehot <= 5'b10000;
                    default: grant_onehot <= 5'b00000;
                endcase
            end else begin
                grant_onehot <= 5'b00000;
                credit_out   <= credit_in;
            end
        end
    end

endmodule
