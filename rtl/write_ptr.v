`timescale 1ns/1ps

module write_ptr #(
    parameter ADDR_WIDTH = 4
)(
    input  wire                     wr_clk,
    input  wire                     rst_n,
    input  wire                     wr_en,

    input  wire [ADDR_WIDTH:0]      rd_ptr_gray,     // async, from read domain

    output wire [ADDR_WIDTH-1:0]    wr_addr,
    output reg  [ADDR_WIDTH:0]      wr_ptr_gray,
    output reg                      full
);
    // Binary write pointer (extra MSB for wrap)
    reg  [ADDR_WIDTH:0] wr_ptr_bin;
    wire [ADDR_WIDTH:0] wr_ptr_bin_next;
    wire [ADDR_WIDTH:0] wr_ptr_gray_next;

    assign wr_ptr_bin_next  = wr_ptr_bin + (wr_en && !full);
    assign wr_addr           = wr_ptr_bin[ADDR_WIDTH-1:0];

    // Gray-code conversion of the next binary pointer (combinational,
    bin2gray #(
        .WIDTH (ADDR_WIDTH+1)
    ) u_bin2gray_wr (
        .bin  (wr_ptr_bin_next),
        .gray (wr_ptr_gray_next)
    );
    // Synchronize read pointer (Gray) into wr_clk domain
    wire [ADDR_WIDTH:0] rd_ptr_gray_sync;

    sync_2ff #(
        .WIDTH (ADDR_WIDTH+1)
    ) u_sync_rd_ptr (
        .clk      (wr_clk),
        .rst_n    (rst_n),
        .async_in (rd_ptr_gray),
        .sync_out (rd_ptr_gray_sync)
    );
    // Register binary and Gray write pointers
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            wr_ptr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;
        end
    end
    // Full flag
    // FIFO is full when the next write pointer (Gray) equals the
    // synchronized read pointer with its MSBs inverted.
    // in empty pointers match exactly
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin
            full <= 1'b0;
        end else begin
            full <= (wr_ptr_gray_next == {~rd_ptr_gray_sync[ADDR_WIDTH:ADDR_WIDTH-1],
                                            rd_ptr_gray_sync[ADDR_WIDTH-2:0]});
        end
    end

endmodule