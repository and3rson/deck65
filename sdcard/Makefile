CPU := 65c02

all: bin bin/hello.bin bin/ctest.bin

bin:
	mkdir bin

bin/hello.bin: src/hello.s
	ca65 --cpu $(CPU) ./src/hello.s
	ld65 -C ../rom/rom.cfg ./src/hello.o -o bin/hello.bin --lib ../rom/rom.lib

bin/ctest.bin: src/ctest.c
	# https://cc65.github.io/doc/intro.html#ss1.2
	cc65 --cpu $(CPU) ./src/ctest.c --inline-stdfuncs -T
	cat ./src/loader.s ./src/ctest.s | tee ./src/ctest.s > /dev/null
	ca65 --cpu $(CPU) ./src/ctest.s
	ld65 -C ../rom/rom.cfg ./src/ctest.o -o bin/ctest.bin --lib ../rom/rom.lib

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

copy:
	sudo mount /dev/sda1 /mnt/1 -o fat=16
	sudo rm -rf /mnt/1/*
	cat file1.txt | sudo tee /mnt/1/file1.txt
	# for i in `seq 2 50`; do echo "This is file $$i" | sudo tee /mnt/1/file$${i}.txt; done
	sudo cp ./bin/hello.bin /mnt/1/
	sudo cp ./bin/ctest.bin /mnt/1/
	sudo umount /mnt/1
	sync

.PHONY: clean
clean:
	rm -rf bin src/*.o
