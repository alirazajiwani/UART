module uart_top #(
	parameter SYS_FREQ = 50_000_000, 
	parameter BAUD_RATE = 9600,
	parameter DATABITS = 8,
	parameter PARITY_EN = 1,  	// 1 = parity enabled, 0 = parity disabled
	parameter PARITY_TYPE = 0 	// 0 = even parity, 1 = odd parity
)(
	input logic clk,
	input logic reset,
	input logic tx_en,
	input logic [DATABITS-1:0] tx_data_in,		//Parallel data Stored for TX to intake
	input logic rx_data, 				//Serial In to RX
	output logic tx_data,				//Serial Out from TX
	output logic tx_done,             
	output logic [DATABITS-1:0] rx_data_out,	//Parallel data Stored from RX to output
	output logic rx_done,
 	output logic error_flag,
	output logic baud_tick,  			// 1x 	tick for the transmitter
	output logic tick_16x    			// 16x tick for the receiver
);

logic tx_busy, stop_error, parity_error;


// Baud rate generator
baud_gen #(
	.SYS_FREQ(SYS_FREQ),
	.BAUD_RATE(BAUD_RATE)
) baud_inst (
	.clk(clk),
	.reset(reset),
	.baud_tick(baud_tick),
	.tick_16x(tick_16x)
);

// UART Transmitter
uart_tx #(
	.DATABITS(DATABITS),
	.PARITY_EN(PARITY_EN),
	.PARITY_TYPE(PARITY_TYPE)
) tx_inst (
	.clk(clk),
	.reset(reset),
	.data_in(tx_data_in),
	.tx_en(tx_en),
	.baud_tick(baud_tick),
	.tx_data(tx_data),
	.tx_busy(tx_busy)
);

// UART Receiver
uart_rx #(
	.DATABITS(DATABITS),
	.PARITY_EN(PARITY_EN),
	.PARITY_TYPE(PARITY_TYPE)
) rx_inst (
	.clk(clk),
	.reset(reset),
	.rx_data(rx_data),
	.tick_16x(tick_16x),
	.data_out(rx_data_out),
	.rx_done(rx_done),
	.parity_error(parity_error),
	.stop_error(stop_error)
);


assign tx_done = ~tx_busy;                    // Tx_done signal (high when transmission complete)
assign error_flag = parity_error | stop_error; // Combined error flag


endmodule