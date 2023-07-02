run: 1.bin
	sim65 --verbose 1.bin

1.bin: 1.s
	cl65 --target sim6502 1.s -o 1.bin

clean:
	rm -f *.o *.bin
