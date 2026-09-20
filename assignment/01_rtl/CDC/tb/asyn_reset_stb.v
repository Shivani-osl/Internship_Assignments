`timescale 1ns/1ps

module asyn_reset_stb;

    parameter DEASSERT_DELAY = 4;

    reg clk;
    reg reset_n;

    wire local_reset_n;
    wire reset_active;
    wire reset_done;

    integer pass_count;
    integer fail_count;
    integer i;

    // ------------------------------------------------------------
    // DUT
    // ------------------------------------------------------------
    reset_architecture #(
        .DEASSERT_DELAY(DEASSERT_DELAY)
    ) dut (
        .clk           (clk),
        .reset_n       (reset_n),
        .local_reset_n (local_reset_n),
        .reset_active  (reset_active),
        .reset_done    (reset_done)
    );

    // ------------------------------------------------------------
    // 10 ns clock
    // ------------------------------------------------------------
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ------------------------------------------------------------
    // Self-checking task
    // ------------------------------------------------------------
    task check;
        input expected_local_reset_n;
        input expected_reset_active;
        input expected_reset_done;
        input [255:0] name;

        begin
            #1;

            if ((local_reset_n === expected_local_reset_n) &&
                (reset_active  === expected_reset_active)  &&
                (reset_done    === expected_reset_done)) begin

                $display("[PASS] %s", name);
                pass_count = pass_count + 1;

            end
            else begin

                $display("[FAIL] %s | Expected: LRST=%b ACTIVE=%b DONE=%b | Got: LRST=%b ACTIVE=%b DONE=%b",
                         name,
                         expected_local_reset_n,
                         expected_reset_active,
                         expected_reset_done,
                         local_reset_n,
                         reset_active,
                         reset_done);

                fail_count = fail_count + 1;
            end
        end
    endtask

    // ------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------
    initial begin

        pass_count = 0;
        fail_count = 0;

        $display("");
        $display("==============================================");
        $display(" RESET ARCHITECTURE SELF-CHECKING TESTBENCH");
        $display(" DEASSERT_DELAY = %0d", DEASSERT_DELAY);
        $display("==============================================");
        $display("");

        // ========================================================
        // TEST 1: Asynchronous assertion
        // ========================================================

        reset_n = 1'b1;

        // Assert reset away from clock edge
        #2;
        reset_n = 1'b0;

        #1;

        check(
            1'b0,
            1'b1,
            1'b0,
            "Asynchronous reset assertion"
        );

        // ========================================================
        // TEST 2: Synchronous delayed deassertion
        // ========================================================

        // Release reset away from clock edge
        @(negedge clk);
        reset_n = 1'b1;

        // Immediately after release, local reset must remain active
        #1;

        check(
            1'b0,
            1'b1,
            1'b0,
            "Reset remains active immediately after release"
        );

        // First DEASSERT_DELAY clock edges
        for (i = 1; i <= DEASSERT_DELAY; i = i + 1) begin

            @(posedge clk);

            check(
                1'b0,
                1'b1,
                1'b0,
                "Deassertion delay cycle"
            );

        end

        // One additional edge releases reset
        @(posedge clk);

        check(
            1'b1,
            1'b0,
            1'b1,
            "Reset released after delay"
        );

        // ========================================================
        // TEST 3: Reset remains released
        // ========================================================

        @(posedge clk);

        check(
            1'b1,
            1'b0,
            1'b1,
            "Reset remains released"
        );

        // ========================================================
        // TEST 4: Asynchronous reset during operation
        // ========================================================

        @(negedge clk);
        reset_n = 1'b0;

        #1;

        check(
            1'b0,
            1'b1,
            1'b0,
            "Reset asserted during normal operation"
        );

        // ========================================================
        // TEST 5: Release and interrupt the delay
        // ========================================================

        @(negedge clk);
        reset_n = 1'b1;

        // First delay edge
        @(posedge clk);

        check(
            1'b0,
            1'b1,
            1'b0,
            "Interrupted release - cycle 1"
        );

        // Second delay edge
        @(posedge clk);

        check(
            1'b0,
            1'b1,
            1'b0,
            "Interrupted release - cycle 2"
        );

        // Assert reset again BEFORE release completes
        @(negedge clk);
        reset_n = 1'b0;

        #1;

        check(
            1'b0,
            1'b1,
            1'b0,
            "Reset reasserted during deassertion delay"
        );

        // ========================================================
        // TEST 6: Verify delay restarted from zero
        // ========================================================

        @(negedge clk);
        reset_n = 1'b1;

        #1;

        check(
            1'b0,
            1'b1,
            1'b0,
            "New release starts with reset active"
        );

        // Complete a fresh delay
        for (i = 1; i <= DEASSERT_DELAY; i = i + 1) begin

            @(posedge clk);

            check(
                1'b0,
                1'b1,
                1'b0,
                "Fresh deassertion delay cycle"
            );

        end

        // Release
        @(posedge clk);

        check(
            1'b1,
            1'b0,
            1'b1,
            "Fresh reset release completed"
        );

        // ========================================================
        // TEST 7: Output relationships
        // ========================================================

        if (local_reset_n === reset_done) begin
            $display("[PASS] local_reset_n equals reset_done");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] local_reset_n does not equal reset_done");
            fail_count = fail_count + 1;
        end

        if (reset_active === ~reset_done) begin
            $display("[PASS] reset_active is inverse of reset_done");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] reset_active is not inverse of reset_done");
            fail_count = fail_count + 1;
        end

        // ========================================================
        // Final result
        // ========================================================

        $display("");
        $display("==============================================");
        $display(" TEST SUMMARY");
        $display(" PASS COUNT : %0d", pass_count);
        $display(" FAIL COUNT : %0d", fail_count);
        $display("==============================================");

        if (fail_count == 0)
            $display("RESULT : PASS");
        else
            $display("RESULT : FAIL");

        $display("");

        $finish;
    end

endmodule