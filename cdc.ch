Apply as "ctangle ../avrtel/avrtel cdc cdc", "cweave ../avrtel/avrtel cdc cdc".

@x
DTR is used by \.{tel} to switch the phone off (on timeout and for
special commands) by switching off/on
base station for one second (the phone looses connection to base
station and automatically powers itself off).

\.{tel} uses DTR to switch on base station when it starts;
and when TTY is closed, DTR switches off base station.

The main requirement to the phone is that base station
must have led indicator\footnote*{For
some phone models when base station is powered on, the indicator is turned
on for a short time. In such case use \.{avrtel-poweron.ch}.}
for on-hook / off-hook on base station (to be able
to reset to initial state in state machine in \.{tel}; note, that
measuring voltage drop in phone line to determine hook state does not work
reliably, because it
falsely triggers when dtmf signal is produced ---~the dtmf signal is alternating
below the trigger level and multiple on-hook/off-hook events occur in high
succession).

Note, that relay switches off output from base station's power supply, not input
because transition processes from 220v could damage power supply because it
is switched on/off multiple times.

Also note that when device is not plugged in,
base station must be powered off, and it must be powered on by \.{tel} (this
is why non-inverted relay must be used (and from such kind of relay the
only suitable I know of is mechanical relay; and such relay gives an advantage
that power supply with AC and DC output may be used; however, see {\tt
TLP281.tex} how to fix TLP281 to make it behave like
normally-open-mechanical-relay)).
If base station
is powered when device is not plugged in, this breaks program logic badly.

%Note, that we can not use simple cordless phone---a DECT phone is needed, because
%resetting base station to put the phone on-hook will not work
%(FIXME: check if it is really so).

$$\hbox to12.27cm{\vbox to9.87777777777778cm{\vfil\special{psfile=avrtel.3
  clip llx=-91 lly=-67 urx=209 ury=134 rwi=3478}}\hfil}$$
@y
@z

@x
volatile int keydetect = 0;
ISR(INT1_vect)
{
  keydetect = 1;
}
@y
@z

@x
  DDRD |= 1 << PD5; /* |PD5| is used to show on-line/off-line state
                       and to determine when transition happens */
  @<Set |PD2| to pullup mode@>@;
  EICRA |= 1 << ISC11 | 1 << ISC10; /* set INT1 to trigger on rising edge */
  EIMSK |= 1 << INT1; /* turn on INT1; if it happens while USB RESET interrupt
    is processed, it does not change anything, as the device is going to be reset;
    if USB RESET happens whiled this interrupt is processed, it also does not change
    anything, as USB RESET is repeated several times by USB host, so it is safe
    that USB RESET interrupt is enabled (we cannot disable it because USB host
    may be rebooted) */
  DDRB |= 1 << PB0; /* |PB0| is used to show DTR state and and to determine
    when transition happens */
  PORTB |= 1 << PB0; /* led on */
  DDRE |= 1 << PE6;

  if (line_status.DTR != 0) { /* are unions automatically zeroed? (may be removed if yes) */
    PORTB |= 1 << PB0;
    PORTD |= 1 << PD5;
    return;
  }
  char digit;
  while (1) {
    @<Get |line_status|@>@;
    if (line_status.DTR) {
      PORTE |= 1 << PE6; /* base station on */
      PORTB &= ~(1 << PB0); /* led off */
    }
    else {
      if (!(PORTB & 1 << PB0)) { /* transition happened */
        PORTE &= ~(1 << PE6); /* base station off */
        keydetect = 0; /* in case key was detected right before base station was
                          switched off, which means that nothing must come from it */
      }
      PORTB |= 1 << PB0; /* led on */
    }
    @<Check |PD2| and indicate it via |PD5| and if it changed write to USB `\.@@' or `\.\%'
      (the latter only if DTR)@>@;
    if (keydetect) {
      keydetect = 0;
      switch (PINB & (1 << PB4 | 1 << PB5 | 1 << PB6) | PIND & 1 << PD7) {
      case (0x10): digit = '1'; @+ break;
      case (0x20): digit = '2'; @+ break;
      case (0x30): digit = '3'; @+ break;
      case (0x40): digit = '4'; @+ break;
      case (0x50): digit = '5'; @+ break;
      case (0x60): digit = '6'; @+ break;
      case (0x70): digit = '7'; @+ break;
      case (0x80): digit = '8'; @+ break;
      case (0x90): digit = '9'; @+ break;
      case (0xA0): digit = '0'; @+ break;
      case (0xB0): digit = '*'; @+ break;
      case (0xC0): digit = '#'; @+ break;
      }
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = digit;
      UEINTX &= ~(1 << FIFOCON);
    }
  }
