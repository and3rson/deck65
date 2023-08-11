BIN = ./.pio/build/atmega328p/firmware.hex

$(BIN): src/*
	pio run

# .PHONY: upload
# upload: $(BIN)
# 	pio run -t upload

.PHONY: program
program: $(BIN)
	minipro -p ATMEGA328P@DIP28 -w $(BIN)
	make fuses-write

.PHONY: fuses-write
fuses-write:
	minipro -p ATMEGA328P@DIP28 -c config -w fuses.conf -e

.PHONY: fuses-read
fuses-read:
	minipro -p ATMEGA328P@DIP28 -r atmega328p

.PHONY: clean
clean:
	rm -rf .pio/build/

.PHONY: compile_commands.json
compile_commands.json:
	pio run -t compiledb
