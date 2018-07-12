##############################################################################
# Generic Makefile for following parts AT90USBx ATMegaxUx
###############################################################################

OUTPUT = default

# General Flags
TARGET = $(PROJECT).elf
CC = avr-gcc
MAKECFG   = config.mk

# Options common to compile, link and assembly rules
COMMON = -mmcu=$(MCU)

# Compile options common for all C compilation units.
CFLAGS = $(COMMON)
CFLAGS += -Wall -gdwarf-2 -Os -fsigned-char -ffunction-sections -ffunction-sections
CFLAGS += -MD -MP -MT $(OUTPUT)/$(*F).o -MF $(OUTPUT)/dep/$(@F).d 

# Assembly specific flags
ASMFLAGS = $(COMMON)
ASMFLAGS += -x assembler-with-cpp -Wa,-gdwarf2

# Linker flags
LDFLAGS = $(COMMON)
LDFLAGS += -Wl,-Map=$(PROJECT).map,--cref,--gc-sections,--relax

# Intel Hex file production flags
HEX_FLASH_FLAGS = -R .eeprom

# Eeprom file production flags
HEX_EEPROM_FLAGS = -j .eeprom
HEX_EEPROM_FLAGS += --set-section-flags=.eeprom="alloc,load"
HEX_EEPROM_FLAGS += --change-section-lma .eeprom=0

# Include Directories
INCLUDES = -I"./.." -I"../conf" -I"../../.." -I"../../../../at90usb128" -I"../../../../common" 

# Include Source files list and part informations
include $(MAKECFG)


## Build
.PHONY: all
all: $(TARGET) $(PROJECT).hex size

## Clean target
.PHONY: clean
clean:
	@echo "Clean project"
	@-rm -rf $(OUTPUT)/dep/* $(OUTPUT)/* $(PROJECT).elf $(PROJECT).hex $(PROJECT).eep $(PROJECT).map

## Rebuild the project.
.PHONY: rebuild
rebuild: clean all


## Compile

# Create objects files list with sources files
OBJECTS  = $(CSRCS:.c=.o) $(ASSRCS:.s=.o)

.PHONY: objfiles
objfiles: $(OBJECTS)

# create object files from C source files.
%.o: %.w
	@echo 'Building file: $<'
	@$(shell mkdir $(OUTPUT) 2>/dev/null)
	@$(shell mkdir $(OUTPUT)/dep 2>/dev/null)
	@ctangle $< - $(@D)/$(*F).c >/dev/null
	@$(CC) $(INCLUDES) $(CFLAGS) -c $(@D)/$(*F).c -o $(OUTPUT)/$(@F)
	
# Preprocess & assemble: create object files from assembler source files.
%.o: %.s
	@echo 'Building file: $<'
	@$(shell mkdir $(OUTPUT) 2>/dev/null)
	@$(shell mkdir $(OUTPUT)/dep 2>/dev/null)
	@$(CC) $(INCLUDES) $(ASMFLAGS) -c $< -o $(OUTPUT)/$(@F)


## Link
$(TARGET): $(OBJECTS)
	@echo "Linking"
	@$(CC) $(LDFLAGS) $(addprefix $(OUTPUT)/,$(notdir $(OBJECTS))) $(LINKONLYOBJECTS) $(LIBDIRS) $(LIBS) -o $(TARGET)

%.hex: $(TARGET)
	@echo "Create hex file"
	@avr-objcopy -O ihex $(HEX_FLASH_FLAGS)  $< $@

%.eep: $(TARGET)
	@echo "Create eep file"
	@avr-objcopy $(HEX_EEPROM_FLAGS) -O ihex $< $@  || exit 0

%.lss: $(TARGET)
	@echo "Create lss file"
	@avr-objdump -h -S $< > $@

size: ${TARGET}
	@avr-size -C --mcu=${MCU} ${TARGET}

test:
	avr-gcc -mmcu=$(MCU) -g -Os -o $@.elf $@.c
	avr-objdump -d $@.elf >x
	avr-objcopy -O ihex $@.elf $@.hex

flash:
	avrdude -c usbasp -p atmega32u4 -U flash:w:test.hex

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
