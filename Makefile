all:
	dasm *.asm -f3 -v1 -oorbit26.bin

run:
	stella orbit26.bin
