`timescale 1ns/1ps

module gray_pointer_stb;

    parameter WIDTH = 4;

    reg                  rd_clk;
    reg                  wr_clk;
    reg                  reset_n;

    wire [WIDTH-1:0]     bin_ptr;
    wire [WIDTH-1:0]     syn_bptr;

    integer pass_count;
    integer fail_count;

    /*
     * Reference model
     *
     * internal_bin represents the DUT's bin_ptr_i.
     */
    reg [WIDTH-1:0] expected_internal_bin;

    /*
     * The DUT's bin_ptr output is assigned from the OLD
     * bin_ptr_i inside the clocked process.
     */
    reg [WIDTH-1:0] expected_bin_ptr;

    /*
     * Reference model of the two synchronizer stages.
     *
     * At every read-clock edge:
     *
     *     stage1 = current Gray pointer
     *     stage2 = old stage1
     */
    reg [WIDTH-1:0] expected_gray_stage1;
    reg [WIDTH-1:0] expected_gray_stage2;

    reg [WIDTH-1:0] expected_gray;


    /*
     * ============================================================
     * DUT
     * ============================================================
     */

    gray_pointer_sync #(
        .width(WIDTH)
    ) dut (
        .rd_clk  (rd_clk),
        .wr_clk  (wr_clk),
        .reset_n (reset_n),
        .bin_ptr (bin_ptr),
        .syn_bptr(syn_bptr)
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
     * 10 ns and 13 ns are intentionally different so that
     * the clock edges do not repeatedly coincide.
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
     *
     * Gray = Binary XOR (Binary >> 1)
     * ============================================================
     */

    function [WIDTH-1:0] bin_to_gray;

        input [WIDTH-1:0] binary_value;

        begin
            bin_to_gray = binary_value ^
                          (binary_value >> 1);
        end

    endfunction


    /*
     * ============================================================
     * GRAY TO BINARY
     *
     * This function works for arbitrary WIDTH.
     * ============================================================
     */

    function [WIDTH-1:0] gray_to_bin;

        input [WIDTH-1:0] gray_value;

        integer j;

        begin

            gray_to_bin[WIDTH-1] = gray_value[WIDTH-1];

            for (j = WIDTH-2; j >= 0; j = j - 1) begin
                gray_to_bin[j] =
                    gray_to_bin[j+1] ^ gray_value[j];
            end

        end

    endfunction


    /*
     * ============================================================
     * WRITE-CLOCK REFERENCE MODEL
     * ============================================================
     */

    always @(posedge wr_clk) begin

        if (reset_n == 1'b0) begin

            expected_internal_bin = {WIDTH{1'b0}};
            expected_bin_ptr      = {WIDTH{1'b0}};

        end
        else begin

            /*
             * DUT does:
             *
             * bin_ptr_i <= bin_ptr_i + 1;
             * bin_ptr   <= bin_ptr_i;
             *
             * Therefore bin_ptr receives the OLD value.
             */

            expected_bin_ptr = expected_internal_bin;

            expected_internal_bin =
                expected_internal_bin + 1'b1;

        end

    end


    /*
     * ============================================================
     * READ-CLOCK REFERENCE MODEL
     * ============================================================
     */

    always @(posedge rd_clk) begin

        if (reset_n == 1'b0) begin

            expected_gray_stage1 = {WIDTH{1'b0}};
            expected_gray_stage2 = {WIDTH{1'b0}};

        end
        else begin

            /*
             * The Gray pointer is generated from the current
             * binary pointer in the write clock domain.
             */
            expected_gray =
                bin_to_gray(expected_internal_bin);

            /*
             * Model the two synchronizer stages.
             */
            expected_gray_stage2 =
                expected_gray_stage1;

            expected_gray_stage1 =
                expected_gray;

        end

    end


    /*
     * ============================================================
     * MAIN TEST
     * ============================================================
     */

    integer i;

    initial begin

        pass_count = 0;
        fail_count = 0;

        reset_n = 1'b0;

        expected_internal_bin = {WIDTH{1'b0}};
        expected_bin_ptr      = {WIDTH{1'b0}};
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

        /*
         * Assert reset.
         */
        #2;

        check(bin_ptr == 0,
              "bin_ptr is zero during reset");

        check(syn_bptr == 0,
              "syn_bptr is zero during reset");


        /*
         * Keep reset active across clock edges.
         */
        #10;

        check(bin_ptr == 0,
              "bin_ptr remains zero while reset is active");

        check(syn_bptr == 0,
              "syn_bptr remains zero while reset is active");


        /*
         * Release reset away from clock edge.
         */
        #3;

        reset_n = 1'b1;

        $display("");
        $display("---- RESET RELEASED ----");
        $display("");


        /*
         * ========================================================
         * TEST 2 : BINARY POINTER
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 2 : BINARY POINTER COUNTING");
        $display("==============================================");


        /*
         * First write-clock edge after reset.
         *
         * expected_internal_bin starts at 0.
         *
         * DUT:
         *     bin_ptr_i <= 1
         *     bin_ptr   <= 0
         *
         * Therefore bin_ptr = 0.
         */
        @(posedge wr_clk);
        #1;

        check(bin_ptr == expected_bin_ptr,
              "bin_ptr first value is correct");


        /*
         * More write-clock edges.
         */
        for (i = 0; i < 10; i = i + 1) begin

            @(posedge wr_clk);
            #1;

            check(bin_ptr == expected_bin_ptr,
                  "bin_ptr matches reference model");

        end


        /*
         * ========================================================
         * TEST 3 : BINARY POINTER WRAP
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 3 : BINARY POINTER WRAP");
        $display("==============================================");


        /*
         * WIDTH = 4, so binary pointer has values:
         *
         * 0 ... 15
         *
         * then wraps to 0.
         */

        for (i = 0; i < 20; i = i + 1) begin

            @(posedge wr_clk);
            #1;

            check(bin_ptr == expected_bin_ptr,
                  "binary pointer continues through wrap");

        end


        /*
         * ========================================================
         * TEST 4 : CDC SYNCHRONIZATION
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 4 : TWO-FLOP CDC SYNCHRONIZATION");
        $display("==============================================");


        /*
         * Let the write pointer move several times.
         */
        repeat (5)
            @(posedge wr_clk);

        #1;


        /*
         * Allow the read clock to capture the Gray pointer.
         *
         * The synchronized output should follow after the
         * two synchronizer stages.
         */

        repeat (10) begin

            @(posedge rd_clk);
            #1;

            check(syn_bptr ==
                  gray_to_bin(expected_gray_stage2),
                  "synchronized pointer matches reference model");

        end


        /*
         * ========================================================
         * TEST 5 : CONTINUOUS POINTER MOVEMENT
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 5 : CONTINUOUS POINTER MOVEMENT");
        $display("==============================================");


        /*
         * Run both clocks and check synchronization continuously.
         */
        for (i = 0; i < 40; i = i + 1) begin

            @(posedge rd_clk);
            #1;

            check(syn_bptr ==
                  gray_to_bin(expected_gray_stage2),
                  "CDC output follows Gray pointer safely");

        end


        /*
         * ========================================================
         * TEST 6 : ASYNCHRONOUS RESET DURING OPERATION
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 6 : RESET DURING OPERATION");
        $display("==============================================");


        /*
         * Let pointer move first.
         */
        repeat (4)
            @(posedge wr_clk);

        #2;

        /*
         * Assert reset between clock edges.
         */
        reset_n = 1'b0;

        #1;

        check(bin_ptr == 0,
              "bin_ptr clears immediately during asynchronous reset");

        check(syn_bptr == 0,
              "syn_bptr clears immediately during asynchronous reset");


        /*
         * Release reset.
         */
        #4;

        reset_n = 1'b1;


        /*
         * ========================================================
         * TEST 7 : POINTER AFTER RESET
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 7 : POINTER RESTART AFTER RESET");
        $display("==============================================");


        @(posedge wr_clk);
        #1;

   

        check(bin_ptr == 0,
              "binary pointer restarts from zero");

        @(posedge wr_clk);
        #1;

        check(bin_ptr == 1,
              "binary pointer increments correctly after reset");

        $display("DEBUG 1");

        #1;
        $display("DEBUG 2");

        #1;
        $display("DEBUG 3");

        $display("FINAL TEST RESULT STARTING");

        $display("Total PASS checks : %0d", pass_count);
        $display("Total FAIL checks : %0d", fail_count);

        if (fail_count == 0) begin
            $display("SYSTEM TEST PASSED");
            $display("RESULT : PASS");
        end
        else begin
            $display("SYSTEM TEST FAILED");
            $display("RESULT : FAIL");
        end

        $finish;
            /*
            
     * ============================================================
     * FINAL TEST RESULT
     * ============================================================
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