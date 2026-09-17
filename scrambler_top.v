module scrambler_top (
    input  wire         clk,
    input  wire         rst,
    input  wire         Tx_phy_block_valid,
    input  wire         Data_stream_en,
    input  wire         Upstream_Downstream,
    input  wire [2:0]   Spg,
    input  wire [1:0]   link_id,
    input  wire [7:0]   data_in,
    input  wire         scrambler_en,          // Asserted at the start of 8-bit input data (valid)
    output reg  [7:0]   data_out_final,        // 8-bit scrambled output byte
    output reg          scrambler_done,        // 1-cycle pulse when all 8 bits are scrambled
    output reg          scrambler_ready,       // Held high once 8-bit scrambled output is ready
    output wire [7:0]   upstream_s0_debug,     // Debug port
    output wire [183:0] upstream_state_debug,  // Debug port
    output wire [183:0] dnstream_state_debug   // Debug port
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

    // Gate the control-module enables with scrambler_en
    wire lfsr_en_up_gated = lfsr_en_up & scrambler_en;
    wire lfsr_en_dn_gated = lfsr_en_dn & scrambler_en;

    // Instantiate Upstream Core (Parallel 8-bit LFSR)
    lfsr_upstream_8p u_upstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_up_gated),
        .link_id   (link_id),
        .data_in   (data_in),
        .data_out  (data_out_up),
        .state_out (upstream_state_debug),
        .s0_debug  (upstream_s0_debug)
    );

    // Instantiate Downstream Core (Parallel 8-bit LFSR)
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

    // Datapath Mux (Combinatorial output selection)
    always @(*) begin
        if (Upstream_Downstream) begin
            data_out_final = data_out_up;
        end else begin
            data_out_final = data_out_dn;
        end
    end

    // Gated active enable signal for tracking active processing channel
    wire active_en_gated = Upstream_Downstream ? lfsr_en_up_gated : lfsr_en_dn_gated;

    // Output Handshake Logic (Parallel Byte Processed)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            scrambler_done  <= 1'b0;
            scrambler_ready <= 1'b0;
        end else begin
            // scrambler_done pulses high for 1 cycle when scrambled byte is registered
            scrambler_done  <= active_en_gated;

            // scrambler_ready stays high following a valid parallel 8-bit write 
            // until rst or next sequence step
            if (active_en_gated) begin
                scrambler_ready <= 1'b1;
            end
        end
    end

endmodule
