CPU := 65c02

SRC = $(wildcard src/*.c)
BIN = $(patsubst src/%.c, bin/%.bin, $(SRC))

# all: bin bin/hello.bin bin/cltest.bin bin/maze.bin bin/snake.bin bin/time.bin
all: bin bin/hello.bin $(BIN)

bin:
	mkdir bin

bin/%.bin: src/%.c ../rom/rom.lib
	cl65 -t none -C ../rom/rom.cfg --cpu $(CPU) $< ../rom/rom.lib -o $@

bin/hello.bin: ../rom/rom.cfg ../rom/rom.lib src/hello.s
	ca65 --cpu $(CPU) ./src/hello.s
	ld65 -C ../rom/rom.cfg ./src/hello.o -o bin/hello.bin ../rom/rom.lib

# bin/cltest.bin: Makefile ../rom/rom.cfg ../rom/rom.lib src/cltest.c
# 	# https://cc65.github.io/doc/intro.html#ss1.2
# 	cl65 -t none -C ../rom/rom.cfg --cpu $(CPU) ./src/cltest.c ../rom/rom.lib -o ./bin/cltest.bin -m cltest.map

# bin/maze.bin: Makefile ../rom/rom.cfg ../rom/rom.lib src/maze.c
# 	# https://cc65.github.io/doc/intro.html#ss1.2
# 	cl65 -t none -C ../rom/rom.cfg --cpu $(CPU) ./src/maze.c ../rom/rom.lib -o ./bin/maze.bin -m maze.map

# bin/snake.bin: Makefile ../rom/rom.cfg ../rom/rom.lib src/snake.c
# 	# https://cc65.github.io/doc/intro.html#ss1.2
# 	cl65 -t none -C ../rom/rom.cfg --cpu $(CPU) ./src/snake.c ../rom/rom.lib -o ./bin/snake.bin -m snake.map

# bin/time.bin: Makefile ../rom/rom.cfg ../rom/rom.lib src/time.c
# 	# https://cc65.github.io/doc/intro.html#ss1.2
# 	cl65 -t none -C ../rom/rom.cfg --cpu $(CPU) ./src/time.c ../rom/rom.lib -o ./bin/time.bin -m time.map

format:
	# Fill (part of) device with zeroes
	sudo dd if=/dev/zero of=/dev/sda bs=1M count=16
	# Create 32MB partition starting at sector 1
	# sudo parted /dev/sda -s mklabel msdos mkpart primary 1s 65537s
	# Create 32MB partition starting at sector 2048
	# sudo parted /dev/sda -s mklabel msdos mkpart primary 2048s $$((65536+2048))s
	# Create 8MB partition starting at sector 2048
	sudo parted /dev/sda -s mklabel msdos mkpart primary 2048s $$((16384+2048))s
	# Format as FAT16
	# sudo mkfs.vfat -F 16 /dev/sda1 -R 1 -S 512 -f 1 -s 1 -g 1/1 -h 0 -r 256
	# sudo mkfs.vfat -F 16 /dev/sda1  # FAT16
	sudo mkfs.vfat -F 16 -s 1 /dev/sda1  # FAT16, 1 sector per cluster

copy: all
	sudo mount /dev/sda1 /mnt/1 -o fat=16
	sudo rm -rf /mnt/1/*
	cat file1.txt | sudo tee /mnt/1/file1.txt
	# for i in `seq 2 50`; do echo "This is file $$i" | sudo tee /mnt/1/file$${i}.txt; done
	sudo cp ./bin/*.bin /mnt/1/
	sudo umount /mnt/1
	sync

.PHONY: clean
clean:
	rm -rf bin src/*.o
