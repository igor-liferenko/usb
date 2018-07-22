@ In this test we determine how endpoint configuration reacts to reset.
The result is `\.{esa}'.
So, we have learned that |CFGOK| need not be checked after configuring control endpoint,
and that after USB\_RESET control endpoint must be configured anew.
This contradicts to \S21.13,22.4 in datasheet.

\xdef\epconf{\secno}

@(/dev/null@>=
#include <avr/io.h>

#define configure @,@,@,@,@, UECONX |= 1 << EPEN; @+ UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))

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

  configure;
  if (!configured_ok) UDR1 = '=';

  while(1) if (UDINT & (1 << EORSTI)) break; @+ UDINT &= ~(1 << EORSTI);
  if (!configured_en) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'e'; @+ }
  if (!configured_sz) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 's'; @+ }
  if (!configured_al) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'a'; @+ }
}

@ Here we want to find out how many resets happen until first setup packet arrives.
Result is one, two or three\footnote*{In usb hub it is 1, is PC it is two
or three.}.

\xdef\numreset{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

volatile int num = 0;

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
  (void) UEDATX;
  if (UEDATX == 0x06) UDR1 = num + '0';
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    num++;
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  }
}

@ Now we can move further: to count number of resets before set address request.
The result is one.

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, @/
  0x01, @/
  0x10, 0x01, @/
  0x00, @/
  0x00, @/
  0x00, @/
  0x20, @/
  0xEB, 0x03, @/
  0x13, 0x20, @/
  0x00, 0x10, @/
  0x00, @/
  0x00, @/
  0x00, @/
@t\2@> 1 @/
};

uint8_t len = sizeof dev_desc;
const void *ptr = &(dev_desc[0]);

volatile int num = 0;

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
  (void) UEDATX;
  if (UEDATX != 0x06) return;
  (void) UEDATX;
  (void) UEDATX;
  (void) UEDATX; @+ (void) UEDATX;
  (void) UEDATX; @+ (void) UEDATX;
  UEINTX &= ~(1 << RXSTPI);
  num = 0;
  while (len--)
    UEDATX = pgm_read_byte_near((unsigned int) ptr++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);

  while (!(UEINTX & (1 << RXSTPI))) ;
  (void) UEDATX;
  if (UEDATX == 0x05) UDR1 = num + '0';
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    num++;
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  }
}

@ This test shows that in order that |USB_COM_vect| is called for |RXSTPI|,
it is necessary to enable |RXSTPE| after each reset.

\xdef\controlinterrupt{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

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

  while (1) ;
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
    UEIENX |= 1 << RXSTPE;
  }
}

ISR(USB_COM_vect)
{
  UEINTX &= ~(1 << RXSTPI); /* interrupt will fire right away until you acknowledge */
  UDR1 = '%';
}

@ In this test we show that |RSTCPU| does not work after first reset.
Output is `\.{rr}'.

\xdef\rstcpudoesnotworkafterfirstreset{\secno}

@(/dev/null@>=
#include <avr/io.h>

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'r';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  UDCON |= 1 << RSTCPU;

  while (!(UEINTX & (1 << RXSTPI))) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '%';
}

@ In this test we show that on Windows XP, SETUP request comes only once after reset signal.
Here we do according to test in \S\controlinterrupt. The only difference is that we output
`\.r' when reset signal happens.
The output is `\.{rr\%r\%r\%}'.

\xdef\onesetup{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

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

  while (1) ;
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'r';
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
    UEIENX |= 1 << RXSTPE;
  }
}

ISR(USB_COM_vect)
{
  UEINTX &= ~(1 << RXSTPI); /* interrupt will fire right away until you acknowledge */
  UDR1 = '%';
}

@ As is shown by test in \S\rstcpudoesnotworkafterfirstreset, |RSTCPU| does not work
after first reset.
Here we show how to make it work: it is necessary to clear |EORSTI| when reset occurs.

BUT, here is an important gotcha: on some systems, SETUP request comes only once after
reset signal (see test in \S\onesetup),
and it comes too quickly ---~right at the time of reset timeout
(see picture in \S8.0.7 in datasheet). As such, the SETUP request is not received.
For example, in this test on Windows XP the `\.{\%}' is never output: the output is `\.{rrrrr}'.

On Linux output is `\.{rrr\%r\%}'.

\xdef\xxx{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'r';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  UDCON |= 1 << RSTCPU;

  UDIEN |= 1 << EORSTE;
  sei();

  while (!(UEINTX & (1 << RXSTPI))) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '%';
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
  }
}

@ In this test we show that only when |EORSTI| is cleared |RSTCPU| works.
This test is extremely important. See \S\rstcpudoesnotworkafterfirstreset.
We do not want to use interrupts for handling |RXSTPI|, but instead handle
connection phase in a loop and only after that continue to the main program.
And results of this test show how to reset the program to initial state on host
(re)boot.


According to gotcha described in \S\xxx,

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  uint8_t usb_reset = MCUSR & (1 << 5); @+ MCUSR = 0; /* reset as early as possible
    (\S8.0.8 in datasheet) ---~to save some cycles (see below) */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'r';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  if (!usb_reset) { /* save some cycles */
    USBCON |= 1 << USBE;
    UDCON |= 1 << RSTCPU; /* it must be enabled only after enabling |USBE|,
      otherwise this bit remains unset after setting it */
    USBCON &= ~(1 << FRZCLK);
    USBCON |= 1 << OTGPADE; /* enable VBUS pad */
    while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
    UDCON &= ~(1 << DETACH);
  }
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!(UEINTX & (1 << RXSTPI))) ;
  while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = '%';
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'x'; while (!(UCSR1A & 1 << UDRE1)) ;
    UDINT &= ~(1 << EORSTI);
  }
}

@ OK, enough tests. We now have all the information that we need.

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
