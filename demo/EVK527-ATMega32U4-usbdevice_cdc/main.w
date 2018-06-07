@* Intro. This embedded application source code illustrates how to implement a CDC application
with the ATmega32U4 controller.

This application will enumerate as a CDC (communication device class) virtual COM port.
The application can be used as a USB to serial converter.

Changes: now does not allow to send data before end enumeration AND open port detection.

@ The main function first performs the initialization of a scheduler module and then runs it in
an infinite loop.
The scheduler is a simple infinite loop calling all its tasks defined in the conf_scheduler.h file.
No real time schedule is performed, when a task ends, the scheduler calls the next task defined in
the configuration file (\.{conf\_scheduler.h}).

The sample dual role application is based on two different tasks:
\item{-} The |usb_task| (\.{usb\_task.c} associated source file), is the task performing the USB
  low level enumeration process in device mode.
\item{-} The |cdc_task| performs the loop back application between USB and USART interfaces.

@c
#include "config.h"
#include "modules/scheduler/scheduler.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/usb/usb_drv.h"

int main(void)
{
   UHWCON |= (1<<UVREGE); /* enable internal USB pads regulator */
  DDRC |= 1<<PC7;
  if (WDTCSR & (1<<WDE)) PORTC |= 1<<PC7; /* check that this does not happen and remove and add
    result to WDT.README */
   Clear_prescaler();
   scheduler();
   return 0;
}

@ Procedure to speed up the startup code
This one increment the CPU clock before RAM initialisation
Locate low level init function before RAM init (init3 section)
and remove std prologue/epilogue

@c
char __low_level_init(void) __attribute__ ((section (".init3"),naked));
char __low_level_init()
{
  Clear_prescaler();
  return 1;
}
