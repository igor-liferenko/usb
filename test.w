% IMPORTANT: while testing disconnect as much as possible from MCU
% (i.e., usbasp and UART), but most important is to unplug
% usbasp - replug manually, not via usbasp's reset.

% To compile certain section, change "/dev/null" to "test", then do
% as usual "ctangle test && make test".

\let\lheader\rheader
%\datethis

% NOTE: this file is included from other files - do not commit here \noinx, \nosec, \notoc

@* Testing.
The microcontroller is ATmega32U4.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3} (use \.{http://www.engbedded.com/fusecalc}).
We do not use bootloader, so the following may also be unprogrammed: \.{BOOTRST}
(TODO: find out why when this was programmed everything worked).
In short, fuses must be these: \.{E:CB}, \.{H:D9}, \.{L:FF}.
Set with the following command:

\centerline{\tt avrdude -q -c usbasp -p m32u4
  -U efuse:w:0xcb:m -U hfuse:w:0xd9:m -U lfuse:w:0xff:m}

@ In this test we determine how endpoint configuration reacts to reset.
The result is `\.{esa}'.
So, we have learned that after USB\_RESET control endpoint must be configured anew.

There is no sense to configure EP0 before main loop because host always does
\.{USB\_RESET} when it detects attach.

\xdef\epconf{\secno}

@(/dev/null@>=
#include <avr/io.h>

void main(void)
{
  UHWCON |= 1 << UVREGE;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR = 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & 1 << PLOCK)) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDCON &= ~(1 << DETACH);

  UECONX |= 1 << EPEN;
  UECFG1X = 1 << EPSIZE1;
  UECFG1X |= 1 << ALLOC;

  while (!(UDINT & 1 << EORSTI)) ;
  if (!(UECONX & 1 << EPEN)) @+ UDR1 = 'e';
  if (!(UECFG1X & 1 << EPSIZE1)) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 's'; @+ }
  if (!(UECFG1X & 1 << ALLOC)) { @+ while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'a'; @+ }
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

  PLLCSR = 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & 1 << PLOCK)) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  while (!(UEINTX & 1 << RXSTPI)) ;
  (void) UEDATX;
  if (UEDATX == 0x06) UDR1 = num + '0';
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  num++;
  UECONX |= 1 << EPEN;
  UECFG1X = 1 << EPSIZE1;
  UECFG1X |= 1 << ALLOC;
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

  PLLCSR = 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & 1 << PLOCK)) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */

  UDIEN |= 1 << EORSTE;
  sei();

  UDCON &= ~(1 << DETACH);

  while (!(UEINTX & 1 << RXSTPI)) ;
  (void) UEDATX;
  if (UEDATX != 0x06) return;
  UEINTX &= ~(1 << RXSTPI);
  while (!(UEINTX & 1 << TXINI)) ;
  while (len--)
    UEDATX = pgm_read_byte(ptr++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & 1 << RXOUTI)) ;
  num = 0;
  UEINTX &= ~(1 << RXOUTI);

  while (!(UEINTX & 1 << RXSTPI)) ;
  (void) UEDATX;
  if (UEDATX == 0x05) UDR1 = num + '0';
}

ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  num++;
  UECONX |= 1 << EPEN;
  UECFG1X = 1 << EPSIZE1;
  UECFG1X |= 1 << ALLOC;
}

@ We do not want to use interrupts for handling |RXSTPI|, but instead handle
connection phase in a loop (until connection status variable is set to
``connected'') and only after that continue to the main program
(so that USB interrupts will not intervene with interrupts used for application).
But there is a small problem with this approach: on host reboot USB remains powered.
We need to reset the program to initial state by resetting MCU, because
the connection with the host is lost on host reboot, and thus we need to start
the connection loop again.

On host reboot \.{USB\_RESET} is generated, so we may use this fact. 
In reset signal handler we check if the connection is
established. As we have the variable to store status of the connection,
we just check it: if connection is established, this means this
reset signal comes after host reboot, and MCU is reset then.

In this test we show that resetting MCU in \.{USB\_RESET} signal handler works.
Result: on connect first yellow led is on; when host reboots, first led is off and
second yellow led is on at the same time, and first led is on again after a while.
On WinXP this test works excellent. On Linux this happens twice, because
device is connected twice during reboot (on Linux another machine is used for
testing, and the first connect is made by BIOS on that machine).

WinXP before reboot:
vrrDrADgGQDgGSIR
WinXP while reboot:
uvrdDGrrrrDrADgGQDgGSIR
On Linux before reboot:
vrrrDrADQQQgGSIR
On Linux while reboot:
uvrdADgGSDgGGRuvrrrDrADQQQgGSIR

Here is used the fact that TXINI is `1' when RXSTPI becomes `1' (TODO: create test as in
\S\numreset\ and and refer to it from here and change places which refer to here to
refer to new test); and in new test also check that RXOUTI is `0'.

\xdef\resetmcuonhostreboot{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

const uint8_t dev_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x12, 0x01, 0x00, 0x02, 0x00, 0x00, 0x00, 0x20, 0xEB, 0x03, @/
@t\2@> 0x13, 0x20, 0x00, 0x10, 0x00, 0x00, 0x00, 1 @/
};

const uint8_t conf_desc[]
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
  if (MCUSR & 1 << WDRF) {@+ DDRD |= 1 << PD5; @+ PORTD |= 1 << PD5; @+}
  MCUSR = 0x00;
  WDTCSR |= 1 << WDCE | 1 << WDE;
  WDTCSR = 0x00;

  UHWCON |= 1 << UVREGE;

  UBRR1 = 34;
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';

  PLLCSR = 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & 1 << PLOCK)) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE;

  UDIEN |= 1 << EORSTE;
  sei();
  UDCON &= ~(1 << DETACH);

  uint8_t size;
  const void *buf;
  uint16_t wLength;
  int i;
  while (!connected)
    if (UEINTX & 1 << RXSTPI)
      switch (UEDATX | UEDATX << 8) {
      case 0x0500:
        UDADDR = UEDATX & 0x7F;
        UEINTX &= ~(1 << RXSTPI);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & 1 << TXINI)) ;
        UDADDR |= 1 << ADDEN;
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
        break;
      case 0x0680:
        switch (UEDATX | UEDATX << 8) {
        case 0x0100:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          size = wLength;
          if (wLength != 8) size = sizeof dev_desc; /* because host asks 64 bytes */
          buf = dev_desc;
          while (size--)
            UEDATX = pgm_read_byte(buf++);
          UEINTX &= ~(1 << TXINI);
          while (!(UEINTX & 1 << RXOUTI)) ;
          UEINTX &= ~(1 << RXOUTI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength == 8) UDR1 = 'd'; else UDR1 = 'D';
          break;
        case 0x0200:
          (void) UEDATX; @+ (void) UEDATX;
          wLength = UEDATX | UEDATX << 8;
          UEINTX &= ~(1 << RXSTPI);
          size = wLength;
          buf = conf_desc;
          if (wLength == 9) {
            while (size--)
              UEDATX = pgm_read_byte(buf++);
          }
          else {
            i = 0;
            for (; i < 32; i++)
              UEDATX = pgm_read_byte(buf++);
            UEINTX &= ~(1 << TXINI);
            while (!(UEINTX & 1 << TXINI)) ;
            for (; i < 34; i++)
              UEDATX = pgm_read_byte(buf++);
          }
          UEINTX &= ~(1 << TXINI);
          while (!(UEINTX & 1 << RXOUTI)) ;
          UEINTX &= ~(1 << RXOUTI);
          while (!(UCSR1A & 1 << UDRE1)) ;
          if (wLength == 9) UDR1 = 'g'; else UDR1 = 'G';
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
        size = sizeof rep_desc; /* not wLength because winxp requests 98 bytes */
        buf = rep_desc;
        i = 0;
        for (; i < 32; i++)
          UEDATX = pgm_read_byte(buf++);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & 1 << TXINI)) ;
        for (; i < 43; i++)
          UEDATX = pgm_read_byte(buf++);
        UEINTX &= ~(1 << TXINI);
        while (!(UEINTX & 1 << RXOUTI)) ;
        UEINTX &= ~(1 << RXOUTI);
        while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
        connected = 1;
        DDRB |= 1 << PB0; @+ PORTB |= 1 << PB0;
        break;
      case 0x0900:
        UEINTX &= ~(1 << RXSTPI);
        UENUM = 1;
        UECONX |= 1 << EPEN;
        UECFG0X = 1 << EPTYPE1 | 1 << EPTYPE0 | 1 << EPDIR;
        UECFG1X = 0;
        UECFG1X |= 1 << ALLOC;
        UENUM = 0;
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
    UECFG1X = 1 << EPSIZE1; /* it was checked that on atmega32u4 64 bytes does not work */
    UECFG1X |= 1 << ALLOC;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
  }
  else {
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'u'; while (!(UCSR1A & 1 << UDRE1)) ;
    WDTCSR |= 1 << WDCE | 1 << WDE;
    WDTCSR = 1 << WDE;
    while (1) ;
  }
}
