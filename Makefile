ldiv.vcd: ldiv
	ldiv

ldiv: ldiv.v tb.v
	iverilog -o ldiv tb.v ldiv.v

clean:
	rm -f ldiv ldiv.vcd
