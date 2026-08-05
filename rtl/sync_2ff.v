`timescale 1ns/1ps

module sync_2ff #(
    parameter WIDTH = 4
)(
    input  wire             clk,       // Destination domain clock
    input  wire             rst_n,     // Active-low
    input  wire [WIDTH-1:0] async_in,  // Asynchronous input from other clock domain
    output reg  [WIDTH-1:0] sync_out   // Synchronized output in clk domain
);
    // Two-stage synchronizer flip-flop chain.
    // sync_ff1 may briefly go metastable when sampling async_in.
    // sync_ff2 samples sync_ff1 one cycle later, by which time it has
    // had a full clock period to resolve to a stable 0 or 1.
    reg [WIDTH-1:0] sync_ff1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_ff1 <= {WIDTH{1'b0}};
            sync_out <= {WIDTH{1'b0}};
        end else begin
            sync_ff1 <= async_in;
            sync_out <= sync_ff1;
        end
    end

endmodule