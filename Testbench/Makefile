all: clean comp
comp:
	iverilog -Winfloop -DTESTBENCH -o test.o -s test -I../include ./soktb.v ../CPU/*.v ../Memories/*.v ../*.v
	echo finish | vvp test.o > output.txt
	gtkwave gtkw.gtkw 2>/dev/null
clean:
	rm -f test.o ZSOC.vcd output.txt
