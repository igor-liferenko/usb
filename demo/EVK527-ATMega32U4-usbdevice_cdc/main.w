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
#include "modules/usb/ch9/usb_device_task.h"
#include "modules/usb/ch9/usb_standard_request.h"

#include "config.h"
#include "conf_usb.h"

extern U8    usb_configuration_nb;

@<EOR interrupt handler@>@;

volatile int connected = 0;
int main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */
  @#
  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  @#
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  @#
  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  @#
  UDCON &= ~(1 << DETACH);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!connected) {
    if (UEINTX & (1 << RXSTPI)) {
      usb_process_request();
    }
  }

//detect DTR before each operation on USB this way:
#if 1==0
prev = UENUM;
UENUM = EP0;
if (UEINTX & 1 << RXSTPI) {
  while (!<read DTR>) ;
/*process dtr here - grep SETUP\_CDC\_SET\_CONTROL\_LINE\_STATE*/
  line_status.DTR = DTR ? 1 : 0;
}
UENUM = prev;
if (line_status.DTR) ... else ...
#endif

/* http://we.easyelectronics.ru/electro-and-pc/
  interfeys-usb-realizaciya-chast-2.html */
/* http://www.usbmadesimple.co.uk/ums\_3.htm */

  while (1) { /* main application loop */
#if 1==0
  if (line_status.DTR) {
      /* send a character (see cdc\_task.w) */
    _delay_ms(1000);
  }
#endif
  }
}

@ @<EOR interrupt handler@>=
ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
//  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG0X = 0 << EPTYPE0 | 0 << EPDIR; /* control, out */
    UECFG1X = 1 << EPSIZE1 + 1 << EPSIZE0 | 0 << EPBK0 | 1 << ALLOC; /* 64 bytes, one bank */
//TODO: see operator precedence
//  }
}


@* Index.
