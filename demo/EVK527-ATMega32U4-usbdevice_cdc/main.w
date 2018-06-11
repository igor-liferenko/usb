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
   usb_device_task_init(); /* enable the USB controller and init the USB interrupts;
     the aim is to allow the USB connection detection in order to send
     the appropriate USB event to the operating mode manager */
   while (1) {
         @<USB device task@>@;
         cdc_task();
   }
   return 0;
}

@ This function is the entry point of the USB management. Each USB
event is checked here in order to launch the appropriate action.
If a Setup request occurs on the Default Control Endpoint,
the usb_process_request() function is call in the usb_standard_request.c file

@<USB device task@>=
/*use PC7 to check if these checks are needed, and compare procedure here with usbttl/ */
   if (usb_connected == FALSE) {
     if (Is_usb_vbus_high()) {    // check if Vbus ON to attach
       Usb_enable();
       usb_connected = TRUE;
       usb_start_device();
     }
   }

   if(Is_usb_event(EVT_USB_RESET))
   {
      Usb_ack_event(EVT_USB_RESET);
      Usb_reset_endpoint(0);
      usb_configuration_nb=0;
   }

   // Here connection to the device enumeration process
   Usb_select_endpoint(EP_CONTROL);
   if (Is_usb_receive_setup())
   {
      usb_process_request();
   }
