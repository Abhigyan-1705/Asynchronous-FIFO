// Dual-port memory array for the asynchronous FIFO. 
// Write port is synchronous to wr_clk; read port is
// combinational (asynchronous read), giving zero read latency.
`timescale 1ns/1ps

module fifo_mem #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Write port (wr_clk domain)
    input  wire                    wr_clk,
    input  wire                    wr_en,
    input  wire [ADDR_WIDTH-1:0]   wr_addr,
    input  wire [DATA_WIDTH-1:0]   wr_data,

    // Read port (combinational / rd_clk domain address source)
    input  wire [ADDR_WIDTH-1:0]   rd_addr,
    output wire [DATA_WIDTH-1:0]   rd_data
);
    // Memory array: 2^ADDR_WIDTH entries, each DATA_WIDTH bits wide.
    // No reset applied — stale data at unaddressed locations is
    // harmless since valid pointers never expose unwritten entries.
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Sync write port
    always @(posedge wr_clk) begin
        if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // async/comb read port
    assign rd_data = mem[rd_addr];

endmodule