// UART Interface
interface uart_if(input logic clk);
	logic reset;
	logic tx_en;
	logic [7:0] tx_data_in;
	logic rx_data;
	logic tx_data;
	logic tx_done;      
	logic [7:0] rx_data_out;
	logic rx_done;
	logic error_flag;
	logic baud_tick;
	logic tick_16x;
endinterface

// Top-level Testbench Module
module uart_tb;
	import uart_tb_package::*;
    
	logic clk;
	uart_if uif(clk);
	environment env;
	uart_config cfg;
    
	// DUT Instantiation
	uart_top #(
        	.SYS_FREQ(50_000_000),
        	.BAUD_RATE(9600),
        	.DATABITS(8),
        	.PARITY_EN(1),
        	.PARITY_TYPE(0)
	) dut (
        	.clk(uif.clk),
        	.reset(uif.reset),
        	.tx_en(uif.tx_en),
        	.tx_data_in(uif.tx_data_in),
        	.rx_data(uif.rx_data),
        	.tx_data(uif.tx_data),
        	.tx_done(uif.tx_done),
        	.rx_data_out(uif.rx_data_out),
        	.rx_done(uif.rx_done),
        	.error_flag(uif.error_flag),
        	.baud_tick(uif.baud_tick),
        	.tick_16x(uif.tick_16x)
	);
    
	// Clock generation (50MHz = 20ns period)
	initial begin
        	clk = 0;
        	forever #10 clk = ~clk;
	end
    
	// Test execution
	initial begin
        	$display("\n");
        	$display("========================================================");
        	$display("           UART TESTBENCH SIMULATION STARTED");
       		$display("========================================================");
        	$display("System Frequency : %0d Hz", 50_000_000);
        	$display("Baud Rate        : %0d", 9600);
        	$display("Data Bits        : %0d", 8);
        	$display("Parity           : %s", "ENABLED (EVEN)");
        	$display("========================================================");
        
		cfg = new();
        	env = new(uif, cfg, 10);
        	env.run();
        
        	#100000;
        
 		$display("========================================================");
        	$display("           UART TESTBENCH SIMULATION ENDED");
        	$display("========================================================");
        
        	$finish;
    	end

endmodule