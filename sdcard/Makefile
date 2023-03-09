all:
	false

format:
	# Partition must be 32 MB
	sudo mkfs.vfat -F 16 /dev/sda1 -R 1 -S 512 -f 1 -s 1 -g 1/1 -h 0 -r 16
	sudo mount /dev/sda1 /mnt/1
	echo 'This is file zero' | sudo tee /mnt/1/0_zero.txt
	echo 'This is file one' | sudo tee /mnt/1/1_one.txt
	echo 'This is file two' | sudo tee /mnt/1/2_two.txt
	echo 'This is file three' | sudo tee /mnt/1/3_three.txt
	sudo umount /mnt/1
	sync
