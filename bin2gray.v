`timescale 1ns/1ps

module bin2gray #(
    parameter WIDTH = 4
)(
    input  wire [WIDTH-1:0] bin,   // Binary input value
    output wire [WIDTH-1:0] gray   // Gray-coded output value
);
    // Each subsequent bit = XOR of current binary bit and next higher bit
    assign gray = bin ^ (bin >> 1);

endmodule