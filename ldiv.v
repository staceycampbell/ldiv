module ldiv #
  (
   parameter 	NUMERATOR_WIDTH = 10,
   parameter 	DENOMINATOR_WIDTH = 10,
   parameter 	QUOTIENT_WIDTH = 10 
   )
   (
    input 			    clk,
    input 			    resetb,
    input [NUMERATOR_WIDTH - 1:0]   numerator_in,
    input [DENOMINATOR_WIDTH - 1:0] denominator_in,
    input 			    valid_in,
    output [QUOTIENT_WIDTH - 1:0]   quotient_out,
    output [NUMERATOR_WIDTH - 1:0]  remainder_out,
    output 			    valid_out
    );

   localparam LATENCY = NUMERATOR_WIDTH + 1;

   reg [LATENCY - 1:0] 		    numerator [LATENCY - 1:0];
   reg [DENOMINATOR_WIDTH - 1:0]    denominator [LATENCY - 1:0];
   reg [QUOTIENT_WIDTH - 1:0] 	    quotient [LATENCY - 1:0];
   reg [NUMERATOR_WIDTH - 1:0] 	    remainder [LATENCY - 1:0];
   reg 				    valid [LATENCY - 1:0];

   wire [LATENCY - 1:0] 	    remainder_next [LATENCY - 1:0];

   assign quotient_out = quotient[LATENCY - 1];
   assign remainder_out = remainder[LATENCY - 1];
   assign valid_out = valid[LATENCY - 1];

   genvar 			    i;

   generate
      for (i = 0; i < LATENCY; i = i + 1)
	begin
	   assign remainder_next[i] = i > 0 ? (remainder[i - 1] << 1) | numerator[i - 1][LATENCY - i - 1] : 0;

	   always @(posedge clk or negedge resetb)
	     if (~resetb)
	       begin
		  quotient[i] <= 0;
		  remainder[i] <= 0;
		  denominator[i] <= 0;
		  numerator[i] <= 0;
		  valid[i] <= 0;
	       end
	     else
	       if (i == 0)
		 begin
		    quotient[i] <= 0;
		    remainder[i] <= 0;
		    denominator[i] <= denominator_in;
		    numerator[i] <= numerator_in;
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
		    valid[i] <= valid[i - 1];
		 end
	end
   endgenerate

   always @(posedge clk)
     if (valid[LATENCY - 1])
       $display("%d / %d = %d, %d %% %d = %d: %s", numerator[LATENCY - 1], denominator[LATENCY - 1], quotient[LATENCY - 1],
		numerator[LATENCY - 1], denominator[LATENCY - 1], remainder[LATENCY - 1],
		numerator[LATENCY - 1] / denominator[LATENCY - 1] == quotient[LATENCY - 1] &&
		numerator[LATENCY - 1] % denominator[LATENCY - 1] == remainder[LATENCY - 1] ? "PASS" : "FAIL");

endmodule

module main ();

   localparam NUMERATOR_WIDTH = 23;
   localparam DENOMINATOR_WIDTH = 15;
   localparam QUOTIENT_WIDTH = NUMERATOR_WIDTH;

   reg 				 valid_in;
   reg [15:0] 			 t;
   reg 				 go;
   reg 				 clk;
   reg [NUMERATOR_WIDTH - 1:0] 	 rnd_num; 	      
   reg [DENOMINATOR_WIDTH - 1:0] rnd_dem;
   reg [NUMERATOR_WIDTH - 1:0] 	 numerator;
   reg [DENOMINATOR_WIDTH - 1:0] denominator;
   
   wire [QUOTIENT_WIDTH - 1:0] 	 quotient;
   wire [NUMERATOR_WIDTH - 1:0]  remainder;
   wire 			 valid_out;
   wire 			 reset = t < 4;
   
   ldiv #
     (
      .NUMERATOR_WIDTH(NUMERATOR_WIDTH),
      .DENOMINATOR_WIDTH(DENOMINATOR_WIDTH),
      .QUOTIENT_WIDTH(QUOTIENT_WIDTH)
      )
   ldiv
     (
      .clk(clk),
      .resetb(~reset),
      .numerator_in(numerator),
      .denominator_in(denominator),
      .valid_in(valid_in),
      .quotient_out(quotient),
      .remainder_out(remainder),
      .valid_out(valid_out)
      );

   initial
     begin
	$dumpfile("ldiv.vcd");
	$dumpvars(0, main);
	clk = 0;
	for (t = 0 ; t < 1000;  t = t + 1)
	  begin
	     #1 clk = 1;
	     #1 clk = 0;
	  end
	$display("Done.");
	$finish;
     end // initial begin

   always @(posedge clk)
     begin
	rnd_num <= $random;
	rnd_dem <= $random;
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
