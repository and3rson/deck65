BIN = ./.pio/build/ATmega328P/firmware.elf

$(BIN): src/*
	pio run

.PHONY: upload
upload: $(BIN)
	pio run -t upload

.PHONY: clean
clean:
	rm -rf .pio/build/

.PHONY: compile_commands.json
compile_commands.json:
	pio run -t compiledb
