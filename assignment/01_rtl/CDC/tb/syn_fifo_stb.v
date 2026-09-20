`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 15.09.2026 01:18:16
// Design Name: 
// Module Name: syn_fifo_stb
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


module syn_fifo_stb;


    parameter WIDTH = 8;
    parameter DEPTH = 8;
    parameter THRESHOLD = 2;

    reg                  clk;
    reg                  reset_n;
    reg                  Wr_en;
    reg                  Rd_en;
    reg  [WIDTH-1:0]     data_in;

    wire [WIDTH-1:0]     data_out;
    wire                 Full;
    wire                 Empty;
    wire                 almost_full;
    wire                 almost_emp;
    wire [3:0]           occupancy_count;

    integer pass_count;
    integer fail_count;

    /*
     * ------------------------------------------------------------
     * DUT
     * ------------------------------------------------------------
     */
    syn_fifo dut (
        .Wr_en(Wr_en),
        .Rd_en(Rd_en),
        .clk(clk),
        .reset_n(reset_n),
        .Full(Full),
        .Empty(Empty),
        .almost_full(almost_full),
        .almost_emp(almost_emp),
        .data_out(data_out),
        .data_in(data_in),
        .occupancy_count(occupancy_count)
    );


    /*
     * ------------------------------------------------------------
     * Reference FIFO model
     * ------------------------------------------------------------
     */
    reg [WIDTH-1:0] model_mem [0:DEPTH-1];

    integer model_wr_ptr;
    integer model_rd_ptr;
    integer model_count;

    reg [WIDTH-1:0] expected_data;


    /*
     * ------------------------------------------------------------
     * Clock
     * ------------------------------------------------------------
     */
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    /*
     * ------------------------------------------------------------
     * PASS / FAIL check task
     * ------------------------------------------------------------
     */
    task check;
        input condition;
        input [8*100-1:0] message;

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
     * ------------------------------------------------------------
     * Reset task
     * ------------------------------------------------------------
     */
    task do_reset;

        begin
            @(negedge clk);

            reset_n = 1'b0;
            Wr_en   = 1'b0;
            Rd_en   = 1'b0;
            data_in = {WIDTH{1'b0}};

            /*
             * DUT reset is synchronous, so keep reset low
             * across at least one rising clock edge.
             */
            @(posedge clk);
            #1;

            /*
             * Reset reference model
             */
            model_wr_ptr = 0;
            model_rd_ptr = 0;
            model_count  = 0;

            check(occupancy_count == 0,
                  "occupancy is zero after reset");

            check(Empty == 1'b1,
                  "Empty asserted after reset");

            check(Full == 1'b0,
                  "Full deasserted after reset");

            check(almost_emp == 1'b1,
                  "almost_empty asserted after reset");

            check(almost_full == 1'b0,
                  "almost_full deasserted after reset");

            @(negedge clk);
            reset_n = 1'b1;

            Wr_en   = 1'b0;
            Rd_en   = 1'b0;

            $display("");
            $display("---- RESET RELEASED ----");
            $display("");
        end

    endtask


    /*
     * ------------------------------------------------------------
     * One FIFO transaction
     *
     * The reference model determines whether the read/write
     * operation is actually accepted.
     * ------------------------------------------------------------
     */
    task fifo_cycle;

        input wr;
        input rd;
        input [WIDTH-1:0] din;

        reg write_accept_model;
        reg read_accept_model;
        reg [WIDTH-1:0] expected_read;

        begin

            /*
             * ----------------------------------------------------
             * Determine accepted operations BEFORE clock edge.
             * This exactly matches the DUT equations.
             * ----------------------------------------------------
             */

            write_accept_model =
                wr && ((!Full) || (rd && (!Empty)));

            read_accept_model =
                rd && (!Empty);


            /*
             * Save old FIFO data for a read.
             *
             * This is important for simultaneous read/write.
             * The read must obtain the old memory value.
             */
            if (read_accept_model) begin
                expected_read = model_mem[model_rd_ptr];
            end


            /*
             * Apply inputs away from rising edge.
             */
            @(negedge clk);

            Wr_en   = wr;
            Rd_en   = rd;
            data_in = din;


            /*
             * Execute DUT operation.
             */
            @(posedge clk);

            #1;


            /*
             * ----------------------------------------------------
             * Update reference model
             * ----------------------------------------------------
             */

            if (write_accept_model) begin

                model_mem[model_wr_ptr] = din;

                if (model_wr_ptr == DEPTH-1)
                    model_wr_ptr = 0;
                else
                    model_wr_ptr = model_wr_ptr + 1;

            end


            if (read_accept_model) begin

                model_rd_ptr = model_rd_ptr + 1;

                if (model_rd_ptr == DEPTH)
                    model_rd_ptr = 0;

            end


            /*
             * Update occupancy model.
             */
            if (write_accept_model && !read_accept_model)
                model_count = model_count + 1;

            else if (read_accept_model && !write_accept_model)
                model_count = model_count - 1;


            /*
             * ----------------------------------------------------
             * Check occupancy
             * ----------------------------------------------------
             */
            check(occupancy_count == model_count,
                  "occupancy count matches reference model");


            /*
             * ----------------------------------------------------
             * Check Full / Empty
             * ----------------------------------------------------
             */
            check(Full == (model_count == DEPTH),
                  "Full flag matches occupancy");

            check(Empty == (model_count == 0),
                  "Empty flag matches occupancy");


            /*
             * ----------------------------------------------------
             * Check almost-empty
             *
             * DUT:
             *     almost_empty = 1 when count <= THRESHOLD
             * ----------------------------------------------------
             */
            check(almost_emp == (model_count <= THRESHOLD),
                  "almost_empty flag matches occupancy");


            /*
             * ----------------------------------------------------
             * Check almost-full
             *
             * DUT:
             *     almost_full = 1 when count >= DEPTH-THRESHOLD
             * ----------------------------------------------------
             */
            check(almost_full ==
                  (model_count >= (DEPTH-THRESHOLD)),
                  "almost_full flag matches occupancy");


            /*
             * ----------------------------------------------------
             * Check read data only when a read was accepted.
             * ----------------------------------------------------
             */
            if (read_accept_model) begin

                check(data_out == expected_read,
                      "read data matches reference FIFO");

            end


            /*
             * Disable enables after checking.
             */
            Wr_en = 1'b0;
            Rd_en = 1'b0;

        end

    endtask


    /*
     * ------------------------------------------------------------
     * Main test
     * ------------------------------------------------------------
     */
    integer i;
    reg random_wr;
    reg random_rd;
    reg [WIDTH-1:0] random_data;

    initial begin

        pass_count = 0;
        fail_count = 0;

        reset_n = 1'b0;
        Wr_en   = 1'b0;
        Rd_en   = 1'b0;
        data_in = 0;

        model_wr_ptr = 0;
        model_rd_ptr = 0;
        model_count  = 0;


        /*
         * ========================================================
         * TEST 1 : RESET
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 1 : RESET");
        $display("==============================================");

        do_reset;


        /*
         * ========================================================
         * TEST 2 : READ FROM EMPTY FIFO
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 2 : READ FROM EMPTY FIFO");
        $display("==============================================");

        fifo_cycle(1'b0, 1'b1, 8'hAA);


        /*
         * ========================================================
         * TEST 3 : SINGLE WRITE
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 3 : SINGLE WRITE");
        $display("==============================================");

        fifo_cycle(1'b1, 1'b0, 8'h11);


        /*
         * ========================================================
         * TEST 4 : SINGLE READ
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 4 : SINGLE READ");
        $display("==============================================");

        fifo_cycle(1'b0, 1'b1, 8'h00);


        /*
         * ========================================================
         * TEST 5 : FILL FIFO
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 5 : FILL FIFO");
        $display("==============================================");

        for (i = 0; i < DEPTH; i = i + 1) begin
            fifo_cycle(1'b1, 1'b0, i);
        end


        /*
         * ========================================================
         * TEST 6 : FIFO FULL
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 6 : FULL CONDITION");
        $display("==============================================");

        check(Full == 1'b1,
              "FIFO is full");

        check(Empty == 1'b0,
              "FIFO is not empty when full");

        check(occupancy_count == DEPTH,
              "occupancy equals FIFO depth");


        /*
         * Try writing while full.
         * Write must be rejected.
         */
        fifo_cycle(1'b1, 1'b0, 8'hFF);


        /*
         * ========================================================
         * TEST 7 : FULL + SIMULTANEOUS READ/WRITE
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 7 : FULL + SIMULTANEOUS READ/WRITE");
        $display("==============================================");

        fifo_cycle(1'b1, 1'b1, 8'hA5);

        check(model_count == DEPTH,
              "FIFO remains full after simultaneous R/W at full");

        check(Full == 1'b1,
              "Full remains asserted after simultaneous R/W at full");


        /*
         * ========================================================
         * TEST 8 : DRAIN FIFO
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 8 : DRAIN FIFO");
        $display("==============================================");

        while (model_count > 0) begin
            fifo_cycle(1'b0, 1'b1, 8'h00);
        end


        /*
         * ========================================================
         * TEST 9 : EMPTY + SIMULTANEOUS READ/WRITE
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 9 : EMPTY + SIMULTANEOUS READ/WRITE");
        $display("==============================================");

        fifo_cycle(1'b1, 1'b1, 8'h55);

        check(model_count == 1,
              "Empty simultaneous R/W results in one stored word");

        check(Empty == 1'b0,
              "FIFO is no longer empty after write at empty");


        /*
         * Read the word written above.
         */
        fifo_cycle(1'b0, 1'b1, 8'h00);


        /*
         * ========================================================
         * TEST 10 : ALMOST EMPTY THRESHOLD
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 10 : ALMOST EMPTY THRESHOLD");
        $display("==============================================");

        /*
         * Fill to THRESHOLD entries.
         */
        for (i = 0; i < THRESHOLD; i = i + 1) begin
            fifo_cycle(1'b1, 1'b0, 8'h30 + i);
        end

        check(almost_emp == 1'b1,
              "almost_empty asserted at threshold");

        /*
         * One more entry should clear almost_empty.
         */
        fifo_cycle(1'b1, 1'b0, 8'h40);

        check(almost_emp == 1'b0,
              "almost_empty deasserted above threshold");


        /*
         * ========================================================
         * TEST 11 : ALMOST FULL THRESHOLD
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 11 : ALMOST FULL THRESHOLD");
        $display("==============================================");

        while (model_count < (DEPTH-THRESHOLD)) begin
            fifo_cycle(1'b1, 1'b0, 8'h50 + model_count);
        end

        check(almost_full == 1'b1,
              "almost_full asserted at threshold");


        /*
         * ========================================================
         * TEST 12 : POINTER WRAP
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 12 : POINTER WRAP");
        $display("==============================================");

        /*
         * Complete fill and drain sequence causes both
         * pointers to wrap around.
         */
        while (model_count < DEPTH) begin
            fifo_cycle(1'b1, 1'b0, 8'h60 + model_count);
        end

        while (model_count > 0) begin
            fifo_cycle(1'b0, 1'b1, 8'h00);
        end

        check(model_count == 0,
              "FIFO returns to empty after pointer wrap test");

        check(Empty == 1'b1,
              "Empty asserted after pointer wrap test");


        /*
         * ========================================================
         * TEST 13 : RESET DURING OPERATION
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 13 : RESET DURING OPERATION");
        $display("==============================================");

        fifo_cycle(1'b1, 1'b0, 8'h71);
        fifo_cycle(1'b1, 1'b0, 8'h72);
        fifo_cycle(1'b1, 1'b0, 8'h73);

        /*
         * Assert reset while FIFO contains data.
         */
        do_reset;

        check(model_count == 0,
              "reference FIFO cleared by reset");

        check(Empty == 1'b1,
              "FIFO becomes empty after mid-operation reset");


        /*
         * ========================================================
         * TEST 14 : RANDOM TRAFFIC
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("TEST 14 : RANDOM TRAFFIC");
        $display("==============================================");

        for (i = 0; i < 100; i = i + 1) begin

            random_wr   = $random;
            random_rd   = $random;
            random_data = $random;

            fifo_cycle(random_wr, random_rd, random_data);

        end


        /*
         * ========================================================
         * FINAL RESULT
         * ========================================================
         */
        $display("");
        $display("==============================================");
        $display("FIFO TEST SUMMARY");
        $display("==============================================");

        $display("PASS COUNT : %0d", pass_count);
        $display("FAIL COUNT : %0d", fail_count);

        if (fail_count == 0) begin
            $display("");
            $display("RESULT : PASS");
            $display("");
        end
        else begin
            $display("");
            $display("RESULT : FAIL");
            $display("");
        end

        $finish;

    end

endmodule
