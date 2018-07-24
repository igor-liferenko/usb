kbd:
	avr-gcc -mmcu=atmega32u4 -g -Os -o kbd.elf kbd.c
	@avr-objdump -S kbd.elf >x
	avr-objcopy -O ihex kbd.elf fw.hex

flash:
	avrdude -c usbasp -p atmega32u4 -U flash:w:fw.hex -q

.PHONY: test
test:
	@mv test test.c
	avr-gcc -mmcu=atmega32u4 -g -Os -o test.elf test.c
	@avr-objdump -S test.elf >x
	avr-objcopy -O ihex test.elf fw.hex

asm:
	avr-gcc -mmcu=atmega32u4 -g -o asm.elf asm.S
	@avr-objdump -S asm.elf >x
	avr-objcopy -O ihex asm.elf fw.hex

.PHONY: $(wildcard *.eps)

control-IN.eps: control-IN.png
	@convert $< $@
	@imgsize $@ 12.5 -

control-OUT.eps: control-OUT.png
	@convert $< $@
	@imgsize $@ 16 -

direction.eps: direction.gif
	@convert $< $@
	@imgsize $@ 6 -

control-read-stages.eps: control-read-stages.gif
	@convert $< $@
	@imgsize $@ 10 -

control-write-stages.eps: control-write-stages.png
	@convert $< $@
	@imgsize $@ 10 -

transaction-IN.eps: transaction-IN.gif
	@convert $< $@
	@imgsize $@

transaction-OUT.eps: transaction-OUT.gif
	@convert $< $@
	@imgsize $@

transaction-SETUP.eps: transaction-SETUP.gif
	@convert $< $@
	@imgsize $@

hid-structure.eps: hid-structure.png
	@convert $< $@
	@imgsize $@ 5 -

kbd-structure.eps: kbd-structure.png
	@convert $< $@
	@imgsize $@ 5 -
