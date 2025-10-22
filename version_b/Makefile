all: clean comp
comp:
	iverilog -g2012 -Winfloop -o test.o ./*.v
	vvp test.o
	./surfer soc.vcd --state-file ./test/surf.ron
clean:
	rm -f soc.vcd test.o
