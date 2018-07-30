% IMPORTANT: while testing disconnect as much as possible from MCU
% (i.e., programmer and UART), but most important is to unplug the
% programmer - replug manually, not via programmer's reset.

% To compile certain section, change "/dev/null" to "test", then do
% as usual "ctangle test && make test".

\let\lheader\rheader
%\datethis

% NOTE: this file is included from other files - do not commit here \noinx, \nosec, \notoc

@* Testing.
The microcontroller is ATmega32U4.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3} (use \.{http://www.engbedded.com/fusecalc}).
In short, fuses must be these: \.{E:CB}, \.{H:D8}, \.{L:FF}.

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

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

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
  0x00, 0x02, @/
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

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  while (!(UEINTX & (1 << RXSTPI))) ;
  (void) UEDATX;
  if (UEDATX != 0x06) return;
  UEINTX &= ~(1 << RXSTPI);
  num = 0;
  while (len--)
    UEDATX = pgm_read_byte(ptr++);
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
it is necessary to enable |RXSTPE| at the time when you configure EP0.

Result: `\.{\%\%\%}' (on WinXP).

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

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

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
  UEINTX &= ~(1 << RXSTPI); /* interrupt will trigger infinitely if you don't do this */
  UDR1 = '%';
}

@ In this test we show that |RSTCPU| does not work after first reset.
Output is `\.{vr}'.

\xdef\rstcpudoesnotworkafterfirstreset{\secno}

@(/dev/null@>=
#include <avr/io.h>
#define USBRF 5
uint8_t usb_reset = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  if (MCUSR & 1 << USBRF) usb_reset = 1;
  MCUSR = 0;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  if (!usb_reset) { UDR1 = 'v'; while (!(UCSR1A & 1 << UDRE1)) ; }

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  if (usb_reset) { UDR1 = 'r'; while (!(UCSR1A & 1 << UDRE1)) ; }
  UDCON |= 1 << RSTCPU;
  UDCON &= ~(1 << DETACH);
  UECONX |= 1 << EPEN;
  UECFG1X = 1 << EPSIZE1 | 1 << ALLOC;

  while (!(UEINTX & (1 << RXSTPI))) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '%';
}

@ Here we show that RSTCPU remains enabled on MCU restart.

Result: on device connect yellow led is on,
green led is burning after host reboot.

\xdef\rstcpuremainsenabled{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#define USBRF 5

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0xEB, 0x03, @/
@t\2@> 0x13, 0x20, 0x00, 0x10, 0x00, 0x00, 0x00, 1 @/
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

void send_descriptor(const void *buf, int size)
{
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == 32)
        break;
      UEDATX = pgm_read_byte(buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
}

volatile int connected = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  if (MCUSR & 1 << USBRF && UDCON & 1 << RSTCPU) {
    DDRC |= 1 << PC7;
    PORTC |= 1 << PC7;
  }
  MCUSR = 0;

  UDCON &= ~(1 << RSTCPU);

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  uint16_t wLength;
  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      switch (UEDATX | UEDATX << 8) {
      case 0x0500:
        UDADDR = UEDATX & 0x7F;
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet was sent */
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
        UDADDR |= 1 << ADDEN;
        break;
      case 0x0680:
        switch (UEDATX | UEDATX << 8) {
        case 0x0100:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==8) UDR1 = 'd'; else UDR1 = 'D';
          send_descriptor(dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
          break;
        case 0x0200:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==9) UDR1 = 'g'; else UDR1 = 'G';
          send_descriptor(&user_conf_desc, wLength);
          break;
        case 0x0600:
          UECONX |= 1 << STALLRQ;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'Q';
          break;
        }
        break;
      case 0x0681:
        UEINTX &= ~(1 << RXSTPI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
        send_descriptor(rep_desc, sizeof rep_desc);
        connected = 1;
        DDRB |= 1 << PB0; @+ PORTB |= 1 << PB0;
        UENUM = 1;
        UECONX |= 1 << EPEN;
        UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR;
        UECFG1X = 1 << ALLOC;
        break;
      case 0x0900:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'S';
        break;
      case 0x0a21:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'I';
        break;
      }

  while (1) ;
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
  }
  else {
    UDCON |= 1 << RSTCPU;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'u';
  }
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

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

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
test in \S\numreset, there may be only {\sl one\/} SETUP request.}),
and it comes too quickly ---~right at the time of reset timeout
(see picture in \S8.0.7 in datasheet). As such, the SETUP request is not received.
For example, in this test on Windows XP the `\.{\%}' is never output: the output is `\.{vrrrr}'.

