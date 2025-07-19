module baud_generator #(
    parameter SYS_FREQ = 10_000_000,
    parameter BAUD_RATE = 9600
)(
    input  logic clk,
    input  logic reset,
    output logic baud_tick,   // 1x baud tick
    output logic tick_16x     // 16x oversample tick
);

    // Parameters for tick generation
    localparam integer OVERSAMPLE_RATE = 16;
    
    // Baud cycle counts
    localparam integer BAUD_CYCLE     = SYS_FREQ / BAUD_RATE;
    localparam integer TICK16X_CYCLE  = SYS_FREQ / (BAUD_RATE * OVERSAMPLE_RATE);

    // Counters
    logic [$clog2(BAUD_CYCLE)-1:0]    baud_count;
    logic [$clog2(TICK16X_CYCLE)-1:0] tick16x_count;

    always_ff @(posedge clk) begin
        if (reset) begin
            baud_count     <= 0;
            tick16x_count  <= 0;
            baud_tick      <= 0;
            tick_16x       <= 0;
        end
        else begin
            // Baud Tick (1x)
            if (baud_count == BAUD_CYCLE - 1) begin
                baud_count <= 0;
                baud_tick  <= 1;
            end
            else begin
                baud_count <= baud_count + 1;
                baud_tick  <= 0;
            end

            // 16x Tick
            if (tick16x_count == TICK16X_CYCLE - 1) begin
                tick16x_count <= 0;
                tick_16x      <= 1;
            end
            else begin
                tick16x_count <= tick16x_count + 1;
                tick_16x      <= 0;
            end
        end
    end

endmodule