@y
  @<Pullup input pins@>@;

  while (1) {
    @<Get |line_status|@>@;
    if (line_status.DTR) {
      @<Get button@>@;
      if (btn != 0) {
        @<Send button@>@;
        U8 prev_button = btn;
        int timeout = 2000;
        while (--timeout) {
          @<Get button@>@;
          if (btn != prev_button) break;
          _delay_ms(1);
        }
        while (1) {
          @<Get button@>@;
          if (btn != prev_button) break;
          @<Send button@>@;
          _delay_ms(50);
        }
      }
    }
  }
@z

@x
@ We check if handset is in use by using a switch. The switch is
optocoupler.

TODO create avrtel.4 which merges PC817C.png and PC817C-pinout.png,
except pullup part, and put section "enable pullup" before this section
and "git rm PC817C.png PC817C-pinout.png"

For on-line indication we send `\.@@' character to \.{tel}---to put
it to initial state.
For off-line indication we send `\.\%' character to \.{tel}---to disable
power reset on base station after timeout.

$$\hbox to9cm{\vbox to5.93cm{\vfil\special{psfile=avrtel.4
  clip llx=0 lly=0 urx=663 ury=437 rwi=2551}}\hfil}$$

@<Check |PD2| and indicate it via |PD5| and if it changed write to USB `\.@@' or `\.\%'
  (the latter only if DTR)@>=
if (PIND & 1 << PD2) { /* off-line */
  if (PORTD & 1 << PD5) { /* transition happened */
    if (line_status.DTR) { /* off-line was not caused by un-powering base station */
      while (!(UEINTX & 1 << TXINI)) ;
      UEINTX &= ~(1 << TXINI);
      UEDATX = '%';
      UEINTX &= ~(1 << FIFOCON);
    }
  }
  PORTD &= ~(1 << PD5);
}
else { /* on-line */
  if (!(PORTD & 1 << PD5)) { /* transition happened */
    while (!(UEINTX & 1 << TXINI)) ;
    UEINTX &= ~(1 << TXINI);
    UEDATX = '@@';
    UEINTX &= ~(1 << FIFOCON);
  }
  PORTD |= 1 << PD5;
}

@ The pull-up resistor is connected to the high voltage (this is usually 3.3V or 5V and is
often refereed to as VCC).

Pull-ups are often used with buttons and switches.

With a pull-up resistor, the input pin will read a high state when the photo-transistor
is not opened. In other words, a small amount of current is flowing between VCC and the input
pin (not to ground), thus the input pin reads close to VCC. When the photo-transistor is
opened, it connects the input pin directly to ground. The current flows through the resistor
to ground, thus the input pin reads a low state.

Since pull-up resistors are so commonly needed, our MCU has internal pull-ups
that can be enabled and disabled.

$$\hbox to7.54cm{\vbox to3.98638888888889cm{\vfil\special{psfile=avrtel.2
  clip llx=0 lly=0 urx=214 ury=113 rwi=2140}}\hfil}$$

@<Set |PD2| to pullup mode@>=
PORTD |= 1 << PD2;
_delay_us(1); /* after enabling pullup, wait for the pin to settle before reading it */
@y
@z

@x
@ No other requests except {\caps set control line state} come
after connection is established (speed is not set in \.{tel}).
@y
@ No other requests except {\caps set control line state} come
after connection is established (speed is not set in application, because it is irrelevant here).
Note, that skipping here {\caps set line coding} makes no sense,
because for this device to work with any application (not just where speed is not set),
such application must set DTR, which is never (?) the case.
@z

@x
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"TEL");
@y
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"CDC MATRIX");
@z

@x
@* Headers.
@y
@ @<Send button@>=
while (!(UEINTX & 1 << TXINI)) ;
UEINTX &= ~(1 << TXINI);
UEDATX = btn;
UEINTX &= ~(1 << FIFOCON);

@i matrix.w

@* Headers.
@z

@x
#include <util/delay.h> /* |_delay_us| */
@y
#include <util/delay.h> /* |_delay_us|, |_delay_ms| */
@z
