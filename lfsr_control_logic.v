module scrambler_top (
    input  wire         clk,
    input  wire         rst,
    
    // Control interface
    input  wire         Tx_phy_block_valid,  // Valid signal from RS-FEC encoder
    input  wire         Data_stream_en,      // Data stream enable input
    input  wire         Upstream_Downstream, // High = Upstream, Low = Downstream
    input  wire [2:0]   Spg,                 // Speed grade configuration
    input  wire [1:0]   link_id,             // Link ID selection
    
    // Data interface
    input  wire [7:0]   data_in,             // 8-bit raw input data
    output reg  [7:0]   data_out,            // 8-bit processed output data
    output wire [183:0] state_out            // Shared flat-packed LFSR states
);

    // Internal routing lines
    wire lfsr_en_up;
    wire lfsr_en_dn;
    
    wire [7:0]   data_out_up;
    wire [7:0]   data_out_dn;
    wire [183:0] state_out_up;
    wire [183:0] state_out_dn;

    // 1. Instantiate the central Control Logic
    lfsr_enable_control u_control (
        .Tx_phy_block_valid (Tx_phy_block_valid),
        .Data_stream_en     (Data_stream_en),
        .Upstream_Downstream(Upstream_Downstream),
        .lfsr_en_up         (lfsr_en_up),
        .lfsr_en_dn         (lfsr_en_dn)
    );

    // 2. Instantiate the Upstream Scrambler 
    lfsr_upstream_8p u_upstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_up), // Maps control enable dynamically
        .Spg       (Spg),
        .link_id   (link_id),
        .data_in   (data_in),
        .data_out  (data_out_up),
        .state_out (state_out_up)
    );

    // 3. Instantiate the Downstream Scrambler
    lfsr_downstream_8p u_downstream (
        .clk       (clk),
        .rst       (rst),
        .Dnstr_en  (lfsr_en_dn), // Maps control enable dynamically
        .Spg       (Spg),
        .link_id   (link_id),
        .data_in   (data_in),
        .data_out  (data_out_dn),
        .state_out (state_out_dn)
    );

    // 4. Multiplex Outputs based on operational path selection
    always @(*) begin
        if (Upstream_Downstream) begin
            data_out = data_out_up;
        end else begin
            data_out = data_out_dn;
        end
    end

    // Direct assignment for flat-packed state reporting
    assign state_out = (Upstream_Downstream) ? state_out_up : state_out_dn;

endmodule
