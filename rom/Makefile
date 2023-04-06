CPU := 65c02
SRC = $(shell find . -name '*.s')

all: rom.bin flash
# all: rom.bin rom_sim65.bin

rom.bin: $(SRC) rom.cfg Makefile
	ca65 --cpu $(CPU) -g ./src/rom.s -l rom.lst -o ./rom.o
	ld65 -C rom.cfg -o rom.bin -m rom.map ./rom.o

flash:
	minipro -p W27C512@DIP28 -w rom.bin -S

# rom_sim65.bin: src/*.s rom.cfg Makefile
# 	true
# 	# cl65 --target sim65c02 -g ./src/rom.s -o ./rom_sim65.bin

.PHONY: clean
clean:
	rm -f *.o *.bin *.lst *.map

.PHONY: run
run:
	x64 -kernal rom.bin -nativemonitor

.PHONY: run-sim65
run-sim65:
	sim65 -vvvvvv --cycles rom_sim65.bin
