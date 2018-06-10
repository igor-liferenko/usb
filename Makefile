all:
	make -C demo/EVK527-ATMega32U4-usbdevice_cdc/gcc/

flash:
	avrdude -c usbasp -p m32u4 -U flash:w:cdc.hex
