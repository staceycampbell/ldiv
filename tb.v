module tb ();

   localparam TB_TICKS = 2000;
   localparam NUMERATOR_WIDTH = 14;
   localparam DENOMINATOR_WIDTH = 11;
   localparam QUOTIENT_WIDTH = NUMERATOR_WIDTH;

   reg 				 valid_in;
   reg [15:0] 			 t;
   reg 				 go;
   reg 				 clk;
   reg signed [NUMERATOR_WIDTH - 1:0] rnd_num; 	      
   reg [DENOMINATOR_WIDTH - 1:0]      rnd_dem;
   reg signed [NUMERATOR_WIDTH - 1:0] numerator;
   reg [DENOMINATOR_WIDTH - 1:0]      denominator;
   
   wire signed [QUOTIENT_WIDTH - 1:0] quotient_out;
   wire signed [NUMERATOR_WIDTH - 1:0] remainder_out;
   wire 			       valid_out;
   wire signed [NUMERATOR_WIDTH - 1 + 1:0] numerator_out;
   wire [DENOMINATOR_WIDTH - 1:0] 	   denominator_out;
   
   wire 				   pass = numerator_out / $signed({1'b0, denominator_out}) == quotient_out && numerator_out % $signed({1'b0, denominator_out}) == remainder_out;
   wire 				   reset = t < 4;

   integer 				   idx;

   initial
     begin
	$dumpfile("ldiv.vcd");
	$dumpvars(0, tb);
	for (idx = 0; idx < NUMERATOR_WIDTH; idx = idx + 1)
	  begin
	     $dumpvars(0, ldiv.numerator[idx]);
	     $dumpvars(0, ldiv.denominator[idx]);
	     $dumpvars(0, ldiv.quotient[idx]);
	     $dumpvars(0, ldiv.remainder[idx]);
	     $dumpvars(0, ldiv.valid[idx]);
	     $dumpvars(0, ldiv.remainder_next[idx]);
	  end
	clk = 0;
	for (t = 0 ; t < TB_TICKS;  t = t + 1)
	  #1 clk = ~clk;
	$display("Done.");
	$finish;
     end // initial begin

   always @(posedge clk)
     begin
	rnd_num <= $random + ($random << 32);
	rnd_dem <= $random & 1 ? $random + ($random << 32) : $random >>> 24;
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
       end // else: !if(reset)
   
   always @(posedge clk)
     if (valid_out)
       begin
	  $display("%d / %d = %d, %d %% %d = %d: %s", numerator_out, denominator_out, quotient_out, numerator_out, denominator_out, remainder_out, pass ? "PASS" : "FAIL");
	  if (! pass)
	    #1 $finish();
       end
   
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
      .quotient_out(quotient_out),
      .remainder_out(remainder_out),
      .valid_out(valid_out),
      .numerator_out(numerator_out),
      .denominator_out(denominator_out)
      );
   
endmodule
