`timescale 1ns / 1ps


module Rotation_mode# (
    parameter DATA_WIDTH = 16,  // Width of x, y, z registers
    parameter ITERATIONS = 16   // Number of CORDIC iterations (pipeline stages)
) (
    input                       clk,
    input                       rst_n,
    input                       valid_in,   // Data valid input
    input      signed [DATA_WIDTH-1:0] angle_in,   // Input angle in scaled format

    output reg signed [DATA_WIDTH-1:0] x_out,      // cos(angle_in)
    output reg signed [DATA_WIDTH-1:0] y_out,      // sin(angle_in)
    output reg                  valid_out   // Data valid output
);

    //--------------------------------------------------------------------------
    // 1. Angle Look-Up Table (LUT) for arctan(2^-i)
    //--------------------------------------------------------------------------
    // These are the pre-calculated, fixed-point values for our micro-rotations.
    reg signed [DATA_WIDTH-1:0] angle_lut [0:ITERATIONS-1];

    initial begin
        // Values are  (arctan(2^-i) in degrees )* (16384/90) to scale correctly
        angle_lut[0]  = 16'd8192; // 45.0 deg
        angle_lut[1]  = 16'd4836; // 26.565 deg
        angle_lut[2]  = 16'd2554; // 14.036 deg
        angle_lut[3]  = 16'd1297; // 7.125 deg
        angle_lut[4]  = 16'd652;  // 3.576 deg
        angle_lut[5]  = 16'd326;  // 1.79 deg
        angle_lut[6]  = 16'd163;  // 0.895 deg
        angle_lut[7]  = 16'd81;   // 0.447 deg
        angle_lut[8]  = 16'd41;   // 0.224 deg
        angle_lut[9]  = 16'd20;   // 0.112 deg
        angle_lut[10] = 16'd10;   // 0.056 deg
        angle_lut[11] = 16'd5;    // 0.028 deg
        angle_lut[12] = 16'd2;    // 0.014 deg
        angle_lut[13] = 16'd1;    // 0.007 deg
        angle_lut[14] = 16'd1;    // 0.003 deg (precision limit)
        angle_lut[15] = 16'd0;    // 0.002 deg (precision limit)
    end

    //--------------------------------------------------------------------------
    // 2. Internal Registers for the Pipeline
    //--------------------------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] x_pipe [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] y_pipe [0:ITERATIONS];
    reg signed [DATA_WIDTH-1:0] z_pipe [0:ITERATIONS];
    reg valid_pipe [0:ITERATIONS];

    //--------------------------------------------------------------------------
    // 3. Datapath and Pipeline Logic
    //--------------------------------------------------------------------------
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic
            for (i=0; i<=ITERATIONS; i=i+1) begin
                x_pipe[i] <= 0;
                y_pipe[i] <= 0;
                z_pipe[i] <= 0;
                valid_pipe[i] <= 0;
            end
            x_out <= 0;
            y_out <= 0;
            valid_out <= 0;
        end else begin
            // Pipeline Stage 0: Input capture
            valid_pipe[0] <= valid_in;
            if (valid_in) begin
                x_pipe[0] <= 16'd9950;  // Initial X = 1/K (0.60725) in Q2.14
                y_pipe[0] <= 16'd0;     // Initial Y = 0
                z_pipe[0] <= angle_in;  // Load the target angle
            end else begin
                // Optional: clear or keep data when invalid. Keeping is fine.
            end

            // Pipeline Stages 1 to ITERATIONS
            for (i=0; i<ITERATIONS; i=i+1) begin
                valid_pipe[i+1] <= valid_pipe[i]; // Propagate the valid signal
                
                // Only compute if valid data is present to save switching power, 
                // though strictly not necessary for functionality.
                if (valid_pipe[i]) begin
                    // Determine rotation direction based on the sign of z
                    if (z_pipe[i][DATA_WIDTH-1]) begin // z is negative
                        x_pipe[i+1] <= x_pipe[i] + (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] - (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] + angle_lut[i];
                    end else begin // z is positive or zero
                        x_pipe[i+1] <= x_pipe[i] - (y_pipe[i] >>> i);
                        y_pipe[i+1] <= y_pipe[i] + (x_pipe[i] >>> i);
                        z_pipe[i+1] <= z_pipe[i] - angle_lut[i];
                    end
                end
            end
            

            valid_out <= valid_pipe[ITERATIONS];
            if(valid_out)begin
            // Output Registration
                    x_out <= x_pipe[ITERATIONS]; // Cosine result
                    y_out <= y_pipe[ITERATIONS]; // Sine result            
            end
        end
    end
endmodule
