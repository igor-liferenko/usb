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

imgs:
	@mpost usb
	@perl -ne 'if (/^(.*\.eps): (.*)/) { system "convert $$2 $$1" }' Makefile

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

control-IN.eps: control-IN.png
	@convert $< $@
	@imgsize $@ 12.5 -

control-OUT.eps: control-OUT.png
	@convert $< $@
	@imgsize $@ 16 -

direction.eps: direction.gif
	@convert $< $@
	@imgsize $@

control-read-stages.eps: control-read-stages.gif
	@convert $< $@
	@imgsize $@

control-write-stages.eps: control-write-stages.png
	@convert $< $@
	@imgsize $@

transaction-IN.eps: transaction-IN.gif
	@convert $< $@
	@imgsize $@

transaction-OUT.eps: transaction-OUT.gif
	@convert $< $@
	@imgsize $@

transaction-SETUP.eps: transaction-SETUP.gif
	@convert $< $@
	@imgsize $@

IN.eps: IN.png
	@convert $< $@
	@imgsize $@ 14 -

OUT.eps: OUT.png
	@convert $< $@
	@imgsize $@ 16 -

stall-control-read-with-data-stage.eps: stall-control-read-with-data-stage.png
	@convert $< $@
	@imgsize $@
