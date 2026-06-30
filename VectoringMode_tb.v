`timescale 1ns / 1ps


module VectoringMode_tb;

    //===========================================================
    // Parameters
    //===========================================================

    localparam DATA_WIDTH = 16;
    localparam ITERATIONS = 16;
    localparam CLK_PERIOD = 10;

    //===========================================================
    // Testbench Signals
    //===========================================================

    reg clk;
    reg rst_n;
    reg valid_in;

    reg signed [DATA_WIDTH-1:0] x_in;
    reg signed [DATA_WIDTH-1:0] y_in;

    wire signed [DATA_WIDTH-1:0] magnitude_out;
    wire signed [DATA_WIDTH-1:0] phase_out;
    wire valid_out;

    //===========================================================
    // Instantiate DUT
    //===========================================================

    VectoringMode_CORDIC #(
        .DATA_WIDTH(DATA_WIDTH),
        .ITERATIONS(ITERATIONS)
    ) dut (

        .clk(clk),
        .rst_n(rst_n),
        .valid_in(valid_in),

        .x_in(x_in),
        .y_in(y_in),

        .magnitude_out(magnitude_out),
        .phase_out(phase_out),
        .valid_out(valid_out)

    );

    //===========================================================
    // Clock Generation
    //===========================================================

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    //===========================================================
    // Test Data Arrays
    //===========================================================

    real x_test [0:6];
    real y_test [0:6];

    real expected_mag [0:6];
    real expected_phase [0:6];

    initial begin
//-------------------------------------------------------
// Test Vector 0
//-------------------------------------------------------
    x_test[0] = 1.0;
    y_test[0] = 0.0;
    
    expected_mag[0]   = 1.646760258;
    expected_phase[0] = 0.000000;
    
    //-------------------------------------------------------
    // Test Vector 1
    //-------------------------------------------------------
    x_test[1] = 1.0;
    y_test[1] = 0.1;
    
    expected_mag[1]   = 1.654974449;
    expected_phase[1] = 5.710593;
    
    //-------------------------------------------------------
    // Test Vector 2
    //-------------------------------------------------------
    x_test[2] = 0.8;
    y_test[2] = 0.5;
    
    expected_mag[2]   = 1.554815238;
    expected_phase[2] = 32.005383;
    
    //-------------------------------------------------------
    // Test Vector 3
    //-------------------------------------------------------
    x_test[3] = 0.5;
    y_test[3] = 1.0;
    
    expected_mag[3]   = 1.841248392;
    expected_phase[3] = 63.434949;
    
    //-------------------------------------------------------
    // Test Vector 4
    //-------------------------------------------------------
    x_test[4] = 0.0;
    y_test[4] = 1.0;
    
    expected_mag[4]   = 1.646760258;
    expected_phase[4] = 90.000000;
    
    //-------------------------------------------------------
    // Test Vector 5
    //-------------------------------------------------------
    x_test[5] = 1.0;
    y_test[5] = -0.2;
    
    expected_mag[5]   = 1.679368216;
    expected_phase[5] = -11.309932;
    
    //-------------------------------------------------------
    // Test Vector 6
    //-------------------------------------------------------
    x_test[6] = 0.7;
    y_test[6] = 0.5;
    
    expected_mag[6]   = 1.416644670;
    expected_phase[6] = 35.537678;
    //===========================================================
    // Variables
    //===========================================================
end
    integer i;
    integer output_idx;

    real actual_mag;
    real actual_phase;

    //===========================================================
    // Main Test Sequence
    //===========================================================

    initial begin

        rst_n      <= 0;
        valid_in   <= 0;
        x_in       <= 0;
        y_in       <= 0;

        output_idx = 0;
                //--------------------------------------------------------
        // Apply Reset
        //--------------------------------------------------------

        #(CLK_PERIOD*2);

        rst_n <= 1;

        #(CLK_PERIOD);

        $display("\n==============================================");
        $display("   VECTORING MODE CORDIC TEST START");
        $display("==============================================");

        //--------------------------------------------------------
        // Feed Inputs
        //--------------------------------------------------------

        for(i=0;i<7;i=i+1) begin

            // Convert to Q2.14

            x_in <= (x_test[i] * 16384.0);
            y_in <= (y_test[i] * 16384.0);

            valid_in <= 1;

            @(posedge clk);

        end

        valid_in <= 0;

    end


    //===========================================================
    // Output Monitor
    //===========================================================

    always @(posedge clk) begin

        if(valid_out) begin

            actual_mag   = $itor(magnitude_out) / 16384.0;
            actual_phase = $itor(phase_out)     * 90.0 / 16384;

            $display("\n--------------------------------------------");

            $display("Test Vector %0d",output_idx);

            $display("Input Vector");

            $display("X = %f",x_test[output_idx]);
            $display("Y = %f",y_test[output_idx]);

            $display("--------------------------------------------");

            $display("Expected Magnitude = %f",
                     expected_mag[output_idx]);

            $display("CORDIC Magnitude   = %f",
                     actual_mag);

            $display("--------------------------------------------");

            $display("Expected Phase = %f deg",
                     expected_phase[output_idx]);

            $display("CORDIC Phase   = %f deg",
                     actual_phase);

            output_idx = output_idx + 1;

            if(output_idx == 7) begin

                $display("\n==============================================");
                $display("      ALL TEST VECTORS COMPLETED");
                $display("==============================================");

                $finish;

            end

        end

    end


    //===========================================================
    // Timeout
    //===========================================================

    initial begin

        #(CLK_PERIOD*100);

        $display("TIMEOUT");

        $finish;

    end

endmodule