bin/main.hex: bin src/*
	avra ./src/main.asm -l main.lst -o ./bin/main.hex -e ./bin/main.eep.hex
	avr-objdump -D -m avr25 bin/main.hex

bin:
	mkdir bin

.PHONY: flash
flash: bin/main.hex
	minipro -p ATTINY45@DIP8 -w ./bin/main.hex

.PHONY: clean
clean:
	find . -regex '.*\.\(o\|obj\|hex\|bin\|lst\|map\)' -exec rm {} \;
