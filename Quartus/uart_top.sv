module uart_top #(
	parameter SYS_FREQ = 10_000_000, 
	parameter BAUD_RATE = 9600,
	parameter DATABITS = 8,
	parameter PARITY_EN = 1,  // 1 = parity enabled, 0 = parity disabled
	parameter PARITY_TYPE = 0 // 0 = even parity, 1 = odd parity
)(
	input logic clk,
	input logic reset,
	input logic tx_en,
	input logic [DATABITS-1:0] tx_data_in,
	input logic rx_data,
	output logic tx_data,
	output logic tx_busy,
	output logic [DATABITS-1:0] rx_data_out,
	output logic rx_done,
	output logic parity_error,
	output logic stop_error,
	output logic baud_tick_dbg,
	output logic baud_tick_16x_dbg
);

logic baud_tick;   // 1x tick for the transmitter
logic tick_16x;    // 16x tick for the receiver

  // Baud rate generator
    baud_generator #( // Use the correct module name
        .SYS_FREQ(SYS_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) baud_inst (
        .clk(clk),
        .reset(reset),
        .baud_tick(baud_tick),   // Connect both outputs
        .tick_16x(tick_16x)      // Connect both outputs
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

assign baud_tick_dbg = baud_tick;
assign baud_tick_16x_dbg = tick_16x;

endmodule