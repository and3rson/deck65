CPU := 65c02
ASM_SRC = $(shell find src -name '*.s')
C_SRC = $(shell find src -name '*.c')
OBJ = $(foreach x, $(basename $(ASM_SRC)), $(x).s.o) $(foreach x, $(basename $(C_SRC)), $(x).c.o)
# OBJ = $(patsubst %.c,%.o,$(ASM_SRC)) $(patsubst %.s,%.o,$(C_SRC))

all: rom.bin api.lib program
# all: rom.bin rom_sim65.bin

# rom.bin: $(SRC) rom.cfg Makefile
# 	ca65 --cpu $(CPU) -g ./src/rom.s -l rom.lst -o ./rom.o
# 	cl65 -c --cpu $(CPU) ./src/kore/drivers/sdcard2.c
# 	ld65 -C rom.cfg -o rom.bin -m rom.map ./rom.o ./src/kore/drivers/sdcard2.o
# 	# ld65 -C rom.cfg -o rom.bin -m rom.map ./rom.o
# 	ar65 r rom.lib rom.o ./src/kore/drivers/sdcard2.o

program:
	minipro -p W27C512@DIP28 -w rom.bin -S

rom.bin: Makefile rom.cfg $(OBJ)
	mkdir -p gen
	# cl65 -t none -C rom.cfg -o rom.bin -m rom.map $(OBJ)
	ld65 -C rom.cfg -o rom.bin -m rom.map $(OBJ) -Ln gen/labels.lst
	# ar65 r rom.lib $(OBJ)

api.lib: rom.bin
	cat gen/labels.lst | sed -E 's/[[:alpha:]]+\s([[:alpha:][:digit:]]+)\s\.(.*)/.export \2 = $$\1/g' > gen/api.s
	ca65 --cpu $(CPU) gen/api.s -o gen/api.o
	ar65 r api.lib gen/api.o

%.s.o: %.s
	ca65 --cpu $(CPU) --feature string_escapes $< -o $@

%.c.o: %.c
	cl65 -t none -c --cpu $(CPU) -I ./include $<
	mv $(patsubst %.c.o,%.o,$@) $@

# rom_sim65.bin: src/*.s rom.cfg Makefile
# 	true
# 	# cl65 --target sim65c02 -g ./src/rom.s -o ./rom_sim65.bin

.PHONY: clean
clean:
	rm -rf *.o *.bin *.lst *.map *.lib gen
	find . -name '*.o' -exec rm {} \;

.PHONY: run
run:
	x64 -kernal rom.bin -nativemonitor

.PHONY: run-sim65
run-sim65:
	sim65 -vvvvvv --cycles rom_sim65.bin
