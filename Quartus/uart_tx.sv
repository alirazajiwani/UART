module uart_tx #(
	parameter DATABITS = 8,
	parameter PARITY_EN = 1,  // 1 = parity enabled, 0 = parity disabled
	parameter PARITY_TYPE = 0 // 0 = even parity, 1 = odd parity
)(
	input logic clk,
	input logic reset,
	input logic [DATABITS-1:0] data_in,
	input logic tx_en,
	input logic baud_tick,
	output logic tx_data,
	output logic tx_busy
);

typedef enum logic [2:0] {
	IDLE,
	START,
	DATA,
	PARITY,
	STOP
} state_tx;

state_tx CS;
logic [2:0] bit_count;
logic [DATABITS-1:0] data_reg;
logic tx_reg;
logic parity_bit;
logic tx_en_latched;


always_ff @(posedge clk) begin
    if (reset)
        tx_en_latched <= 1'b0;
    else if (!tx_busy && tx_en)
        tx_en_latched <= 1'b1;
    else if (CS == IDLE && baud_tick)
        tx_en_latched <= 1'b0;
end


// State machine logic
always_ff @(posedge clk) begin
	if (reset) begin
		CS <= IDLE;
        	bit_count <= 0;
        	data_reg <= '0;
        	tx_reg <= 1'b1;  // Idle state is high
        	tx_busy <= 1'b0;
		parity_bit <= 1'b0;
    	end
    	else if (baud_tick) begin
		case (CS)
		IDLE: begin
			tx_reg <= 1'b1;  // Idle line high
                	if (tx_en_latched) begin
				CS <= START;
				tx_busy <= 1'b1;
				data_reg <= data_in;
				bit_count <= 0;
				parity_bit <= (PARITY_TYPE == 0)? ^data_in: ~(^data_in);
			end
            	end
            
		START: begin
			tx_reg <= 1'b0;  // Start bit is low
			CS <= DATA;
            	end
            
		DATA: begin
			tx_reg <= data_reg[bit_count];
                	if (bit_count == DATABITS-1) begin
                		//bit_count <= 0;  // Reset for next transmission
                    		if (PARITY_EN) begin
					CS <= PARITY;
                    		end 
				else begin
					CS <= STOP;
				end
                	end 
			else begin
				bit_count <= bit_count + 1;
			end
		end
            
		PARITY: begin
			tx_reg <= parity_bit;
			CS <= STOP;
		end
            
		STOP: begin
			tx_reg <= 1'b1;  // Stop bit is high
			CS <= IDLE;
			tx_busy <= 1'b0;
		end
            
		default: begin
			CS <= IDLE;
			tx_reg <= 1'b1;
			tx_busy <= 1'b0;
		end
		endcase
	end
end

// Output assignment
assign tx_data = tx_reg;

endmodule