On Linux output is `\.{vrr\%r\%}'.

\xdef\rstcpugotcha{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#define USBRF 5
uint8_t usb_reset = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  if (MCUSR & 1 << USBRF) usb_reset = 1;
  MCUSR = 0;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  if (!usb_reset) { UDR1 = 'v'; while (!(UCSR1A & 1 << UDRE1)) ; }

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  UDIEN |= 1 << EORSTE;
  sei();
  if (usb_reset) { UDR1 = 'r'; while (!(UCSR1A & 1 << UDRE1)) ; }
  UDCON |= 1 << RSTCPU;
  UDCON &= ~(1 << DETACH);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);

  while (!(UEINTX & (1 << RXSTPI))) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '%';
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
}

@ We do not want to use interrupts for handling |RXSTPI|, but instead handle
connection phase in a loop (until connection status variable is set to
``connected'') and only after that continue to the main program
(so that USB interrupts will not intervene with interrupts used for application).
But there is a small problem with this approach: on host reboot USB remains powered.
We need to reset the program to initial state via |RSTCPU|
(on host reboot usb reset signals are sent), because
the connection with the host is lost on host reboot, and thus we need to start
the connection loop again.

BUT according to the gotcha in \S\rstcpugotcha, we cannot use |RSTCPU| after every
reset signal (because we will miss SETUP request).
But we don't have to. It is sufficient to use |RSTCPU| only once on host
reboot. And on host reboot there are plenty of reset signals,
so we will not miss anything.

But how do we detect host reboot?
The answer is: by checking in reset signal handler if the connection is
established. As we have the variable to store status of the connection,
we just check it: if connection is established, this means this
reset signal comes after host reboot, and |RSTCPU| is enabled then.

According to test in \S\rstcpuremainsenabled, |RSTCPU| remains enabled on MCU
restart, so we need to disable it: on MCU start we always disable
|RSTCPU| (nothing will change if it is not enabled).

In this test we show that setting |RSTCPU| in reset signal handler works.
Result: on connect first yellow led is on; when host reboots, first led is off and
second yellow led is on at the same time, and first led is on again after a while.
On WinXP this test works excellent. On Linux this happens twice, because
device is connected twice during reboot (on Linux another machine is used for
testing, and I am sure that the first connect is made by BIOS on that machine).

WinXP before reboot:
vrrDrADgGQDgGSIR
WinXP while reboot:
uvrrdDGrrrrDrADgGQDgGSIR
On Linux before reboot:
vrrrDrADQQQgGSIR
On Linux while reboot:
uvrrdADgGSDgGGRuvrrrDrADQQQgGSIR

\xdef\cpuresetonlyonhostreboot{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#define USBRF 5

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0xEB, 0x03, @/
@t\2@> 0x13, 0x20, 0x00, 0x10, 0x00, 0x00, 0x00, 1 @/
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

void send_descriptor(const void *buf, int size)
{
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == 32)
        break;
      UEDATX = pgm_read_byte(buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
}

volatile int connected = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  if (MCUSR & 1 << USBRF) {@+ DDRD |= 1 << PD5; @+ PORTD |= 1 << PD5; @+}
  MCUSR = 0;

  UDCON &= ~(1 << RSTCPU);

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  uint16_t wLength;
  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      switch (UEDATX | UEDATX << 8) {
      case 0x0500:
        UDADDR = UEDATX & 0x7F;
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet was sent */
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
        UDADDR |= 1 << ADDEN;
        break;
      case 0x0680:
        switch (UEDATX | UEDATX << 8) {
        case 0x0100:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==8) UDR1 = 'd'; else UDR1 = 'D';
          send_descriptor(dev_desc, wLength < sizeof dev_desc ? wLength : sizeof dev_desc);
          break;
        case 0x0200:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==9) UDR1 = 'g'; else UDR1 = 'G';
          send_descriptor(&user_conf_desc, wLength);
          break;
        case 0x0600:
          UECONX |= 1 << STALLRQ;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'Q';
          break;
        }
        break;
      case 0x0681:
        UEINTX &= ~(1 << RXSTPI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
        send_descriptor(rep_desc, sizeof rep_desc);
        connected = 1;
        DDRB |= 1 << PB0; @+ PORTB |= 1 << PB0;
        UENUM = 1;
        UECONX |= 1 << EPEN;
        UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR;
        UECFG1X = 1 << ALLOC;
        break;
      case 0x0900:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'S';
        break;
      case 0x0a21:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'I';
        break;
      }

  while (1) ;
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
  }
  else {
    UDCON |= 1 << RSTCPU;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'u';
  }
}

@ In this test we show that |UENUM| is automatically set to zero on CPU reset,
caused by |RSTCPU|. This allows us not to set |UENUM| to zero before configuring
control endpoint in reset interrupt handler. Note, that we set |UENUM| to one
right before setting the |connected| flag.

This example implements a HID keyboard.

Result: on connect yellow led is on; on host reboot green led is not on.

\xdef\uenumtozero{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#define USBRF 5

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0xEB, 0x03, @/
@t\2@> 0x13, 0x20, 0x00, 0x10, 0x00, 0x00, 0x00, 1 @/
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

void send_descriptor(const void *buf, int size)
{
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == 32)
        break;
      UEDATX = pgm_read_byte(buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
}

volatile int connected = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  if (MCUSR & 1 << USBRF && UENUM != 0) {@+ DDRC |= 1 << PC7; @+ PORTC |= 1 << PC7; @+}
  MCUSR = 0;

  UDCON &= ~(1 << RSTCPU);

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  uint16_t wLength;
  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      switch (UEDATX | UEDATX << 8) {
      case 0x0500:
        UDADDR = UEDATX & 0x7F;
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet was sent */
        UDADDR |= 1 << ADDEN;
        break;
      case 0x0680:
        switch (UEDATX | UEDATX << 8) {
        case 0x0100:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          send_descriptor(dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
          break;
        case 0x0200:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          send_descriptor(&user_conf_desc, wLength);
          break;
        case 0x0600:
          UECONX |= 1 << STALLRQ;
          UEINTX &= ~(1 << RXSTPI);
          break;
        }
        break;
      case 0x0681:
        UEINTX &= ~(1 << RXSTPI);
        send_descriptor(rep_desc, sizeof rep_desc);
        UENUM = 1;
        UECONX |= 1 << EPEN;
        UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR;
        UECFG1X = 1 << ALLOC;
        connected = 1;
        DDRB |= 1 << PB0; @+ PORTB |= 1 << PB0;
        break;
      case 0x0900:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        break;
      case 0x0a21:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        break;
      }

  while (1) ;
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC;
  }
  else UDCON |= 1 << RSTCPU;
}

@ In this test we show that when MCU starts, TXINI is 0, and that it is changed from
0 to 1 for the first time when SETUP packet arrives. Output is `\.{01}'.
After a timeout appear `\.{01}'. It means that TXINI is set
to `\.0' when next SETUP packet arrives and then
immediately it is set to `\.1'.

Maybe this is done for TXINI interrupt to work (in order for interrupt to work
TXINI must change from 0 to 1).

Note, that SETUP packet may be received by CONTROL and OUT endpoints, but not
by IN endpoint.

\xdef\txinichange{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

void main(void)
{
  UHWCON |= 1 << UVREGE;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  if (UEINTX & 1 << TXINI) UDR1 = '1';
  else UDR1 = '0';
  while (!(UEINTX & 1 << RXSTPI)) ;
  while (!(UCSR1A & 1 << UDRE1)) ;
  if (UEINTX & 1 << TXINI) UDR1 = '1';
  else UDR1 = '0';
  UEINTX &= ~(1 << RXSTPI);
  while (UEINTX & 1 << TXINI) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '0';
  while (!(UEINTX & 1 << TXINI)) ;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = '1';
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
}

@ In this test we check if |RXSTPI| is automatically acknowledged.
Do not clear |RXSTPI| on first request and see in wireshark if response will
be sent with the same status as normal.

Result: wireshark shows ENOENT error status in response URB (while checking wireshark
ensure that `\.{\%}' is printed to terminal).

