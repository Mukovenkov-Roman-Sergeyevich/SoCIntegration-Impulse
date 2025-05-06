`timescale 1ns / 1ps

module formula_tb;

    parameter int N = 8;
    parameter CLK_PERIOD = 10;

    logic clk;
    logic rstn;

    logic i_valid;
    logic signed [N-1 : 0] a;
    logic signed [N-1 : 0] b;
    logic signed [N-1 : 0] c;
    logic signed [N-1 : 0] d;

    logic o_valid;
    logic signed [N-1 : 0] q;

    formula #(
        .N(N)
    ) 
    dut (
        .clk        ( clk     ),
        .rstn       ( rstn    ),
        .i_valid    ( i_valid ),
        .a          ( a       ),
        .b          ( b       ),
        .c          ( c       ),
        .d          ( d       ),
        .o_valid    ( o_valid ),
        .q          ( q       )
    );

    localparam DUT_LATENCY = 5;

    always #(CLK_PERIOD / 2) clk = ~clk;

    function automatic signed [N-1:0] find_expected_q (
        input signed [N-1:0] i_a,
        input signed [N-1:0] i_b,
        input signed [N-1:0] i_c,
        input signed [N-1:0] i_d
    );
        localparam int N_MAX = 2*N+4; 

        logic signed [N_MAX-1:0] sub1; // a - b
        logic signed [N_MAX-1:0] add1; // 1 + 3 * c
        logic signed [N_MAX-1:0] mul3; // 4 * d
        logic signed [N_MAX-1:0] sub2; // ((a - b) * (1 + 3 * c)) - (4 * d)
        logic signed [N_MAX-1:0] div;  // divide by 2
        logic signed [N-1:0] saturated_q;
        
        logic signed [N-1:0] MAX_VAL;
        logic signed [N-1:0] MIN_VAL;

        MAX_VAL =  (1 << (N-1)) - 1;
        MIN_VAL = -(1 << (N-1));

        sub1 = N_MAX'(i_a) - N_MAX'(i_b);
        add1 = N_MAX'(1  ) + (N_MAX'(3) * N_MAX'(i_c));
        mul3 = N_MAX'(4  ) * N_MAX'(i_d);

        sub2 = (sub1 * add1) - mul3;

        div = sub2 >>> 1;

        if (div > MAX_VAL) begin
            saturated_q = MAX_VAL;
        end else if (div < MIN_VAL) begin
            saturated_q = MIN_VAL;
        end else begin
            saturated_q = div[N-1:0];
        end
        return saturated_q;
    endfunction

    initial begin
        clk = 0;
        rstn = 0;
        i_valid = 0;
        a = 0; b = 0; c = 0; d = 0;

        $display("Testbench: N=%0d", N);

        #(CLK_PERIOD * 2);
        rstn = 1;
        $display("Reset released at %0t", $time);
        #(CLK_PERIOD);

        // Test 1: Simple values
        a = 1; b = 2; c = 3; d = 4; i_valid = 1;
        $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
        #CLK_PERIOD; i_valid = 0;

        // Test 2: Simple values
        #(CLK_PERIOD * 2); 
        a = 10; b = 20; c = 5; d = 10; i_valid = 1;
        $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
        #CLK_PERIOD; i_valid = 0;

        // Test 3: Negative numbers
        #(CLK_PERIOD * 2);
        a = -5; b = 10; c = -20; d = -1; i_valid = 1;
        $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
        #CLK_PERIOD; i_valid = 0;

        // Test 4: Positive overflow before clamping
        if (N == 8) begin 
            #(CLK_PERIOD * 2);
            a = 120; b = -25; c = 7; d = 6; i_valid = 1;
            $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
            #CLK_PERIOD; i_valid = 0;
        end

        // Test 5: Negative overflow before clamping
        if (N == 8) begin
            #(CLK_PERIOD * 2);
            a = -120; b = 25; c = 7; d = 6; i_valid = 1;
            $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
            #CLK_PERIOD; i_valid = 0;
        end

        // Test 6: Zero values
        #(CLK_PERIOD * 2);
        a = 0; b = 0; c = 0; d = 0; i_valid = 1;
        $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
        #CLK_PERIOD; i_valid = 0;

        // Test 7: Max and min inputs
        if (N == 8) begin
            # (CLK_PERIOD * 2);
            a = 127; b = -128; c = 127; d = -128; i_valid = 1;
            $display("[%0t]: a=%d, b=%d, c=%d, d=%d, i_valid=%b", $time, a, b, c, d, i_valid);
            #CLK_PERIOD; i_valid = 0;
        end

        // More tests are needed, due to time constraints, this isn't as fleshed out :(

        #(CLK_PERIOD * (DUT_LATENCY + 5));
        $display("Finished at %0t", $time);
        $finish;
    end

    // Shift register
    logic signed [N-1:0] a_shift     [DUT_LATENCY];
    logic signed [N-1:0] b_shift     [DUT_LATENCY];
    logic signed [N-1:0] c_shift     [DUT_LATENCY];
    logic signed [N-1:0] d_shift     [DUT_LATENCY];
    logic                valid_shift [DUT_LATENCY];

    always @(posedge clk) begin
        if (!rstn) begin
            for (int i = 0; i < DUT_LATENCY; i++) begin
                valid_shift[i] <= '0;
                a_shift[i] <= '0; 
                b_shift[i] <= '0;
                c_shift[i] <= '0;
                d_shift[i] <= '0;
            end
        end else begin
            valid_shift[0] <= i_valid; 
            if (i_valid) begin 
                a_shift[0] <= a;
                b_shift[0] <= b;
                c_shift[0] <= c;
                d_shift[0] <= d;
            end

            for (int i = 1; i < DUT_LATENCY; i++) begin
                a_shift[i] <= a_shift[i-1];
                b_shift[i] <= b_shift[i-1];
                c_shift[i] <= c_shift[i-1];
                d_shift[i] <= d_shift[i-1];
                valid_shift[i] <= valid_shift[i-1];
            end
        end
    end

    logic signed [N-1:0] expected_q;

    always @(posedge clk) begin
        if (rstn) begin
            if (o_valid) begin
                if (valid_shift[DUT_LATENCY-1]) begin
                    expected_q = find_expected_q(a_shift[DUT_LATENCY-1],
                                                 b_shift[DUT_LATENCY-1],
                                                 c_shift[DUT_LATENCY-1],
                                                 d_shift[DUT_LATENCY-1]);

                    $display("[%0t]: o_valid=%b, q=%d, expected_q=%d (a=%d,b=%d,c=%d,d=%d)",
                             $time, o_valid, q, expected_q, 
                             a_shift[DUT_LATENCY-1], b_shift[DUT_LATENCY-1], 
                             c_shift[DUT_LATENCY-1], d_shift[DUT_LATENCY-1]);

                    if (q !== expected_q) begin
                        $error("False!");
                    end else begin
                        $display("True");
                    end

                end else begin
                    $error("[%0t]: o_valid = %d, valid_shift[%0d] = %d.",
                           $time, o_valid, DUT_LATENCY-1, valid_shift[DUT_LATENCY-1]);
                end

            end else if (valid_shift[DUT_LATENCY-1]) begin
                $error("[%0t]: o_valid = %d, valid_shift[%0d] = %d.",
                       $time, o_valid, DUT_LATENCY-1, valid_shift[DUT_LATENCY-1]);
            end
        end
    end

endmodule