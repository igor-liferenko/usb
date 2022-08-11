all:
	@echo NoOp

%:
	@avr-gcc -mmcu=atmega32u4 -DF_CPU=16000000UL -g -Os -o fw.elf $@.c
	@avr-objcopy -O ihex fw.elf fw.hex

dump:
	@avr-objdump -d fw.elf

flash:
	@avrdude -qq -c usbasp -p atmega32u4 -U efuse:v:0xcb:m -U hfuse:v:0xd9:m -U lfuse:v:0xff:m -U flash:w:fw.hex

clean:
	@git clean -X -d -f

eps:
	@inkscape --export-type=eps --export-ps-level=2 --export-filename=usb.eps --export-text-to-path usb.svg
	@make --no-print-directory `grep -o '^\S*\.eps' Makefile`

test:
	@grep -q '^@c$$' test.w || ( echo 'NO SECTION ENABLED'; false )
	@grep '^@c$$' test.w | wc -l | grep -q '^1$$' || ( echo 'MORE THAN ONE SECTION ENABLED'; false )
	@avr-gcc -mmcu=atmega32u4 -g -Os -o fw.elf test.c
	@avr-objcopy -O ihex fw.elf fw.hex

asm:
	avr-gcc -mmcu=atmega32u4 -g -o asm.elf asm.S
	@avr-objdump -S asm.elf >x
	avr-objcopy -O ihex asm.elf fw.hex

.PHONY: $(wildcard *.eps)

control-IN.eps:
	@convert control-IN.png eps2:$@

control-OUT.eps:
	@convert control-OUT.png eps2:$@

direction.eps:
	@convert direction.gif eps2:$@

control-read-stages.eps:
	@convert control-read-stages.gif eps2:$@

control-write-stages.eps:
	@convert control-write-stages.png eps2:$@

transaction-IN.eps:
	@convert transaction-IN.gif eps2:$@

transaction-OUT.eps:
	@convert transaction-OUT.gif eps2:$@

transaction-SETUP.eps:
	@convert transaction-SETUP.gif eps2:$@

IN.eps:
	@convert IN.png eps2:$@

OUT.eps:
	@convert OUT.png eps2:$@

stall-control-read-with-data-stage.eps:
	@convert stall-control-read-with-data-stage.png eps2:$@
