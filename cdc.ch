@x
DTR is used by \.{tel} to switch the phone off (on timeout and for
special commands) by switching off/on
base station for one second (the phone looses connection to base
station and automatically powers itself off).

\.{tel} uses DTR to switch on base station when it starts;
and when TTY is closed, DTR switches off base station.

The following phone model is used: Panasonic KX-TCD245.
The main requirement is that base station
must have led indicator for on-hook / off-hook on base station (to be able
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
that power supply with AC and DC output may be used)).

%Note, that we can not use simple cordless phone---a DECT phone is needed, because
%resetting base station to put the phone on-hook will not work
%(FIXME: check if it is really so).
@y
@z

@x
@<Global variables@>@;
@y
@<Global \null variables@>@;
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
  PORTD |= 1 << PD5; /* led off (before enabling output, because this led is inverted) */
  DDRD |= 1 << PD5; /* on-line/off-line indicator; also |PORTD & 1 << PD5| is used to get current
                       state to determine if transition happened (to save extra variable) */
  @<Set |PD2| to pullup mode@>@;
  EICRA |= 1 << ISC11 | 1 << ISC10; /* set INT1 to trigger on rising edge */
  EIMSK |= 1 << INT1; /* turn on INT1 */
  DDRB |= 1 << PB0; /* DTR indicator; also |PORTB & 1 << PB0| is used to get current DTR state
                       to determine if transition happened (to save extra variable) */
  DDRE |= 1 << PE6;

  if (line_status.DTR != 0) { /* are unions automatically zeroed? (may be removed if yes) */
    PORTB &= ~(1 << PB0);
    PORTD &= ~(1 << PD5);
    return;
  }
  char digit;
  while (1) {
    @<Get |line_status|@>@;
    if (line_status.DTR) {
      PORTE |= 1 << PE6; /* base station on */
      PORTB |= 1 << PB0; /* led off */
    }
    else {
      if (PORTB & 1 << PB0) { /* transition happened */
        PORTE &= ~(1 << PE6); /* base station off */
        keydetect = 0; /* in case key was detected right before base station was
                          switched off, which means that nothing must come from it */
      }
      PORTB &= ~(1 << PB0); /* led on */
    }
    @<Indicate phone line state and notify \.{tel} if state changed@>@;
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
      default: digit = '?';
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
@ For on-line indication we send `\.{@@}' character to \.{tel}---to put
it to initial state.
For off-line indication we send `\.{\%}' character to \.{tel}---to disable
power reset on base station after timeout.

TODO: insert PC817C.png

@<Indicate phone line state and notify \.{tel} if state changed@>=
if (PIND & 1 << PD2) { /* off-line */
  if (!(PORTD & 1 << PD5)) { /* transition happened */
    while (!(UEINTX & 1 << TXINI)) ;
    UEINTX &= ~(1 << TXINI);
    UEDATX = '%';
    UEINTX &= ~(1 << FIFOCON);
  }
  PORTD |= 1 << PD5;
}
else { /* on-line */
  if (PORTD & 1 << PD5) { /* transition happened */
    while (!(UEINTX & 1 << TXINI)) ;
    UEINTX &= ~(1 << TXINI);
    UEDATX = '@@';
    UEINTX &= ~(1 << FIFOCON);
  }
  PORTD &= ~(1 << PD5);
}

@ The pull-up resistor is connected to the high voltage (this is usually 3.3V or 5V and is
often refereed to as VCC).

Pull-ups are often used with buttons and switches.

With a pull-up resistor, the input pin will read a high state when the photo-transistor
is not opened. In other words, a small amount of current is flowing between VCC and the input
pin (not to ground), thus the input pin reads close to VCC. When the photo-transistor is
opened, it connects the input pin directly to ground. The current flows through the resistor
to ground, thus the input pin reads a low state.

Since pull-up resistors are so commonly needed, many MCUs, like the ATmega328 microcontroller
on the Arduino platform, have internal pull-ups that can be enabled and disabled.

TODO: insert pullup.svg

@<Set |PD2| to pullup mode@>=
PORTD |= 1 << PD2;
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
@ @<Global variables@>=
@y
@ @<Global \null variables@>=
@z

@x
@ @<Global variables@>=
@y
@ @<Global \null variables@>=
@z

@x
@<Global variables@>=
@y
@<Global \null variables@>=
@z

@x
@ @<Global variables@>=
@y
@ @<Global \null variables@>=
@z

@x
@<Global variables@>=
@y
@<Global \null variables@>=
@z

@x
@<Global variables@>=
@y
@<Global \null variables@>=
@z

@x
@<Global variables@>=
@y
@<Global \null variables@>=
@z

@x
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"TEL");
@y
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"CDC MATRIX");
@z

@x
@<Global variables@>=
@y
@<Global \null variables@>=
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

@ This is to use matrix.w

@<Get button@>=
if (btn == 0x1e) btn = '1';
if (btn == 0x1f) btn = '2';
if (mod == 0 && btn == 0x20) btn = '3';
if (btn == 0x21) btn = '4';
if (btn == 0x22) btn = '5';
if (btn == 0x23) btn = '6';
if (btn == 0x24) btn = '7';
if (mod == 0 && btn == 0x25) btn = '8';
if (btn == 0x26) btn = '9';
if (mod == 0x02 && btn == 0x25) btn = '*';
if (btn == 0x27) btn = '0';
if (mod == 0x02 && btn == 0x20) btn = '#';

@* Headers.
@z
