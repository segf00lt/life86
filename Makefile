all:
	$(shell nasm -f elf64 -g -F dwarf life86.asm && gcc -no-pie -o life86 life86.o && rm life86.o)
.PHONY: all
