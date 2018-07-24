@ In this test we determine how endpoint configuration reacts to reset.
The result is `\.{esa}'.
So, we have learned that |CFGOK| need not be checked after configuring control endpoint,
and that after USB\_RESET control endpoint must be configured anew.

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
  UDINT &= ~(1 << EORSTI);
  num++;
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
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
const void *ptr = dev_desc;

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
  UDINT &= ~(1 << EORSTI);
  num++;
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
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
  UDINT &= ~(1 << EORSTI);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  UEIENX |= 1 << RXSTPE;
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
  UDINT &= ~(1 << EORSTI);
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'r';
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  UEIENX |= 1 << RXSTPE;
}

ISR(USB_COM_vect)
{
  UEINTX &= ~(1 << RXSTPI); /* interrupt will fire right away until you acknowledge */
  UDR1 = '%';
}

@ As is shown by test in \S\rstcpudoesnotworkafterfirstreset, |RSTCPU| does not work
after first reset.
Here we show how to make it work: it is necessary to clear |EORSTI| when reset occurs.
It seems RSTCPU is triggered only when EORSTI goes from zero to one, but only
after EORSTE interrupt exits.

BUT, here is an important gotcha: on some systems, SETUP request comes only once after
reset signal (see test in \S\onesetup\footnote*{Keep in mind also, that according to
test in \S\numreset, there may be only one SETUP request.}),
and it comes too quickly ---~right at the time of reset timeout
(see picture in \S8.0.7 in datasheet). As such, the SETUP request is not received.
For example, in this test on Windows XP the `\.{\%}' is never output: the output is `\.{rrrrr}'.

On Linux output is `\.{rrr\%r\%}'.

We do not want to use interrupts for handling |RXSTPI|, but instead handle
connection phase in a loop (until connection status variable is set to
``connected'') and only after that continue to the main program
(so that USB interrupts will not intervene with interrupts used for application).
But there is a small problem with this approach: on host reboot USB remains powered.
We need to reset the program to initial state via |RSTCPU|
(on host reboot usb reset signals are sent), because
the connection with the host is lost on host reboot, and thus we need to start
the connection loop again.

According to the gotcha, we cannot use |RSTCPU| after every
reset signal (because we will miss SETUP request).
But we don't have to. It is sufficient to use |RSTCPU| only once on host
reboot. And on host reboot there are plenty of reset signals,
so we will not miss anything.

But how do we detect host reboot?
The answer is: by checking in reset signal handler if the connection is
established. As we have the variable to store status of the connection,
we just check it: if connection is established, this means this
reset signal comes after host reboot, and |RSTCPU| is enabled then.

On MCU start we always disable |RSTCPU| (nothing will
change if it is not enabled).

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
  UDINT &= ~(1 << EORSTI);
}

@ In this test we show that setting |RSTCPU| in reset signal handler works.
Result is that green led is turned on when host reboots.

TODO: move here from corresponding part of TeX-part of previous section

@d USBRF 5

@(/dev/null@>=
  if (MCUSR & 1 << USBRF) {@+ DDRC |= 1 << PC7; @+ PORTC |= 1 << PC7; @+}
  MCUSR = 0;

@ In this test we show that |UENUM| is automatically set to zero on CPU reset,
caused by |RSTCPU|. This allows us not to set |UENUM| to zero before configuring
control endpoint in reset interrupt handler. Note, that we set |UENUM| to one
right before setting the |connected| flag.
Result is that green led is turned on when host reboots.

@d USBRF 5

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

const uint8_t user_conf_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x09, 0x02, 0x22, 0x00, 0x01, 0x01, 0x00, 0x80, 0x32, 0x09, 0x04, @/
  0x00, 0x00, 0x01, 0x03, 0x00, 0x00, 0x00, 0x09, 0x21, 0x00, 0x01, @/
  0x00, 0x01, 0x22, 0x2b, 0x00, 0x07, 0x05, 0x81, 0x03, 0x08, 0x00, @/
@t\2@> 0x0f @/
};

const uint8_t rep_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x05, 0x01, 0x09, 0x06, 0xa1, 0x01, 0x05, 0x07, 0x75, 0x01, 0x95, @/
  0x08, 0x19, 0xe0, 0x29, 0xe7, 0x15, 0x00, 0x25, 0x01, 0x81, 0x02, @/
  0x75, 0x08, 0x95, 0x01, 0x81, 0x03, 0x75, 0x08, 0x95, 0x06, 0x19, @/
@t\2@> 0x00, 0x29, 0x65, 0x15, 0x00, 0x25, 0x65, 0x81, 0x00, 0xc0 @/
};

volatile int connected = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  if (MCUSR & 1 << USBRF && UENUM != EP0) {@+ DDRC |= 1 << PC7; @+ PORTC |= 1 << PC7; @+}
  MCUSR = 0;

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;
  while (!(USBSTA & (1 << VBUS))) ;
  UDCON &= ~(1 << DETACH);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!connected) {
    if (UEINTX & 1 << RXSTPI) {
      switch (UEDATX) /* |bmRequestType| */
      {
      case 0x80: @/
        switch (UEDATX) /* |bRequest| */
        {
        case 0x06: @/
          (void) UEDATX; /* Descriptor Index */
          switch (UEDATX) /* |bDescriptorType| */
          {
          case 0x01: @/
            (void) UEDATX; @+ (void) UEDATX; /* Language Id */
            ((uint8_t *) &wLength)[0] = UEDATX;
            ((uint8_t *) &wLength)[1] = UEDATX;
            UEINTX &= ~(1 << RXSTPI);
            send_descriptor(dev_desc, sizeof dev_desc);
            break;
          case 0x02: @/
            (void) UEDATX; @+ (void) UEDATX; /* Language Id */
            ((uint8_t *) &wLength)[0] = UEDATX;
            ((uint8_t *) &wLength)[1] = UEDATX;
            UEINTX &= ~(1 << RXSTPI);
            send_descriptor(&user_conf_desc, wLength);
            break;
          }
          break;
        }
        break;
      case 0x81: @/
        switch (UEDATX) /* |bRequest| */
        {
        case 0x06: @/
          (void) UEDATX; /* Descriptor Index */
          switch (UEDATX) /* |bDescriptorType| */
          {
          case 0x22: @/
            (void) UEDATX; @+ (void) UEDATX; /* Language Id */
            ((uint8_t *) &wLength)[0] = UEDATX;
            ((uint8_t *) &wLength)[1] = UEDATX;
            UEINTX &= ~(1 << RXSTPI);
            send_descriptor(rep_desc, sizeof rep_desc);
            UENUM = 1;
            connected = 1;
            break;
          }
          break;
        }
        break;
      }
    }
  }
  UDR1 = '%';
}

ISR()
{
  UDINT &= ~(1 << EORSTI);
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
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG0X = 0 << EPTYPE0 | 0 << EPDIR; /* control, out */
    UECFG1X = 1 << EPSIZE1 + 1 << EPSIZE0 | 0 << EPBK0 | 1 << ALLOC; /* 64 bytes, one bank */
//TODO: see operator precedence
  }
}


@* Index.
