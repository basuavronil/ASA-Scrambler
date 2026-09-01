module scrambler_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         Tx_phy_block_valid,  
    input  wire         Data_stream_en,      
    input  wire         Upstream_Downstream, 
    input  wire [2:0]   Spg,                 
    input  wire [1:0]   link_id,             
    input  wire [7:0]   data_in,             
    output reg  [7:0]   data_out_final,       // Named to match your exact instantiation
    output wire [7:0]   upstream_s0_debug,    // Added missing debug port
    output wire [183:0] upstream_state_debug, // Added missing debug port
    output wire [183:0] dnstream_state_debug  // Added missing debug port
);

    wire lfsr_en_up;
    wire lfsr_en_dn;
    
    wire [7:0] data_out_up;
    wire [7:0] data_out_dn;

    // Instantiate Control Module
    lfsr_enable_control u_control (
        .Tx_phy_block_valid (Tx_phy_block_valid),
        .Data_stream_en     (Data_stream_en),
        .Upstream_Downstream(Upstream_Downstream),
        .lfsr_en_up         (lfsr_en_up),
        .lfsr_en_dn         (lfsr_en_dn)
    );

    // Instantiate Upstream Core
    lfsr_upstream_8p u_upstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_up), 
        .Spg       (Spg),
        .link_id   (link_id),
        .data_in   (data_in),
        .data_out  (data_out_up),
        .state_out (upstream_state_debug),
        .s0_debug  (upstream_s0_debug)
    );

    // Instantiate Downstream Core
    lfsr_downstream_8p u_downstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_dn), 
        .Spg       (Spg),
        .link_id   (link_id),
        .data_in   (data_in),
        .data_out  (data_out_dn),
        .state_out (dnstream_state_debug)
    );

    // Multiplex Datapath Processing Options
    always @(*) begin
        if (Upstream_Downstream) begin
            data_out_final = data_out_up;
        end else begin
            data_out_final = data_out_dn;
        end
    end

endmodule
