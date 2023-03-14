all:
	false

format:
	# Fill (part of) device with zeroes
	sudo dd if=/dev/zero of=/dev/sda bs=1M count=16
	# Create 32MB partition starting at sector 1
	# sudo parted /dev/sda -s mklabel msdos mkpart primary 1s 65537s
	sudo parted /dev/sda -s mklabel msdos mkpart primary 2048s $$((65536+2048))s
	# Format as FAT16
	# sudo mkfs.vfat -F 16 /dev/sda1 -R 1 -S 512 -f 1 -s 1 -g 1/1 -h 0 -r 256
	sudo mkfs.vfat -F 16 /dev/sda1
	sudo mount /dev/sda1 /mnt/1 -o fat=16
	echo 'This is file zero' | sudo tee /mnt/1/0_zero.txt
	echo 'This is file one' | sudo tee /mnt/1/1_one.txt
	echo 'This is file two' | sudo tee /mnt/1/2_two.txt
	echo 'This is file three' | sudo tee /mnt/1/3_three.txt
	sudo umount /mnt/1
	sync
