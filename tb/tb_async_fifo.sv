`timescale 1ns/1ps

module tb_async_fifo;
    // Parameters
    localparam DATA_WIDTH = 8;
    localparam FIFO_DEPTH = 16;
    localparam ADDR_WIDTH = $clog2(FIFO_DEPTH);

    // DUT signals
    reg                     wr_clk;
    reg                     rd_clk;
    reg                     rst_n;
    reg                     wr_en;
    reg  [DATA_WIDTH-1:0]   wr_data;
    wire                    full;
    reg                     rd_en;
    wire [DATA_WIDTH-1:0]   rd_data;
    wire                    empty;

    integer wr_count;
    integer rd_count;
    integer error_count;

    // Reference model queue
    reg [DATA_WIDTH-1:0] ref_queue [$];

    // DUT instantiation
    async_fifo #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_DEPTH (FIFO_DEPTH)
    ) dut (
        .wr_clk   (wr_clk),
        .rst_n    (rst_n),
        .wr_en    (wr_en),
        .wr_data  (wr_data),
        .full     (full),
        .rd_clk   (rd_clk),
        .rd_en    (rd_en),
        .rd_data  (rd_data),
        .empty    (empty)
    );

    // Independent clock generation for read and write
    initial wr_clk = 0;
    always #5  wr_clk = ~wr_clk;   // 100 MHz write clock (10ns period)

    initial rd_clk = 0;
    always #7  rd_clk = ~rd_clk;   // ~71 MHz read clock (14ns period)

    // Reset
    initial begin
        rst_n   = 1'b0;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = {DATA_WIDTH{1'b0}};
        wr_count    = 0;
        rd_count    = 0;
        error_count = 0;
        repeat (5) @(posedge wr_clk);
        rst_n = 1'b1;
    end

    // Write driver: pushes data whenever not full, with randomized gaps
    task automatic do_write(input [DATA_WIDTH-1:0] data);
        begin
            @(posedge wr_clk);
            while (full) @(posedge wr_clk);
            wr_en   <= 1'b1;
            wr_data <= data;
            @(posedge wr_clk);
            wr_en   <= 1'b0;
            ref_queue.push_back(data);
            wr_count = wr_count + 1;
        end
    endtask

    // Read driver: pops data whenever not empty, checks against reference
    task automatic do_read;
        reg [DATA_WIDTH-1:0] expected;
        begin
            @(posedge rd_clk);
            while (empty) @(posedge rd_clk);
            rd_en <= 1'b1;
            @(posedge rd_clk);
            rd_en <= 1'b0;
            expected = ref_queue.pop_front();
            if (rd_data !== expected) begin
                $error("MISMATCH: expected=%0h got=%0h at time=%0t",
                        expected, rd_data, $time);
                error_count = error_count + 1;
            end
            rd_count = rd_count + 1;
        end
    endtask

    // Test sequence
    integer i;
    integer j_wr, j_rd;
    reg [DATA_WIDTH-1:0] rand_data;

    initial begin
        $dumpfile("tb_async_fifo.vcd");
        $dumpvars(0, tb_async_fifo);

        wait (rst_n == 1'b1);
        @(posedge wr_clk);

        // ---- Test 1: Fill FIFO completely, check 'full' asserts ----
        $display("[TEST 1] Filling FIFO to full...");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            rand_data = $random;
            do_write(rand_data);
        end
        @(posedge wr_clk);
        if (!full) begin
            $error("[TEST 1] FAIL: 'full' not asserted after filling FIFO");
            error_count = error_count + 1;
        end else begin
            $display("[TEST 1] PASS: full flag correctly asserted");
        end

        // ---- Test 2: Drain FIFO completely, check 'empty' asserts ----
        $display("[TEST 2] Draining FIFO to empty...");
        for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
            do_read();
        end
        @(posedge rd_clk);
        if (!empty) begin
            $error("[TEST 2] FAIL: 'empty' not asserted after draining FIFO");
            error_count = error_count + 1;
        end else begin
            $display("[TEST 2] PASS: empty flag correctly asserted");
        end

        // ---- Test 3: Concurrent random read/write stress ----
        $display("[TEST 3] Concurrent randomized read/write stress...");
        fork
            begin : write_stress
                for (j_wr = 0; j_wr < 200; j_wr = j_wr + 1) begin
                    rand_data = $random;
                    do_write(rand_data);
                end
            end
            begin : read_stress
                for (j_rd = 0; j_rd < 200; j_rd = j_rd + 1) begin
                    do_read();
                end
            end
        join

        // ---- Final report ----
        #1000
        $display("=======================================================");
        $display(" TB SUMMARY: writes=%0d reads=%0d errors=%0d",
                    wr_count, rd_count, error_count);
        if (error_count == 0)
            $display(" RESULT: ALL TESTS PASSED");
        else
            $display(" RESULT: %0d MISMATCH(ES) DETECTED", error_count);
        $display("=======================================================");
        $finish;
    end

endmodule
