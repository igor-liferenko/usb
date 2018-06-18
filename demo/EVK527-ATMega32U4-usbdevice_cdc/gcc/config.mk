
# Project name
PROJECT = EVK527-ATMega32U4-usbdevice_cdc

# CPU architecture : {avr0|...|avr6}
# Parts :
MCU = atmega32u4

# Source files
CSRCS = \
  ../uart_usb_lib.c\
  ../usb_descriptors.c\
  ../../../lib_mcu/usb/usb_drv.c\
  ../usb_specific_request.c\
  ../../../lib_mcu/power/power_drv.c\
  ../cdc_task.c\
  ../main.c\
  ../../../modules/usb/device_chap9/usb_standard_request.c\

# Assembler source files
ASSRCS = \
  ../../../lib_mcu/flash/flash_drv.s\

