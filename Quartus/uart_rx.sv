module uart_rx #(
    parameter DATABITS = 8,
    parameter PARITY_EN = 1,
    parameter PARITY_TYPE = 0
)(
    input logic clk,
    input logic reset,
    input logic tick_16x, 
    input logic rx_data,
    output logic [DATABITS-1:0] data_out,
    output logic rx_done,
    output logic parity_error,
    output logic stop_error
);

    // FSM States for oversampling
typedef enum logic [2:0] {
	IDLE,
        START,
        DATA,
        PARITY,
        STOP
} state_rx;

state_rx CS;

logic [3:0] sample_count; // Counts from 0-15 for the 16x tick
logic [2:0] bit_count;    // Counts data bits from 0-7

logic [DATABITS-1:0] data_reg;
logic parity_calc;

always_comb begin
	parity_calc = (PARITY_TYPE == 0) ? ^data_reg : ~(^data_reg);
end

always_ff @(posedge clk) begin
	if (reset) begin
		CS <= IDLE;
		sample_count <= 0;
		bit_count <= 0;
		data_reg <= 0;
		data_out <= 0;
		rx_done <= 0;
                parity_error <= 0;
                stop_error <= 0;
        end
        else begin
                rx_done <= 0;
		if (tick_16x) begin
			case (CS)
			IDLE: begin
				parity_error <= 0;
				stop_error <= 0;
                        	if (rx_data == 1'b0) begin
                        		CS <= START;
                            		sample_count <= 0; // Reset counter to find mid-point
                        	end
                    	end

                    	START: begin
				sample_count <= sample_count + 1;
				if (sample_count == 7) begin
                        		if (rx_data == 1'b0) begin // It's a valid start bit
                                		CS <= DATA;
                                		sample_count <= 0; // Reset for next bit
                                		bit_count <= 0;
                            		end
                            		else begin // It was a glitch, return to idle
                                		CS <= IDLE;
                            		end
                        	end
                    	end

                    	DATA: begin
                        	sample_count <= sample_count + 1;
                        
                        	if (sample_count == 15) begin
                            		sample_count <= 0;
                            		data_reg[bit_count] <= rx_data; // Sample and store bit

                            		if (bit_count == DATABITS - 1) begin
						if (PARITY_EN) CS <= PARITY;
                        	        	else CS <= STOP;
                        	    	end
                        	    	else begin
                        	        	bit_count <= bit_count + 1;
                        	    	end
                        	end
                    	end

                    	PARITY: begin
                        	sample_count <= sample_count + 1;
                        	if (sample_count == 15) begin
                            		sample_count <= 0;
                            		parity_error <= (rx_data != parity_calc); // Sample and check parity
                            		CS <= STOP;
                        	end
                    	end

                    	STOP: begin
                        	sample_count <= sample_count + 1;
                        	if (sample_count == 15) begin
                            		stop_error <= (rx_data != 1'b1); // Stop bit must be high
                            		data_out <= data_reg;
                            		rx_done <= 1;
                            		CS <= IDLE;
                        	end
                    	end

                    	default: CS <= IDLE;

                	endcase
		end
	end
end

endmodule