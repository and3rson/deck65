CPU := 65c02

hello.bin:
	ca65 --cpu $(CPU) ./src/hello.s
	ld65 -t none ./src/hello.o -o ./src/hello.bin