\xdef\rxstpiautoack{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, @/
  0x01, @/
  0x00, 0x02, @/
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

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  while (!(UEINTX & (1 << RXSTPI))) ;
  (void) UEDATX;
  if (UEDATX == 0x06) UDR1 = '%';
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  num++;
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
}

@ In this test we show that CFGOK must not be called after configuring
non-control endpoint.

Result: `\.=' is not output.

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

#define USBRF 5

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0xEB, 0x03, @/
@t\2@> 0x13, 0x20, 0x00, 0x10, 0x00, 0x00, 0x00, 1 @/
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

void send_descriptor(const void *buf, int size)
{
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == 32)
        break;
      UEDATX = pgm_read_byte(buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
}

volatile int connected = 0;
void main(void)
{
  UHWCON |= 1 << UVREGE;

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  uint16_t wLength;
  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      switch (UEDATX | UEDATX << 8) {
      case 0x0500:
        UDADDR = UEDATX & 0x7F;
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet was sent */
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
        UDADDR |= 1 << ADDEN;
        break;
      case 0x0680:
        switch (UEDATX | UEDATX << 8) {
        case 0x0100:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==8) UDR1 = 'd'; else UDR1 = 'D';
          send_descriptor(dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
          break;
        case 0x0200:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength==9) UDR1 = 'g'; else UDR1 = 'G';
          send_descriptor(&user_conf_desc, wLength);
          break;
        case 0x0600:
          UECONX |= 1 << STALLRQ;
          UEINTX &= ~(1 << RXSTPI);
          while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'Q';
          break;
        }
        break;
      case 0x0681:
        UEINTX &= ~(1 << RXSTPI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
        send_descriptor(rep_desc, sizeof rep_desc);
        connected = 1;
        UENUM = 1;
        UECONX |= 1 << EPEN;
        UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR;
        UECFG1X = 1 << ALLOC;
        if (!(UESTA0X & 1 << CFGOK)) {
          while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = '=';
        }
        break;
      case 0x0900:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'S';
        break;
      case 0x0a21:
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'I';
        break;
      }

  while (1) ;
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG1X = 1 << EPSIZE1 | 1 << ALLOC;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
  }
}

@ In this test we check if TXINI is set to 1 befor RXSTPI or after.
It is necessary to know if we must wait for TXINI to become 1 after
receiving RXSTPI or not. According to the test in \S\txinichange,
TXINI becomes 0 when RXSTPI arrives.

Result: `\.x' never appears. So, there is no change that
TXINI is not 1 after we clear RXSTPI---we need not do any checking
and waiting.

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

void main(void)
{
  UHWCON |= 1 << UVREGE;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  if (UEINTX & 1 << TXINI) UDR1 = '1';
  else UDR1 = '0';
  while (!(UEINTX & 1 << RXSTPI)) ;
  while (!(UCSR1A & 1 << UDRE1)) ;
  if (UEINTX & 1 << TXINI) UDR1 = '1';
  else UDR1 = '0';
  UEINTX &= ~(1 << RXSTPI);
  while (UEINTX & 1 << TXINI) ;
  if (UEINTX & 1 << RXSTPI) {
    while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'x';
  }
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  UECONX |= 1 << EPEN;
  UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
}
