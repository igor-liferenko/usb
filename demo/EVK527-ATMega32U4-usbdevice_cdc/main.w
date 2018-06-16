@* Intro. This embedded application source code illustrates how to implement a CDC application
with the ATmega32U4 controller.

This application will enumerate as a CDC (communication device class) virtual COM port.
The application can be used as a USB to serial converter.

Changes: now does not allow to send data before end enumeration AND open port detection.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3}
(use \.{http://www.engbedded.com/fusecalc}).

@ The main function first performs the initialization of a scheduler module and then runs it in
an infinite loop.
The scheduler is a simple infinite loop calling all its tasks defined in the \.{conf\_scheduler.h}
file. No real time schedule is performed, when a task ends, the scheduler calls the next task
defined in the configuration file (\.{conf\_scheduler.h}).

The sample dual role application is based on two different tasks:
\item{-} The |usb_task| (\.{usb\_task.c} associated source file), is the task performing the USB
  low level enumeration process in device mode.
\item{-} The |cdc_task| performs the loop back application between USB and USART interfaces.

@c
#include "config.h"
#include "modules/scheduler/scheduler.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/usb/usb_drv.h"
#include "modules/usb/device_chap9/usb_device_task.h"
#include "modules/usb/usb_task.h"
#include "modules/usb/device_chap9/usb_standard_request.h"

extern U8    usb_configuration_nb;

int main(void)
{
   UHWCON |= (1<<UVREGE); /* enable internal USB pads regulator */
  sei();
  @#
  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1<<VBUS))) ; /* wait until VBUS line detects power from host */
  @#
  USBCON |= 1 << USBE; /* enable usb controller */


   PLLFRQ &= ~((1<<PDIV3)| (1<<PDIV2) | (1<<PDIV1)| (1<<PDIV0));
   PLLFRQ |= 1<<PDIV2;
   PLLCSR = (1<<PINDIV) | (1<<PLLE);
   while (!(PLLCSR & (1<<PLOCK))) ;
   Usb_unfreeze_clock();

   Usb_enable_reset_interrupt();
   Usb_attach();

   while (1) {
         @<USB device task@>@;
         cdc_task();
   }
   return 0;
}

@ This is the entry point of the USB management. Each USB
event is checked here in order to launch the appropriate action.
If a Setup request occurs on the Default Control Endpoint,
the usb_process_request() function is call in the usb_standard_request.c file

@<USB device task@>=
if (Is_usb_event(EVT_USB_RESET)) {
  Usb_ack_event(EVT_USB_RESET);
  Usb_reset_endpoint(0);
  usb_configuration_nb=0;
}

// Here connection to the device enumeration process
Usb_select_endpoint(EP_CONTROL);
if (Is_usb_receive_setup()) {
  usb_process_request();
}
