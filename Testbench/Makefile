all: clean comp
comp:
	iverilog -Winfloop -DTESTBENCH -o test.o -s test -I../include ./soctb.v  ./Simulation/*.v ../CPU/*.v ../GPIO/*.v ../Memories/*.v ../screenI2C/*.v  ../BRAMS/gowin_dpb_program/*.v ../*.v ../InteruptControllers/*.v ../Buses/*.v 
	vvp test.o
	gtkwave gtkw.gtkw 2>/dev/null
clean:
	rm -f test.o ZSOC.vcd
