CPU := 65c02

all: rom.bin rom_sim65.bin

rom.bin: src/*.s rom.cfg Makefile
	ca65 --cpu $(CPU) -g ./src/rom.s -o ./rom.o
	# ld65 -C rom.cfg -o rom.bin ./rom.o
	ld65 -C rom.cfg -o rom.bin ./rom.o

rom_sim65.bin: src/*.s rom.cfg Makefile
	cl65 --target sim65c02 --cpu $(CPU) -g ./src/rom.s -o ./rom_sim65.bin

.PHONY: clean
clean:
	rm -f *.o *.bin

.PHONY: run
run:
	x64 -kernal rom.bin -nativemonitor

.PHONY: run-sim65
run-sim65:
	sim65 rom_sim65.bin
