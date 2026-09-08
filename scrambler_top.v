module scrambler_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         Tx_phy_block_valid,
    input  wire         Data_stream_en,
    input  wire         Upstream_Downstream,
    input  wire [2:0]   Spg,
    input  wire [1:0]   link_id,
    input  wire [7:0]   data_in,
    input  wire         scrambler_en,          // NEW: asserted by RS-FEC encoder when data_in is valid to scramble
    output reg  [7:0]   data_out_final,        // Named to match your exact instantiation
    output reg          scrambler_done,        // NEW: pulses 1 cycle when a scrambled byte is ready on data_out_final
    output wire [7:0]   upstream_s0_debug,     // Added missing debug port
    output wire [183:0] upstream_state_debug,  // Added missing debug port
    output wire [183:0] dnstream_state_debug   // Added missing debug port
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

    // Gate the control-module enables with scrambler_en (RS-FEC valid handshake)
    wire lfsr_en_up_gated = lfsr_en_up & scrambler_en;
    wire lfsr_en_dn_gated = lfsr_en_dn & scrambler_en;

    // Instantiate Upstream Core
    lfsr_upstream_8p u_upstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_up_gated),
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
        .Dnstr_en  (lfsr_en_dn_gated),
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

    // NEW: scrambler_done pulse generation
    // Selects the active-path enable that was actually sampled this cycle,
    // then delays it by one clock so the pulse lines up with the cycle in
    // which the scrambled byte (8 parallel bits) appears on data_out_final.
    wire active_en_gated = Upstream_Downstream ? lfsr_en_up_gated : lfsr_en_dn_gated;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scrambler_done <= 1'b0;
        end else begin
            scrambler_done <= active_en_gated;
        end
    end

endmodule
