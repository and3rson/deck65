SOURCES = $(wildcard src/*.pld)
OBJECTS = $(SOURCES:.pld=.jed) $(SOURCES:.pld=.hex)
TOML_TESTS = $(wildcard src/*.toml)
LGC_TESTS = $(TOML_TESTS:.toml=.lgc)

all: xgpro-logic/xgpro-logic $(OBJECTS) $(LGC_TESTS)

xgpro-logic/xgpro-logic:
	cd xgpro-logic && go mod tidy && (go get || true) && go build -o xgpro-logic cmd/xgpro-logic.app/main.go

src/%.jed: src/%.pld bin/galasm
	bin/galasm -c -p -f -v $<

src/%.hex: src/%.jed
	./src/jedec2hex.py -i $< -o $@

src/%.lgc: src/%.toml
	./xgpro-logic/xgpro-logic lgc $< $@

bin/galasm: galasm/src/*
	mkdir -p bin
	make -C ./galasm/src TARGET=../../bin/galasm

.PHONY: clean
clean:
	rm -f bin/*
	rm -f src/*.jed src/*.fus src/*.chp src/*.pin src/*.hex src/*.lgc
	make -C ./galasm/src clean

.PHONY: program
program: src/$(PROGRAM).jed
ifndef PROGRAM
	$(error PROGRAM is required)
endif
	minipro -p GAL20V8B -w ./src/$(PROGRAM).jed -z

.PHONY: program
program-atf16v8b: src/$(PROGRAM).jed
ifndef PROGRAM
	$(error PROGRAM is required)
endif
	minipro -p ATF16V8B -w ./src/$(PROGRAM).jed -z
