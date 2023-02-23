CPU := 65c02

rom.bin: src/*.s rom.cfg
	ca65 --cpu $(CPU) -g ./src/rom.s -o ./rom.o
	ld65 -C rom.cfg -o rom.bin ./rom.o

.PHONY: clean
clean:
	rm -f *.o *.bin

.PHONY: run
run:
	x64 -kernal rom.bin -nativemonitor
