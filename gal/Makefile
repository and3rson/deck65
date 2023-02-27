SOURCES = $(wildcard src/*.pld)
OBJECTS = $(SOURCES:.pld=.jed) $(SOURCES:.pld=.hex)

all: $(OBJECTS)

src/%.jed: src/%.pld bin/galasm
	bin/galasm -v $<

src/%.hex: src/%.jed
	./src/jedec2hex.py -i $< -o $@

bin/galasm: galasm/src/*
	mkdir -p bin
	make -C ./galasm/src TARGET=../../bin/galasm

.PHONY: clean
clean:
	rm -f bin/*
	rm -f src/*.jed src/*.fus src/*.chp src/*.pin src/*.hex
	make -C ./galasm/src clean
