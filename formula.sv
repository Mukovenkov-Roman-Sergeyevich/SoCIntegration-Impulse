module formula #(
    parameter int N = 8  // Data width
) (
    input logic clk,
    input logic rstn,

    input logic i_valid,
    input logic signed [N-1 : 0] a,
    input logic signed [N-1 : 0] b,
    input logic signed [N-1 : 0] c,
    input logic signed [N-1 : 0] d,

    output logic o_valid,
    output logic signed [N-1 : 0] q
);

    localparam int N_SUB1 =     N + 1;  // a - b
    localparam int N_MUL1 =     N + 2;  // 3 * c
    localparam int N_ADD1 =     N + 2;  // 1 + (3 * c)
    localparam int N_MUL2 = 2 * N + 3;  // (a - b) * (1 + 3 * c)
    localparam int N_MUL3 =     N + 2;  // 4 * d
    localparam int N_SUB2 = 2 * N + 4;  // ((a - b) * (1 + 3 * c)) - (4 * d)
    localparam int N_DIV  = 2 * N + 3;  // divide by 2

    localparam signed [N-1:0] MAX_VAL =  (1 << (N - 1)) - 1;
    localparam signed [N-1:0] MIN_VAL = -(1 << (N - 1));

    logic valid2;
    logic valid3;
    logic valid4;
    logic valid5;
    logic valid6;

    // Stage 1: (a - b), (3 * c), (4 * d)
    logic signed [N_SUB1-1:0] w_sub1;
    logic signed [N_MUL1-1:0] w_mul1;
    logic signed [N_MUL3-1:0] w_mul3;

    assign w_sub1 = a - b;
    assign w_mul1 = 3 * c;
    assign w_mul3 = 4 * d;

    logic signed [N_MUL1-1:0] r_mul1;
    logic signed [N_SUB1-1:0] r1_sub1;
    logic signed [N_MUL3-1:0] r1_mul3;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r1_sub1 <= '0;
            r_mul1  <= '0;
            r1_mul3 <= '0;
            valid2  <= '0;
        end else begin
            r1_sub1 <= w_sub1;
            r_mul1  <= w_mul1;
            r1_mul3 <= w_mul3;
            valid2  <= i_valid;
        end
    end

    // Stage 2: 1 + (3 * c)
    logic signed [N_ADD1-1:0] w_add1;

    assign w_add1 = r_mul1 + N_ADD1'(1);

    logic signed [N_ADD1-1:0] r_add1;
    logic signed [N_SUB1-1:0] r2_sub1;
    logic signed [N_MUL3-1:0] r2_mul3;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r2_sub1 <= '0;
            r_add1  <= '0;
            r2_mul3 <= '0;
            valid3  <= '0;
        end else begin
            r2_sub1 <= r1_sub1;
            r_add1  <= w_add1;
            r2_mul3 <= r1_mul3;
            valid3  <= valid2;
        end
    end

    // Stage 3: (a - b) * (1 + 3 * c)
    logic signed [N_MUL2-1:0]  w_mul2;

    assign w_mul2 = r2_sub1 * r_add1;

    logic signed [N_MUL2-1:0] r_mul2;
    logic signed [N_MUL3-1:0] r3_mul3;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_mul2  <= '0;
            r3_mul3 <= '0;
            valid4  <= '0;
        end else begin
            r_mul2  <= w_mul2;
            r3_mul3 <= r2_mul3;
            valid4  <= valid3;
        end
    end

    // Stage 4: ((a - b) * (1 + 3 * c)) - (4 * d)
    logic signed [N_SUB2-1:0] w_sub2;

    // Sign extend
    assign w_sub2 = {{N_SUB2-N_MUL2{r_mul2[N_MUL2-1]}}, r_mul2} -
                    {{N_SUB2-N_MUL3{r3_mul3[N_MUL3-1]}}, r3_mul3};

    logic signed [N_SUB2-1:0] r_sub2;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_sub2 <= '0;
            valid5 <= '0;
        end else begin
            r_sub2 <= w_sub2;
            valid5 <= valid4;
        end
    end

    // Stage 5: divide by 2
    logic signed [N_DIV-1:0] w_div;

    assign w_div = r_sub2 >>> 1;
	 
	 logic signed [N_DIV-1:0] r_div;

    always_ff @(posedge clk) begin
        if (!rstn) begin
            r_div  <= '0;
            valid6 <= '0;
        end else begin
            r_div  <= w_div;
            valid6 <= valid5;
        end
    end

    logic signed [N-1:0] saturated_q;

    always_comb begin
        if (r_div > MAX_VAL) begin
            saturated_q = MAX_VAL;
        end else if (r_div < MIN_VAL) begin
            saturated_q = MIN_VAL;
        end else begin
            saturated_q = r_div[N-1:0];
        end
    end

    assign q = saturated_q;
    assign o_valid = valid6;

endmodule
