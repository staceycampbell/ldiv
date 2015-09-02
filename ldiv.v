module ldiv #
  (
   parameter 	NUMERATOR_WIDTH = 10,
   parameter 	DENOMINATOR_WIDTH = 10,
   parameter 	QUOTIENT_WIDTH = 10 
   )
   (
    input 				      clk,
    input 				      reset,
    input signed [NUMERATOR_WIDTH - 1:0]      numerator_in,
    input [DENOMINATOR_WIDTH - 1:0] 	      denominator_in,
    input 				      valid_in,
    output signed [QUOTIENT_WIDTH - 1:0]      quotient_out,
    output signed [NUMERATOR_WIDTH - 1:0]     remainder_out,
    output 				      valid_out,
    output signed [NUMERATOR_WIDTH - 1 + 1:0] numerator_out,
    output [DENOMINATOR_WIDTH - 1:0] 	      denominator_out
    );

   localparam LATENCY = NUMERATOR_WIDTH;

   reg signed [LATENCY - 1 + 1:0] 	      numerator [LATENCY - 1:0];
   reg [DENOMINATOR_WIDTH - 1:0] 	      denominator [LATENCY - 1:0];
   reg [QUOTIENT_WIDTH - 1:0] 		      quotient [LATENCY - 1:0];
   reg [NUMERATOR_WIDTH - 1:0] 		      remainder [LATENCY - 1:0];
   reg 					      valid [LATENCY - 1:0];
   reg [LATENCY - 1:0] 			      numerator_negative;

   wire [LATENCY - 1:0] 		      remainder_next [LATENCY - 1:0];

   assign quotient_out = numerator_negative[LATENCY - 1] ? -quotient[LATENCY - 1] : quotient[LATENCY - 1];
   assign remainder_out = numerator_negative[LATENCY - 1] ? -remainder[LATENCY - 1] : remainder[LATENCY - 1];
   assign valid_out = valid[LATENCY - 1];

   assign numerator_out = numerator_negative[LATENCY - 1] ? -numerator[LATENCY - 1] : numerator[LATENCY - 1];
   assign denominator_out = denominator[LATENCY - 1];

   genvar 				      i;

   generate
      for (i = 0; i < LATENCY; i = i + 1)
	begin
	   assign remainder_next[i] = i > 0 ? (remainder[i - 1] << 1) | numerator[i - 1][LATENCY - i - 1] : 0;

	   always @(posedge clk)
	     if (reset)
	       begin
		  quotient[i] <= 0;
		  remainder[i] <= 0;
		  denominator[i] <= 0;
		  numerator[i] <= 0;
		  numerator_negative[i] <= 0;
		  valid[i] <= 0;
	       end
	     else
	       if (i == 0)
		 begin
		    quotient[i] <= 0;
		    remainder[i] <= 0;
		    denominator[i] <= denominator_in;
		    numerator[i] <= numerator_in < 0 ? -numerator_in : numerator_in;
		    numerator_negative[i] <= numerator_in < 0;
		    valid[i] <= valid_in;
		 end
	       else
		 begin
		    if (remainder_next[i] >= denominator[i - 1])
		      begin
			 remainder[i] <= remainder_next[i] - denominator[i - 1];
			 quotient[i] <= quotient[i - 1] | (1 << LATENCY - i - 1);
		      end
		    else
		      begin
			 remainder[i] <= remainder_next[i];
			 quotient[i] <= quotient[i - 1];
		      end
		    denominator[i] <= denominator[i - 1];
		    numerator[i] <= numerator[i - 1];
		    numerator_negative[i] <= numerator_negative[i - 1];
		    valid[i] <= valid[i - 1];
		 end
	end
   endgenerate

endmodule
