`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.09.2026 13:39:18
// Design Name: 
// Module Name: gray_pointer_sync_fifo_stb
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

module gray_pointer_sync_fifo_stb;

    parameter WIDTH = 4;

    reg                 wr_clk;
    reg                 rd_clk;
    reg                 reset_n;

    reg  [WIDTH-1:0]    bin_ptr;
    wire [WIDTH-1:0]    syn_bptr;

    integer pass_count;
    integer fail_count;

    reg [WIDTH-1:0] expected_gray_stage1;
    reg [WIDTH-1:0] expected_gray_stage2;
    reg [WIDTH-1:0] expected_syn_bptr;

    integer i;


    /*
     * ============================================================
     * DUT
     * ============================================================
     */

    gray_pointer_sync_fifo #(
        .width(WIDTH)
    ) dut (
        .wr_clk   (wr_clk),
        .rd_clk   (rd_clk),
        .reset_n  (reset_n),
        .bin_ptr  (bin_ptr),
        .syn_bptr (syn_bptr)
    );


    /*
     * ============================================================
     * WRITE CLOCK
     * 10 ns period
     * ============================================================
     */

    initial begin
        wr_clk = 1'b0;

        forever #5 wr_clk = ~wr_clk;
    end


    /*
     * ============================================================
     * READ CLOCK
     * 13 ns period
     *
     * Different clock periods make this a real asynchronous
     * clock-domain-crossing test.
     * ============================================================
     */

    initial begin
        rd_clk = 1'b0;

        forever #6.5 rd_clk = ~rd_clk;
    end


    /*
     * ============================================================
     * PASS / FAIL CHECK
     * ============================================================
     */

    task check;
        input condition;
        input [8*120-1:0] message;

        begin

            if (condition) begin
                pass_count = pass_count + 1;
                $display("[PASS] %s", message);
            end

            else begin
                fail_count = fail_count + 1;
                $display("[FAIL] %s", message);
            end

        end
    endtask


    /*
     * ============================================================
     * BINARY TO GRAY
     * ============================================================
     */

    function [WIDTH-1:0] bin_to_gray;

        input [WIDTH-1:0] binary_value;

        begin

            bin_to_gray =
                binary_value ^
                (binary_value >> 1);

        end

    endfunction


    /*
     * ============================================================
     * GRAY TO BINARY
     * ============================================================
     */

    function [WIDTH-1:0] gray_to_bin;

        input [WIDTH-1:0] gray_value;

        integer j;

        begin

            gray_to_bin[WIDTH-1] =
                gray_value[WIDTH-1];

            for (j = WIDTH-2; j >= 0; j = j - 1) begin

                gray_to_bin[j] =
                    gray_to_bin[j+1] ^
                    gray_value[j];

            end

        end

    endfunction


    /*
     * ============================================================
     * REFERENCE MODEL
     *
     * This models the two synchronizer stages.
     *
     * stage1 <= current Gray pointer
     * stage2 <= old stage1
     *
     * Therefore DUT output should correspond to stage2.
     * ============================================================
     */

    always @(posedge rd_clk) begin

        if (reset_n == 1'b0) begin

            expected_gray_stage1 = {WIDTH{1'b0}};
            expected_gray_stage2 = {WIDTH{1'b0}};

        end

        else begin

            expected_gray_stage2 =
                expected_gray_stage1;

            expected_gray_stage1 =
                bin_to_gray(bin_ptr);

        end

    end


    /*
     * ============================================================
     * MAIN TEST
     * ============================================================
     */

    initial begin

        pass_count = 0;
        fail_count = 0;

        bin_ptr = {WIDTH{1'b0}};
        reset_n = 1'b0;

        expected_gray_stage1 = {WIDTH{1'b0}};
        expected_gray_stage2 = {WIDTH{1'b0}};


        /*
         * ========================================================
         * TEST 1 : RESET
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 1 : ASYNCHRONOUS RESET");
        $display("==============================================");

        #2;

        check(
            syn_bptr == 0,
            "syn_bptr is zero during reset"
        );


        /*
         * Keep reset active through several read clocks.
         */

        repeat (3)
            @(posedge rd_clk);

        #1;

        check(
            syn_bptr == 0,
            "syn_bptr remains zero while reset is active"
        );


        /*
         * ========================================================
         * TEST 2 : RESET RELEASE
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 2 : RESET RELEASE");
        $display("==============================================");

        reset_n = 1'b1;

        bin_ptr = 0;

        /*
         * First destination clock:
         *
         * stage1 = Gray(0)
         * stage2 = old stage1 = 0
         */

        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 0,
            "synchronized pointer remains zero after first clock"
        );


        /*
         * Second destination clock:
         *
         * stage2 receives stage1.
         */

        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 0,
            "synchronized pointer remains zero after second clock"
        );


        /*
         * ========================================================
         * TEST 3 : POINTER UPDATE
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 3 : POINTER UPDATE");
        $display("==============================================");


        /*
         * Change binary pointer.
         */

        bin_ptr = 4'b0001;

        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 0,
            "new pointer has not yet passed two synchronizer stages"
        );


        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b0001,
            "binary pointer synchronized correctly"
        );


        /*
         * ========================================================
         * TEST 4 : MULTIPLE POINTER VALUES
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 4 : MULTIPLE POINTER VALUES");
        $display("==============================================");


        for (i = 2; i < 10; i = i + 1) begin

            bin_ptr = i;

            /*
             * Wait for two destination-clock edges.
             */

            @(posedge rd_clk);
            #1;

            @(posedge rd_clk);
            #1;

            expected_syn_bptr = i;

            check(
                syn_bptr == expected_syn_bptr,
                "synchronized pointer matches expected value"
            );

        end


        /*
         * ========================================================
         * TEST 5 : POINTER WRAPAROUND
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 5 : POINTER WRAPAROUND");
        $display("==============================================");


        /*
         * WIDTH = 4
         *
         * Binary values:
         *
         * 14 -> 15 -> 0 -> 1 -> ...
         */

        bin_ptr = 4'b1110;

        @(posedge rd_clk);
        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b1110,
            "pointer value 14 synchronized correctly"
        );


        bin_ptr = 4'b1111;

        @(posedge rd_clk);
        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b1111,
            "pointer value 15 synchronized correctly"
        );


        bin_ptr = 4'b0000;

        @(posedge rd_clk);
        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b0000,
            "pointer wrap from 15 to 0 is synchronized"
        );


        bin_ptr = 4'b0001;

        @(posedge rd_clk);
        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b0001,
            "pointer continues correctly after wrap"
        );


        /*
         * ========================================================
         * TEST 6 : CONTINUOUS POINTER MOVEMENT
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 6 : CONTINUOUS POINTER MOVEMENT");
        $display("==============================================");


        /*
         * Change the source pointer every write-clock edge.
         *
         * The destination domain samples it through the
         * two-stage synchronizer.
         */

        for (i = 2; i < 18; i = i + 1) begin

            @(posedge wr_clk);

            bin_ptr = i;

            @(posedge rd_clk);
            #1;

            @(posedge rd_clk);
            #1;

            check(
                syn_bptr == i[WIDTH-1:0],
                "continuous pointer synchronization correct"
            );

        end


        /*
         * ========================================================
         * TEST 7 : RESET DURING OPERATION
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 7 : RESET DURING OPERATION");
        $display("==============================================");


        bin_ptr = 4'b1010;

        repeat (3)
            @(posedge rd_clk);

        #1;

        check(
            syn_bptr == 4'b1010,
            "pointer is active before reset"
        );


        /*
         * Assert reset asynchronously, away from clock edge.
         */

        #2;

        reset_n = 1'b0;

        #1;

        check(
            syn_bptr == 0,
            "synchronized pointer clears immediately during reset"
        );


        /*
         * ========================================================
         * TEST 8 : RECOVERY AFTER RESET
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 8 : RECOVERY AFTER RESET");
        $display("==============================================");


        bin_ptr = 0;

        #4;

        reset_n = 1'b1;


        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 0,
            "pointer remains zero after reset release"
        );


        /*
         * Apply a new pointer.
         */

        bin_ptr = 4'b0101;

        @(posedge rd_clk);
        #1;

        @(posedge rd_clk);
        #1;

        check(
            syn_bptr == 4'b0101,
            "pointer synchronizes correctly after reset recovery"
        );


        /*
         * ========================================================
         * FINAL TEST RESULT
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("FINAL TEST RESULT");
        $display("==============================================");

        $display("Total PASS checks : %0d", pass_count);
        $display("Total FAIL checks : %0d", fail_count);

        if (fail_count == 0) begin

            $display("");
            $display("==============================================");
            $display("SYSTEM TEST PASSED");
            $display("RESULT : PASS");
            $display("==============================================");
            $display("");

        end

        else begin

            $display("");
            $display("==============================================");
            $display("SYSTEM TEST FAILED");
            $display("RESULT : FAIL");
            $display("==============================================");
            $display("");

        end

        $finish;

    end

endmodule

