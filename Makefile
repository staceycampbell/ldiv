ldiv.vcd: ldiv
	ldiv

ldiv: ldiv.v
	iverilog -o ldiv ldiv.v

clean:
	rm -f ldiv ldiv.vcd
