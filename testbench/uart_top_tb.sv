`timescale 1ns/1ps

module uart_top_tb;

    // Parameters
    parameter CLK_FREQ = 50_000_000;   // 10 MHz for faster simulation
    parameter BAUD_RATE = 9600;
    parameter DATABITS = 8;
    parameter PARITY_EN = 1;
    parameter PARITY_TYPE = 0;         // 0 = even, 1 = odd

    // Clock period
    localparam CLK_PERIOD = 1_000_000_000 / CLK_FREQ; // in ns

    // DUT signals
    logic clk;
    logic reset;
    logic tx_en;
    logic [DATABITS-1:0] tx_data_in;
    logic tx_data;
    logic tx_busy;
    logic tx_done;
    logic rx_data;
    logic [DATABITS-1:0] rx_data_out;
    logic rx_done;
    logic parity_error;
    logic stop_error;
    logic error_flag;
    logic baud_tick;
    logic tick_16x;

    // Test control variables
    int test_count = 0;
    int pass_count = 0;
    int fail_count = 0;

    // Instantiate DUT
    uart_top #(
        .SYS_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE),
        .DATABITS(DATABITS),
        .PARITY_EN(PARITY_EN),
        .PARITY_TYPE(PARITY_TYPE)
    ) dut (
        .clk(clk),
        .reset(reset),
        .tx_en(tx_en),
        .tx_data_in(tx_data_in),
        .tx_data(tx_data),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .rx_data(rx_data),
        .rx_data_out(rx_data_out),
        .rx_done(rx_done),
        .parity_error(parity_error),
        .stop_error(stop_error),
        .error_flag(error_flag),
	.baud_tick(baud_tick),
	.tick_16x(tick_16x)
    );

    // Clock generation
    always #(CLK_PERIOD/2) clk = ~clk;

    // Task: Initialize signals
    task initialize();
        clk = 0;
        reset = 1;
        tx_en = 0;
        tx_data_in = 8'h00;
        #(CLK_PERIOD * 20);
        reset = 0;
        #(CLK_PERIOD * 5);
    endtask

    // Task: Transmit a byte
    task transmit_byte(input [7:0] data);
        @(posedge clk);
        tx_data_in = data;
        tx_en = 1;
        @(posedge clk);
        tx_en = 0;
        wait(tx_done);
        #(CLK_PERIOD * 10); // Small delay between transmissions
    endtask

    // Task: Wait for reception
    task wait_reception();
        wait(rx_done);
        @(posedge clk);
        @(posedge clk);
    endtask

    // Task: Check test result
    task check_result(input [7:0] expected_data, input string test_name);
        test_count++;
        $display("\n========================================");
        $display("Test #%0d: %s", test_count, test_name);
        $display("========================================");
        $display("Sent Data     : 0x%02h (%d)", expected_data, expected_data);
        $display("Received Data : 0x%02h (%d)", rx_data_out, rx_data_out);
        $display("Parity Error  : %0b", parity_error);
        $display("Stop Error    : %0b", stop_error);
        $display("Error Flag    : %0b", error_flag);
        $display("TX Done       : %0b", tx_done);
        
        if (rx_data_out == expected_data && !error_flag) begin
            $display("TEST PASSED!");
            pass_count++;
        end else begin
            $display("TEST FAILED!");
            fail_count++;
        end
        $display("========================================\n");
    endtask

    // Task: Inject parity error
    task inject_parity_error(input [7:0] data);
        int tick_counter;
        logic parity_bit_original;
    
        // Release loopback temporarily
        release rx_data;
        rx_data = 1'b1; // Idle
        #(CLK_PERIOD * 10);
    
        @(posedge clk);
        tx_data_in = data;
        tx_en = 1;
        @(posedge clk);
        tx_en = 0;
    
        // Monitor tx_data and pass through all bits except parity
        tick_counter = 0;
        forever begin
            @(posedge baud_tick);
            tick_counter++;
        
            if (tick_counter <= 9) begin
                // Pass through START + DATA bits normally
                rx_data = tx_data;
            end
            else if (tick_counter == 10) begin
                // This is the PARITY bit - invert it
                parity_bit_original = tx_data;
                rx_data = ~parity_bit_original;
            end
            else if (tick_counter == 11) begin
                // STOP bit - pass through normally
                rx_data = tx_data;
                break;
            end
        end
    
        wait_reception();
        
        // Re-establish loopback
        force rx_data = tx_data;
    endtask

    // Task: Inject stop bit error
    task inject_stop_error(input [7:0] data);
        int bit_counter;
        
        @(posedge clk);
        tx_data_in = data;
        tx_en = 1;
        @(posedge clk);
        tx_en = 0;
        
        // Wait for stop bit position
        bit_counter = 0;
        forever begin
            @(posedge baud_tick);
            bit_counter++;
            if (PARITY_EN) begin
                if (bit_counter == 11) begin // Start + 8 data + parity + stop
                    force rx_data = 1'b0; // Force stop bit low (error)
                    @(posedge baud_tick);
                    release rx_data;
                    break;
                end
            end else begin
                if (bit_counter == 10) begin // Start + 8 data + stop
                    force rx_data = 1'b0;
                    @(posedge baud_tick);
                    release rx_data;
                    break;
                end
            end
        end
        
        wait_reception();
    endtask

    // Main test procedure
    initial begin
        $display("\n");
        $display("==========================================================");
        $display("        UART FULL-DUPLEX COMPREHENSIVE TESTBENCH          ");
        $display("==========================================================");
        $display("\n");

        // Initialize
        initialize();
        
        // Connect transmitter to receiver (loopback)
        force rx_data = tx_data;

        //===========================================
        // TEST 1: Basic Data Transfer - 0xA5
        //===========================================
        transmit_byte(8'hA5);
        wait_reception();
        check_result(8'hA5, "Basic Transfer - 0xA5");

        //===========================================
        // TEST 2: All Zeros - 0x00
        //===========================================
        transmit_byte(8'h00);
        wait_reception();
        check_result(8'h00, "All Zeros - 0x00");

        //===========================================
        // TEST 3: All Ones - 0xFF
        //===========================================
        transmit_byte(8'hFF);
        wait_reception();
        check_result(8'hFF, "All Ones - 0xFF");

        //===========================================
        // TEST 4: Alternating Pattern - 0xAA
        //===========================================
        transmit_byte(8'hAA);
        wait_reception();
        check_result(8'hAA, "Alternating Pattern - 0xAA");

        //===========================================
        // TEST 5: Alternating Pattern - 0x55
        //===========================================
        transmit_byte(8'h55);
        wait_reception();
        check_result(8'h55, "Alternating Pattern - 0x55");

        //===========================================
        // TEST 6: Random Data - 0x3C
        //===========================================
        transmit_byte(8'h3C);
        wait_reception();
        check_result(8'h3C, "Random Data - 0x3C");

        //===========================================
        // TEST 7: Back-to-Back Transmissions
        //===========================================
        $display("\n========================================");
        $display("Test #%0d: Back-to-Back Transmissions", test_count + 1);
        $display("========================================");
        
        transmit_byte(8'h12);
        wait_reception();
        if (rx_data_out == 8'h12 && !error_flag) begin
            $display("  Byte 1 (0x12): PASSED");
        end else begin
            $display("  Byte 1 (0x12): FAILED");
        end
        
        transmit_byte(8'h34);
        wait_reception();
        if (rx_data_out == 8'h34 && !error_flag) begin
            $display("  Byte 2 (0x34): PASSED");
        end else begin
            $display("  Byte 2 (0x34): FAILED");
        end
        
        transmit_byte(8'h56);
        wait_reception();
        if (rx_data_out == 8'h56 && !error_flag) begin
            $display("  Byte 3 (0x56): PASSED");
            pass_count++;
        end else begin
            $display("  Byte 3 (0x56): FAILED");
            fail_count++;
        end
        test_count++;
        $display("========================================\n");

        //===========================================
        // TEST 8: Reset During Transmission
        //===========================================
        $display("\n========================================");
        $display("Test #%0d: Reset During Transmission", test_count + 1);
        $display("========================================");
        
        @(posedge clk);
        tx_data_in = 8'hBB;
        tx_en = 1;
        @(posedge clk);
        tx_en = 0;
        
        // Wait a few bit periods then reset
        repeat(5) @(posedge baud_tick);
        reset = 1;
        #(CLK_PERIOD * 10);
        reset = 0;
        #(CLK_PERIOD * 10);
        
        if (tx_done && !tx_busy) begin
            $display("  Transmitter properly reset: PASSED");
            pass_count++;
        end else begin
            $display("  Transmitter reset failed: FAILED");
            fail_count++;
        end
        test_count++;
        $display("========================================\n");
        
        // Re-establish loopback after reset
        force rx_data = tx_data;

        //===========================================
        // TEST 9: Parity Error Injection
        //===========================================
        release rx_data;
        $display("\n========================================");
        $display("Test #%0d: Parity Error Detection", test_count + 1);
        $display("========================================");
        
        inject_parity_error(8'hC7);
        
        $display("Sent Data       : 0x%02h", 8'hC7);
        $display("Parity Error    : %0b", parity_error);
        $display("Error Flag      : %0b", error_flag);
        
        if (parity_error && error_flag) begin
            $display("Parity Error Detected: PASSED");
            pass_count++;
        end else begin
            $display("Parity Error Not Detected: FAILED");
            fail_count++;
        end
        test_count++;
        $display("========================================\n");
        
        force rx_data = tx_data;
        #(CLK_PERIOD * 20);

        //===========================================
        // TEST 10: Stop Bit Error Injection
        //===========================================
        release rx_data;
        $display("\n========================================");
        $display("Test #%0d: Stop Bit Error Detection", test_count + 1);
        $display("========================================");
        
        inject_stop_error(8'hD8);
        
        $display("Sent Data       : 0x%02h", 8'hD8);
        $display("Stop Error      : %0b", stop_error);
        $display("Error Flag      : %0b", error_flag);
        
        if (stop_error && error_flag) begin
            $display("Stop Bit Error Detected: PASSED");
            pass_count++;
        end else begin
            $display("Stop Bit Error Not Detected: FAILED");
            fail_count++;
        end
        test_count++;
        $display("========================================\n");

        //===========================================
        // TEST 11: Full Duplex Capability Check
        //===========================================
        force rx_data = tx_data;
        #(CLK_PERIOD * 20);
        
        $display("\n========================================");
        $display("Test #%0d: Full-Duplex Verification", test_count + 1);
        $display("========================================");
        $display("Testing simultaneous TX and RX...");
        
        transmit_byte(8'hF0);
        wait_reception();
        
        if (rx_data_out == 8'hF0 && !error_flag) begin
            $display("? Full-Duplex Communication: PASSED");
            pass_count++;
        end else begin
            $display("? Full-Duplex Communication: FAILED");
            fail_count++;
        end
        test_count++;
        $display("========================================\n");

        //===========================================
        // FINAL SUMMARY
        //===========================================
        #1000;
        $display("\n");
        $display("==========================================================");
        $display("                      TEST SUMMARY                        ");
        $display("==========================================================");
        $display("  Total Tests  : %0d", test_count);
        $display("  Passed       : %0d", pass_count);
        $display("  Failed       : %0d", fail_count);
        $display("  Success Rate : %.1f%%", (pass_count * 100.0) / test_count);
        
        if (fail_count == 0) begin
            $display("\n  ALL TESTS PASSED! \n");
        end else begin
            $display("\n  SOME TESTS FAILED! \n");
        end
        $display("==========================================================");

        $finish;
    end

    // Timeout watchdog
    initial begin
        #50_000_000; // 50ms timeout
        $display("\nERROR: Simulation timeout!");
        $finish;
    end

endmodule
