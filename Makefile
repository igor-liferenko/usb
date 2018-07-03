all:
	avr-gcc -mmcu=atmega32u4 -g -o asm.elf asm.S
	avr-objcopy -O ihex asm.elf asm.hex
	avr-objdump -S asm.elf >x

flash:
	avrdude -c usbasp -p atmega32u4 -U flash:w:asm.hex
