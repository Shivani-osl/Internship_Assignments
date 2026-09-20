`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 19.09.2026 14:30:03
// Design Name: 
// Module Name: fwft_adapter_stb
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

module FWFT_adapter_stb;

    parameter DATA_WIDTH = 8;
    parameter FIFO_DEPTH = 8;

    reg                     rd_clk;
    reg                     reset_n;

    reg                     fifo_empty;
    reg                     receiver_ready;
    reg [DATA_WIDTH-1:0]    fifo_data;

    wire                    fifo_rd_en;
    wire [DATA_WIDTH-1:0]   data_read;
    wire                    empty_o;

    integer pass_count;
    integer fail_count;

    /*
     * ============================================================
     * SIMPLE FIFO MODEL
     * ============================================================
     */

    reg [DATA_WIDTH-1:0] fifo_mem [0:FIFO_DEPTH-1];

    integer fifo_wr_ptr;
    integer fifo_rd_ptr;
    integer fifo_count;

    /*
     * ============================================================
     * DUT
     * ============================================================
     */

    FWFT_adapter #(
        .data_width(DATA_WIDTH)
    ) dut (
        .fifo_empty     (fifo_empty),
        .rd_clk         (rd_clk),
        .reset_n        (reset_n),
        .receiver_ready (receiver_ready),
        .fifo_data      (fifo_data),
        .fifo_rd_en     (fifo_rd_en),
        .data_read      (data_read),
        .empty_o        (empty_o)
    );


    /*
     * ============================================================
     * CLOCK
     * ============================================================
     */

    initial begin
        rd_clk = 1'b0;

        forever #5 rd_clk = ~rd_clk;
    end


    /*
     * ============================================================
     * PASS / FAIL CHECK
     * ============================================================
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
     * ============================================================
     * FIFO MODEL
     *
     * fifo_rd_en is the read request from the adapter.
     *
     * The FIFO returns data after the request.
     * ============================================================
     */

    always @(posedge rd_clk) begin

        if (reset_n == 1'b0) begin

            fifo_count = 0;
            fifo_rd_ptr = 0;

            fifo_data <= 0;

        end

        else begin

            if (fifo_rd_en == 1'b1 && fifo_count > 0) begin

                fifo_data <= fifo_mem[fifo_rd_ptr];

                fifo_rd_ptr = fifo_rd_ptr + 1;

                if (fifo_rd_ptr == FIFO_DEPTH)
                    fifo_rd_ptr = 0;

                fifo_count = fifo_count - 1;

            end

        end

    end


    /*
     * ============================================================
     * UPDATE FIFO EMPTY
     * ============================================================
     */

    always @(*) begin

        if (fifo_count == 0)
            fifo_empty = 1'b1;
        else
            fifo_empty = 1'b0;

    end


    /*
     * ============================================================
     * LOAD TEST DATA INTO FIFO MODEL
     * ============================================================
     */

    task load_fifo;

        input [DATA_WIDTH-1:0] value;

        begin

            fifo_mem[fifo_wr_ptr] = value;

            fifo_wr_ptr = fifo_wr_ptr + 1;

            if (fifo_wr_ptr == FIFO_DEPTH)
                fifo_wr_ptr = 0;

            fifo_count = fifo_count + 1;

        end

    endtask


    /*
     * ============================================================
     * MAIN TEST
     * ============================================================
     */

    integer i;

    initial begin

        pass_count = 0;
        fail_count = 0;

        fifo_wr_ptr = 0;
        fifo_rd_ptr = 0;
        fifo_count  = 0;

        fifo_data = 0;

        reset_n = 1'b0;
        receiver_ready = 1'b0;


        /*
         * ========================================================
         * TEST 1 : RESET
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 1 : RESET");
        $display("==============================================");

        #2;

        check(empty_o == 1'b1,
              "adapter output is empty during reset");

        check(fifo_rd_en == 1'b0,
              "FIFO read request is inactive during reset");


        /*
         * Keep reset active for a clock.
         */

        @(posedge rd_clk);
        #1;

        check(empty_o == 1'b1,
              "adapter remains empty during reset");


        /*
         * ========================================================
         * RELEASE RESET
         * ========================================================
         */

        reset_n = 1'b1;

        /*
         * ========================================================
         * TEST 2 : FIFO DATA REQUEST
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 2 : FIFO DATA REQUEST");
        $display("==============================================");


        /*
         * Put one word into FIFO.
         */

        load_fifo(8'hA5);

        receiver_ready = 1'b0;


    
/*
 * fifo_rd_en is a combinational request.
 * Check it BEFORE the clock edge that accepts the request.
 */

        #1;

       check(fifo_rd_en == 1'b1,
      "adapter requests data from FIFO");

           @(posedge rd_clk);
            #1;
        /*
         * ========================================================
         * TEST 3 : DATA CAPTURE
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 3 : DATA CAPTURE");
        $display("==============================================");


        /*
         * Wait for adapter to receive the FIFO data.
         */

        repeat (3) begin

            @(posedge rd_clk);
            #1;

        end


        check(empty_o == 1'b0,
              "output becomes valid after FIFO data arrives");

        check(data_read == 8'hA5,
              "received data matches FIFO data");


        /*
         * ========================================================
         * TEST 4 : BACKPRESSURE
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 4 : BACKPRESSURE");
        $display("==============================================");


        /*
         * Receiver is NOT ready.
         *
         * Therefore output must remain valid and stable.
         */

        receiver_ready = 1'b0;

        @(posedge rd_clk);
        #1;

        check(empty_o == 1'b0,
              "output remains valid when receiver is not ready");

        check(data_read == 8'hA5,
              "output data remains stable under backpressure");


        @(posedge rd_clk);
        #1;

        check(empty_o == 1'b0,
              "output remains valid during continued backpressure");

        check(data_read == 8'hA5,
              "data remains unchanged during backpressure");


        /*
         * ========================================================
         * TEST 5 : DATA CONSUMPTION
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 5 : DATA CONSUMPTION");
        $display("==============================================");


        receiver_ready = 1'b1;

        @(posedge rd_clk);
        #1;

        /*
         * The receiver consumes the output.
         */

        @(posedge rd_clk);
        #1;

        check(empty_o == 1'b1,
              "output becomes empty after receiver consumes data");


        /*
         * ========================================================
         * TEST 6 : MULTIPLE DATA WORDS
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 6 : MULTIPLE DATA WORDS");
        $display("==============================================");


        /*
         * Load several words.
         *
         * Expected order:
         *
         * 11
         * 22
         * 33
         */

        load_fifo(8'h11);
        load_fifo(8'h22);
        load_fifo(8'h33);

        receiver_ready = 1'b1;


        /*
         * Wait until first word arrives.
         */

        wait (empty_o == 1'b0);
        #1;

        check(data_read == 8'h11,
              "first FIFO word arrives in correct order");


        /*
         * Consume first word.
         */

        @(posedge rd_clk);
        #1;


        /*
         * Wait for second word.
         */

        wait (empty_o == 1'b0);
        #1;

        check(data_read == 8'h22,
              "second FIFO word arrives in correct order");


        /*
         * Consume second word.
         */

        @(posedge rd_clk);
        #1;


        /*
         * Wait for third word.
         */

        wait (empty_o == 1'b0);
        #1;

        check(data_read == 8'h33,
              "third FIFO word arrives in correct order");


        /*
         * Consume third word.
         */

        @(posedge rd_clk);
        #1;


        /*
         * ========================================================
         * TEST 7 : FIFO EMPTY
         * ========================================================
         */

        $display("");
        $display("==============================================");
        $display("TEST 7 : FIFO EMPTY CONDITION");
        $display("==============================================");


        repeat (3) begin
            @(posedge rd_clk);
            #1;
        end

        check(empty_o == 1'b1,
              "adapter becomes empty after all data is consumed");


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