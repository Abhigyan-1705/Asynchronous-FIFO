`timescale 1ns/1ps

module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16 // Must be a power of two,
                              // later will make it arbitrary
)(
    // Write domain
    input  wire                  wr_clk,
    input  wire                  rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // Read domain
    input  wire                  rd_clk,
    input  wire                  rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);
    // address width from FIFO depth
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // Internal cross-domain wiring (gray pointers).
    // Synchronization happens in write_ptr / read_ptr, not here.
    wire [ADDR_WIDTH:0]   wr_ptr_gray;
    wire [ADDR_WIDTH:0]   rd_ptr_gray;
    wire [ADDR_WIDTH-1:0] wr_addr;
    wire [ADDR_WIDTH-1:0] rd_addr;

    // Write pointer logic (wr_clk domain)
    write_ptr #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_write_ptr (
        .wr_clk       (wr_clk),
        .rst_n        (rst_n),
        .wr_en        (wr_en),
        .rd_ptr_gray  (rd_ptr_gray),   // async input from read domain
        .wr_addr      (wr_addr),
        .wr_ptr_gray  (wr_ptr_gray),
        .full         (full)
    );

    // Read pointer logic (rd_clk domain)
    read_ptr #(
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_read_ptr (
        .rd_clk       (rd_clk),
        .rst_n        (rst_n),
        .rd_en        (rd_en),
        .wr_ptr_gray  (wr_ptr_gray),   // async input from write domain
        .rd_addr      (rd_addr),
        .rd_ptr_gray  (rd_ptr_gray),
        .empty        (empty)
    );

    // Dual-port memory array
    fifo_mem #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_fifo_mem (
        .wr_clk   (wr_clk),
        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data)
    );

endmodule