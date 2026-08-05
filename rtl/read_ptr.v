`timescale 1ns/1ps

module read_ptr #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                     rd_clk,
    input  wire                     rst_n,
    input  wire                     rd_en,

    input  wire [ADDR_WIDTH:0]      wr_ptr_gray,     // async, from write domain

    output wire [ADDR_WIDTH-1:0]    rd_addr,
    output reg  [ADDR_WIDTH:0]      rd_ptr_gray,
    output reg                      empty
);
    // Binary read pointer (extra MSB for wrap)
    reg  [ADDR_WIDTH:0] rd_ptr_bin;
    wire [ADDR_WIDTH:0] rd_ptr_bin_next;
    wire [ADDR_WIDTH:0] rd_ptr_gray_next;

    assign rd_ptr_bin_next  = rd_ptr_bin + (rd_en && !empty);
    assign rd_addr           = rd_ptr_bin[ADDR_WIDTH-1:0];

    // Gray-code conversion of the *next* binary pointer (combinational,
    bin2gray #(
        .WIDTH (ADDR_WIDTH+1)
    ) u_bin2gray_rd (
        .bin  (rd_ptr_bin_next),
        .gray (rd_ptr_gray_next)
    );
    // Synchronize write pointer (Gray) into rd_clk domain
    wire [ADDR_WIDTH:0] wr_ptr_gray_sync;

    sync_2ff #(
        .WIDTH (ADDR_WIDTH+1)
    ) u_sync_wr_ptr (
        .clk      (rd_clk),
        .rst_n    (rst_n),
        .async_in (wr_ptr_gray),
        .sync_out (wr_ptr_gray_sync)
    );
    // Register binary and Gray read pointers
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            rd_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;
        end
    end
    // Empty flag generation
    // FIFO is empty when the next read pointer (Gray) exactly equals
    // the synchronized write pointer
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin
            empty <= 1'b1;   // FIFO starts empty after reset
        end else begin
            empty <= (rd_ptr_gray_next == wr_ptr_gray_sync);
        end
    end

endmodule