@ Reset is done 4 times. This can be checked by the following code:
TODO: why test.w shows 'r' only twice before 'D'? find out why it is inconsistent
see also "XXX" in test.w

@ In this test we determine how endpoint configuration reacts to reset.
The result is `\.{esa}'. So, after each reset each of these parameters must be set again.

\xdef\epconf{\secno}

@(/dev/null@>=
#include <avr/io.h>

#define configure_en UECONX |= 1 << EPEN;
#define configure_sz UECFG1X = 1 << EPSIZE1;
#define configure_al UECFG1X |= 1 << ALLOC;
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))
#define send(c) do { UDR1 = c; while (!(UCSR1A & 1 << UDRE1)) ; } while (0)

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  configure_en
  configure_sz
  configure_al
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');

  while (!(UEINTX & (1 << RXSTPI))) ;
  send('%');
}

@ Here we want to find out how many resets happen until setup packet arrives.
We start like in \S\epconf\ and start adding code for waiting for successive resets.
Adding code for waiting for a reset consists of two stages: first we add code to configure items
which are output after previous reset and check if `\.{\%}' appears.
If it is, we are done. If not, we add the |while| loop and checking endpoint configuration.
Then the process repeats. To count the number of resets, we output a number after each reset.
The result is two resets. And after each reset endpoint must be configured.

\xdef\numreset{\secno}

@(/dev/null@>=
#include <avr/io.h>

#define configure_en UECONX |= 1 << EPEN;
#define configure_sz UECFG1X = 1 << EPSIZE1;
#define configure_al UECFG1X |= 1 << ALLOC;
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))
#define send(c) do { UDR1 = c; while (!(UCSR1A & 1 << UDRE1)) ; } while (0)

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  configure_en
  configure_sz
  configure_al
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  send('1');
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');
  configure_en
  configure_sz
  configure_al
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  send('2');
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');
  configure_en
  configure_sz
  configure_al
  if (!configured_ok) send('=');

  while (!(UEINTX & (1 << RXSTPI))) ;
  send('%');
}

@ Now we can move further: we detect reset via interrupts.

\xdef\interrupt{\secno}

@(test.c@>=
#include <avr/io.h>
#include <avr/interrupt.h>

#define configure_en UECONX |= 1 << EPEN;
#define configure_sz UECFG1X = 1 << EPSIZE1;
#define configure_al UECFG1X |= 1 << ALLOC;
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))
#define send(c) do { UDR1 = c; while (!(UCSR1A & 1 << UDRE1)) ; } while (0)

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!(UEINTX & (1 << RXSTPI))) ;
  send('%');

}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    configure_en
    configure_sz
    configure_al
    if (!configured_ok) send('=');
  }
}

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

int connected = 0;

int main(void)
{
  sei();
  @#
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
  UDIEN |= 1 << EORSTE;
  UDCON &= ~(1 << DETACH);

  while (!connected) {
    if (UEINTX & (1 << RXSTPI)) {
      usb_process_request();
    }
  }
  UDIEN &= ~(1 << EORSTE);
  while (1) { /* main application loop */
    UENUM = 0;
    if (UEINTX & (1 << RXSTPI)) {
//      |DDRB|=1<<PB0;PORTB|=1<<PB0;|
      /*process dtr here - grep SETUP\_CDC\_SET\_CONTROL\_LINE\_STATE*/
    }
#if 1==0
    if (line_status.DTR) {
      /* send a character (see cdc\_task.w) */
    }
    _delay_ms(1000);
#endif
  }
}

@ @<EOR interrupt handler@>=
ISR(USB_GEN_vect)
{
  if ((UDINT & (1 << EORSTI)) && (UDIEN & (1 << EORSTE))) {
    UDINT &= ~(1 << EORSTI);
    UDADDR &= ~(1 << ADDEN);
    UENUM = 0;
    UECONX |= 1 << EPEN;
    UECFG0X |= 0 << EPTYPE0; /* control */
    UECFG0X |= 0 << EPDIR; /* out */
    UECFG1X |= 3 << EPSIZE0; /* 64 bytes (binary 011) - must be in accord with
      |EP_CONTROL_LENGTH| */
    UECFG1X |= 0 << EPBK0; /* one */
    UECFG1X |= 1 << ALLOC;
  }
}


@* Index.
