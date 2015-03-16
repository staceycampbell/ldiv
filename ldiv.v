module ldiv #
  (
   parameter 	NUMERATOR_WIDTH = 10,
   parameter 	DENOMINATOR_WIDTH = 10,
   parameter 	QUOTIENT_WIDTH = 10 
   )
   (
    input 				  clk,
    input 				  reset,
    input signed [NUMERATOR_WIDTH - 1:0]  numerator_in,
    input [DENOMINATOR_WIDTH - 1:0] 	  denominator_in,
    input 				  valid_in,
    output signed [QUOTIENT_WIDTH - 1:0]  quotient_out,
    output signed [NUMERATOR_WIDTH - 1:0] remainder_out,
    output 				  valid_out
    );

   localparam LATENCY = NUMERATOR_WIDTH;

   reg signed [LATENCY - 1 + 1:0] 	  numerator [LATENCY - 1:0];
   reg [DENOMINATOR_WIDTH - 1:0] 	  denominator [LATENCY - 1:0];
   reg [QUOTIENT_WIDTH - 1:0] 		  quotient [LATENCY - 1:0];
   reg [NUMERATOR_WIDTH - 1:0] 		  remainder [LATENCY - 1:0];
   reg 					  valid [LATENCY - 1:0];
   reg [LATENCY - 1:0] 			  numerator_negative;

   wire [LATENCY - 1:0] 		  remainder_next [LATENCY - 1:0];

   wire signed [NUMERATOR_WIDTH - 1 + 1:0] numerator_out;
   wire [DENOMINATOR_WIDTH - 1:0] 	   denominator_out;

   assign quotient_out = numerator_negative[LATENCY - 1] ? -quotient[LATENCY - 1] : quotient[LATENCY - 1];
   assign remainder_out = numerator_negative[LATENCY - 1] ? -remainder[LATENCY - 1] : remainder[LATENCY - 1];
   assign valid_out = valid[LATENCY - 1];

   assign numerator_out = numerator_negative[LATENCY - 1] ? -numerator[LATENCY - 1] : numerator[LATENCY - 1];
   assign denominator_out = denominator[LATENCY - 1];

   genvar 				   i;

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

   wire pass = numerator_out / $signed({1'b0, denominator_out}) == quotient_out && numerator_out % $signed({1'b0, denominator_out}) == remainder_out;

   always @(posedge clk)
     if (valid_out)
       begin
	  $display("%d / %d = %d, %d %% %d = %d: %s", numerator_out, denominator_out, quotient_out, numerator_out, denominator_out, remainder_out, pass ? "PASS" : "FAIL");
	  if (! pass)
	    #1 $finish();
       end

endmodule

module main ();

   localparam TB_TICKS = 500;
   localparam NUMERATOR_WIDTH = 24;
   localparam DENOMINATOR_WIDTH = 24;
   localparam QUOTIENT_WIDTH = NUMERATOR_WIDTH;

   reg 				 valid_in;
   reg [15:0] 			 t;
   reg 				 go;
   reg 				 clk;
   reg signed [NUMERATOR_WIDTH - 1:0] rnd_num; 	      
   reg [DENOMINATOR_WIDTH - 1:0]      rnd_dem;
   reg signed [NUMERATOR_WIDTH - 1:0] numerator;
   reg [DENOMINATOR_WIDTH - 1:0]      denominator;
   
   wire signed [QUOTIENT_WIDTH - 1:0] quotient;
   wire signed [NUMERATOR_WIDTH - 1:0] remainder;
   wire 			       valid_out;
   wire 			       reset = t < 4;
   
   ldiv #
     (
      .NUMERATOR_WIDTH(NUMERATOR_WIDTH),
      .DENOMINATOR_WIDTH(DENOMINATOR_WIDTH),
      .QUOTIENT_WIDTH(QUOTIENT_WIDTH)
      )
   ldiv
     (
      .clk(clk),
      .reset(reset),
      .numerator_in(numerator),
      .denominator_in(denominator),
      .valid_in(valid_in),
      .quotient_out(quotient),
      .remainder_out(remainder),
      .valid_out(valid_out)
      );

   initial
     begin
	if (TB_TICKS <= 5000) // keep wavefile data under control
	  begin
	     $dumpfile("ldiv.vcd");
	     $dumpvars(0, main);
	  end
	else
	  $display("Too much data for wavefile. Not creating.");
	clk = 0;
	for (t = 0 ; t < TB_TICKS;  t = t + 1)
	  begin
	     #1 clk = 1;
	     #1 clk = 0;
	  end
	$display("Done.");
	$finish;
     end // initial begin

   always @(posedge clk)
     begin
	rnd_num <= $random + ($random << 32);
	rnd_dem <= $random + ($random << 32);
     end

   always @(posedge clk)
     if (reset)
       begin
	  numerator <= 0;
	  denominator <= 0;
	  valid_in <= 0;
	  go <= 1;
       end
     else
       begin
	  numerator <= rnd_num;
	  denominator <= rnd_dem ? rnd_dem : 3;
	  if (go && ~valid_in)
	    begin
	       go <= 0;
	       valid_in <= 1;
	    end
       end
   
endmodule
