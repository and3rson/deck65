lcd.bin: bin/galasm
	bin/galasm ./src/lcd.pld

bin/galasm:
	mkdir -p bin
	make -C ./galasm/src/ TARGET=../../bin/galasm
