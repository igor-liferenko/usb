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
#include "modules/usb/device_chap9/usb_standard_request.h"

#include "config.h"
#include "conf_usb.h"

extern U8    usb_configuration_nb;

@<EOR interrupt handler@>@;

void main(void)
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
  sei();
  UDIEN |= 1 << EORSTE;
  UDCON &= ~(1 << DETACH);

  while (1) {
    @<Check for a setup packet@>@;
    cdc_task();
  }
}

@ @<Check for a setup packet@>=
UENUM = 0;
if (UEINTX & (1 << RXSTPI)) {
  usb_process_request();
}

@ При обнаружении на линии состояния ``Сброс'' устройство должно перейти в исходное состояние
(Default state). На практике, нам нужно присвоить устройству ``нулевой'' адрес и подготовить
``нулевую контрольную точку'' к приему и обработке стандартных USB запросов от хоста. Хост
всегда выставляет ``Сброс'' на шине сразу после того, как определит подключение устройства. До
``сброса'' устройство не должно передавать какие-либо данные в т. ч. в ответ на запрос по адресу
0 (благодаря этому, как я понимаю, решается проблема коллизии, возникающей в случае одновременного
подключения к хосту нескольких новых устройств).

EPEN is necessary because without it RXSTPI flag will not be set when first setup packet
arrives.
But EPEN will have no effect if ALLOC is not done (either before attach of in eor handler - todo:
check if trace of these two cases differs in wireshark).
EPEN can only be enabled in eor handler.
also check if wireshark trace differs if epsize is set before alloc before attach with when it is
not set
and with when it is set before alloc in eor handler

@<EOR interrupt handler@>=
ISR(USB_GEN_vect)
{
  if ((UDINT & (1 << EORSTI)) && (UDIEN & (1 << EORSTE))) {
    UDINT = ~(1 << EORSTI);
    UECONX |= 1 << EPEN;
    @<Configure EP0@>@;
  }
}

@ There is a quirk in atmega32u4 that it deconfigures control endpoint on usb reset
(contrary to what is said in datasheet section 22.4).
This can be shown by calling this section before attaching instead of in reset interrupt
handler and checking the cofigured values in reset interrupt handler --- they will be all zero.

@<Configure EP0@>=
UECFG0X |= 0 << EPTYPE0; /* control */
UECFG0X |= 0 << EPDIR; /* out */
UECFG1X |= 2 << EPSIZE0; /* 32 bytes (binary 10) */
UECFG1X |= 0 << EPBK0; /* one */
UECFG1X |= 1 << ALLOC;
