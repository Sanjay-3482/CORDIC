`timescale 1ns / 1ps

module VectoringMode_CORDIC #(
    parameter DATA_WIDTH = 16,
    parameter ITERATIONS = 16
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         valid_in,
    input  wire signed [DATA_WIDTH-1:0] x_in,
    input  wire signed [DATA_WIDTH-1:0] y_in,
    output reg  signed [DATA_WIDTH+1:0] magnitude_out,
    output reg  signed [DATA_WIDTH-1:0] phase_out,
    output reg                          valid_out
);

    // Internal pipe width: add 2 guard bits to prevent overflow during iterations
    localparam PW = DATA_WIDTH + 2;  // 18 bits

    reg signed [DATA_WIDTH-1:0] angle_lut [0:ITERATIONS-1];
    initial begin
        angle_lut[0]  = 16'sd8192;
        angle_lut[1]  = 16'sd4836;
        angle_lut[2]  = 16'sd2554;
        angle_lut[3]  = 16'sd1297;
        angle_lut[4]  = 16'sd652;
        angle_lut[5]  = 16'sd326;
        angle_lut[6]  = 16'sd163;
        angle_lut[7]  = 16'sd81;
        angle_lut[8]  = 16'sd41;
        angle_lut[9]  = 16'sd20;
        angle_lut[10] = 16'sd10;
        angle_lut[11] = 16'sd5;
        angle_lut[12] = 16'sd2;
        angle_lut[13] = 16'sd1;
        angle_lut[14] = 16'sd0;
        angle_lut[15] = 16'sd0;
    end

    // Pipeline registers - PW wide to absorb intermediate growth
    reg signed [PW-1:0] x_pipe [0:ITERATIONS];
    reg signed [PW-1:0] y_pipe [0:ITERATIONS];
    reg signed [PW-1:0] z_pipe [0:ITERATIONS];
    reg                 valid_pipe [0:ITERATIONS];

 
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= ITERATIONS; i = i + 1) begin
                x_pipe[i]     <= 0;
                y_pipe[i]     <= 0;
                z_pipe[i]     <= 0;
                valid_pipe[i] <= 0;
            end
            magnitude_out <= 0;
            phase_out     <= 0;
            valid_out     <= 0;

        end else begin

            // Stage 0: sign-extend inputs into wider pipeline
            valid_pipe[0] <= valid_in;
            if (valid_in) begin
                x_pipe[0] <= {{2{x_in[DATA_WIDTH-1]}}, x_in};  // sign extend to PW
                y_pipe[0] <= {{2{y_in[DATA_WIDTH-1]}}, y_in};
                z_pipe[0] <= 0;
            end

            // Stages 0..ITERATIONS-1: vectoring CORDIC kernel
            for (i = 0; i < ITERATIONS; i = i + 1) begin
                valid_pipe[i+1] <= valid_pipe[i];
                if (valid_pipe[i]) begin
                    if (y_pipe[i] < 0) begin          // y negative → rotate CCW
                        x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] - {{2{angle_lut[i][DATA_WIDTH-1]}}, angle_lut[i]};
                    end else begin                     // y positive/zero → rotate CW
                        x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] + {{2{angle_lut[i][DATA_WIDTH-1]}}, angle_lut[i]};
                    end
                end
            end

            // Output: truncate back to DATA_WIDTH, apply gain correction
            valid_out <= valid_pipe[ITERATIONS];
            if (valid_pipe[ITERATIONS]) begin
                magnitude_out <= x_pipe[ITERATIONS];
                phase_out     <= z_pipe[ITERATIONS][DATA_WIDTH-1:0];
            end
        end
    end

endmodule