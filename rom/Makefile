rom.bin: src/*.s rom.cfg
	ca65 -g ./src/rom.s
	ld65 -C rom.cfg -o rom.bin ./rom.o

.PHONY: clean
clean:
	rm -f *.o *.bin

.PHONY: run
run:
	x64 -kernal rom.bin -nativemonitor
