module lfsr_upstream_8p (
    input  wire          clk,
    input  wire          rst,
    input  wire          Dnstr_en,    
    input  wire [2:0]    Spg,         
    input  wire [1:0]    link_id,
    input  wire [7:0]    data_in,     
    output wire [7:0]    data_out,    
    output wire [183:0] state_out,   
    output wire [7:0]    s0_debug     // Exposed to pass up to top level
);

    reg [22:0] base_seed;
    always @(*) begin
        case (link_id)
            2'd0 : base_seed = 23'h000001;
            2'd1 : base_seed = 23'h000003;
            2'd2 : base_seed = 23'h000005;
            2'd3 : base_seed = 23'h000007;
            default: base_seed = 23'h000001;
        endcase
    end

    wire [22:0] seed [0:7];
    assign seed[0] = base_seed;
    assign seed[1] = {seed[0][0], seed[0][22:1]};
    assign seed[2] = {seed[1][0], seed[1][22:1]};
    assign seed[3] = {seed[2][0], seed[2][22:1]};
    assign seed[4] = {seed[3][0], seed[3][22:1]};
    assign seed[5] = {seed[4][0], seed[4][22:1]};
    assign seed[6] = {seed[5][0], seed[5][22:1]};
    assign seed[7] = {seed[6][0], seed[6][22:1]};

    reg [22:0] lfsr [0:7];
    always @(posedge clk) begin
        if (rst) begin
            lfsr[0] <= (seed[0] == 23'd0) ? 23'd1 : seed[0];
            lfsr[1] <= (seed[1] == 23'd0) ? 23'd1 : seed[1];
            lfsr[2] <= (seed[2] == 23'd0) ? 23'd1 : seed[2];
            lfsr[3] <= (seed[3] == 23'd0) ? 23'd1 : seed[3];
            lfsr[4] <= (seed[4] == 23'd0) ? 23'd1 : seed[4];
            lfsr[5] <= (seed[5] == 23'd0) ? 23'd1 : seed[5];
            lfsr[6] <= (seed[6] == 23'd0) ? 23'd1 : seed[6];
            lfsr[7] <= (seed[7] == 23'd0) ? 23'd1 : seed[7];
        end else if (Dnstr_en) begin
            lfsr[0] <= {lfsr[0][22] ^ lfsr[0][17], lfsr[0][21:1]};
            lfsr[1] <= {lfsr[1][22] ^ lfsr[1][17], lfsr[1][21:1]};
            lfsr[2] <= {lfsr[2][22] ^ lfsr[2][17], lfsr[2][21:1]};
            lfsr[3] <= {lfsr[3][22] ^ lfsr[3][17], lfsr[3][21:1]};
            lfsr[4] <= {lfsr[4][22] ^ lfsr[4][17], lfsr[4][21:1]};
            lfsr[5] <= {lfsr[5][22] ^ lfsr[5][17], lfsr[5][21:1]};
            lfsr[6] <= {lfsr[6][22] ^ lfsr[6][17], lfsr[6][21:1]};
            lfsr[7] <= {lfsr[7][22] ^ lfsr[7][17], lfsr[7][21:1]};
        end
    end

    assign s0_debug[0] = lfsr[0][0];
    assign s0_debug[1] = lfsr[1][0];
    assign s0_debug[2] = lfsr[2][0];
    assign s0_debug[3] = lfsr[3][0];
    assign s0_debug[4] = lfsr[4][0];
    assign s0_debug[5] = lfsr[5][0];
    assign s0_debug[6] = lfsr[6][0];
    assign s0_debug[7] = lfsr[7][0];

    assign data_out = data_in ^ s0_debug;

    assign state_out[22:0]    = lfsr[0];
    assign state_out[45:23]   = lfsr[1];
    assign state_out[68:46]   = lfsr[2];
    assign state_out[91:69]   = lfsr[3];
    assign state_out[114:92]  = lfsr[4];
    assign state_out[137:115] = lfsr[5];
    assign state_out[160:138] = lfsr[6];
    assign state_out[183:161] = lfsr[7];

endmodule
