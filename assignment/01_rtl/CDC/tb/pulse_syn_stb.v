`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.09.2026 12:24:53
// Design Name: 
// Module Name: pulse_syn_stb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns/1ps

module Pulse_Syn_stb;

    reg clk_tx;
    reg clk_rx;
    reg Pin;
    reg reset_n;

    wire Pout;

    integer pass_count;
    integer fail_count;

    Pulse_Syn dut (
        .clk_tx  (clk_tx),
        .clk_rx  (clk_rx),
        .Pin     (Pin),
        .reset_n (reset_n),
        .Pout    (Pout)
    );

    // ------------------------------------------------------------
    // TX clock
    // 10 ns period
    // ------------------------------------------------------------
    initial begin
        clk_tx = 1'b0;
        forever #5 clk_tx = ~clk_tx;
    end

    // ------------------------------------------------------------
    // RX clock
    // 14 ns period
    //
    // Deliberately different from TX clock to exercise CDC.
    // ------------------------------------------------------------
    initial begin
        clk_rx = 1'b0;
        forever #7 clk_rx = ~clk_rx;
    end

    // ------------------------------------------------------------
    // Main test
    // ------------------------------------------------------------
    initial begin

        pass_count = 0;
        fail_count = 0;

        Pin     = 1'b0;
        reset_n = 1'b0;

        $display("");
        $display("==============================================");
        $display(" TEST: PULSE SYNCHRONIZER");
        $display("==============================================");

        // --------------------------------------------------------
        // TEST 1: Asynchronous reset
        // --------------------------------------------------------
        #2;

        if (Pout === 1'b0) begin
            $display("[PASS] Asynchronous reset drives Pout LOW");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Asynchronous reset drives Pout LOW");
            $display("       Expected = 0, Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 2: Keep reset asserted through clock activity
        // --------------------------------------------------------
        #30;

        if (Pout === 1'b0) begin
            $display("[PASS] Pout remains LOW while reset is asserted");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout changed while reset was asserted");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------
        reset_n = 1'b1;

        #3;

        if (Pout === 1'b0) begin
            $display("[PASS] Pout remains LOW after reset release");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout is not LOW after reset release");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 3: Generate first TX pulse
        //
        // Pin is asserted away from a clock edge.
        // Keep it HIGH for one TX clock cycle.
        // --------------------------------------------------------
        #3;

        Pin = 1'b1;

        $display("");
        $display("Generating pulse 1");

        @(posedge clk_tx);
        #2;

        Pin = 1'b0;

        // Wait for the pulse to cross into RX domain.
        #40;

        // At this point the pulse should have occurred.
        // Pout should normally be LOW again.
        if (Pout === 1'b0) begin
            $display("[PASS] First pulse completed and Pout returned LOW");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout did not return LOW after first pulse");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 4: Second pulse
        // --------------------------------------------------------
        #4;

        Pin = 1'b1;

        $display("");
        $display("Generating pulse 2");

        @(posedge clk_tx);
        #2;

        Pin = 1'b0;

        #40;

        if (Pout === 1'b0) begin
            $display("[PASS] Second pulse completed and Pout returned LOW");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout did not return LOW after second pulse");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 5: Third pulse
        // --------------------------------------------------------
        #4;

        Pin = 1'b1;

        $display("");
        $display("Generating pulse 3");

        @(posedge clk_tx);
        #2;

        Pin = 1'b0;

        #40;

        if (Pout === 1'b0) begin
            $display("[PASS] Third pulse completed and Pout returned LOW");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout did not return LOW after third pulse");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 6: No input pulse
        //
        // Leave Pin LOW for several clock cycles.
        // Pout must remain LOW.
        // --------------------------------------------------------
        Pin = 1'b0;

        #50;

        if (Pout === 1'b0) begin
            $display("[PASS] Pout remains LOW when no input pulse is present");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout asserted without an input pulse");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST 7: Reset during operation
        // --------------------------------------------------------
        Pin = 1'b1;

        #3;

        reset_n = 1'b0;

        #1;

        if (Pout === 1'b0) begin
            $display("[PASS] Reset during operation clears Pout");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Reset during operation did not clear Pout");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        Pin = 1'b0;

        // --------------------------------------------------------
        // TEST 8: Hold reset
        // --------------------------------------------------------
        #25;

        if (Pout === 1'b0) begin
            $display("[PASS] Pout remains LOW during reset after operation");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout changed while reset remained asserted");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // Release reset
        // --------------------------------------------------------
        reset_n = 1'b1;

        #20;

        if (Pout === 1'b0) begin
            $display("[PASS] Pout remains LOW after reset recovery");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] Pout asserted unexpectedly after reset recovery");
            $display("       Actual = %b", Pout);
            fail_count = fail_count + 1;
        end

        // --------------------------------------------------------
        // TEST SUMMARY
        // --------------------------------------------------------
        $display("");
        $display("==============================================");
        $display(" TEST SUMMARY");
        $display("==============================================");
        $display("TESTS PASSED : %0d", pass_count);
        $display("TESTS FAILED : %0d", fail_count);

        if (fail_count == 0) begin
            $display("RESULT       : PASS");
        end
        else begin
            $display("RESULT       : FAIL");
        end

        $display("==============================================");
        $display("");

        $finish;

    end

endmodule
