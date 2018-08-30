@x
DTR is used by \.{tel} to switch the phone off (on timeout and for
special commands) by switching off/on
base station for one second.

Base station is powered when MCU is not powered.
When MCU is powered and connection to host is established,
wait until DTR is set for the first time (which is zero)
and set DTR to one if phone was off-hook, but this can
create problems due to case in avrtel-poweron.ch,
so to avoid need to determine hook state, just poweroff
base station when TTY is opened in \.{tel} (for this add
sleep 1 in two places in tel.w)

host driver powers off base station (by disabling DTR --- due to the patch).
When \.{tel} opens the TTY, DTR is used to switch on base station;
and when \.{tel} closes the TTY, DTR is used to switch off base station.
Note, that 1 second delay is used before enabling DTR in \.{tel} after
opening the TTY in order to reset base station in order to guarantee that
phone is switched off when \.{tel} starts, to make number of `\.{@@}'
match number of `\.{\%}' in log output
(otherwise just wait first RXSTPI after connection is establised and
clear it immediately).

TODO: when phone is off-hook, unplug arduino and ensure that it stays off-hook (and
check that "terminal disappeared" is printed)
TODO: when phone is off-hook, plug arduino and ensure that it stays off-hook
and that "terminal appeared" or "terminal opened" is printed and digits appear

The following phone model is used: Panasonic KX-TCD245.
The main requirement is that power supply for base station must be DC (to
be able to switch off power supply output via relay ---~because switching
off on power supply input (which does not require output to be DC)
could damage the power supply due to transition processes from 220v to
voltage of the power supply output), and it
must have led indicator for on-hook / off-hook on base station (to be able
to reset to initial state in state machine in \.{tel}; note, that
measuring voltage drop in phone line does not work reliably, because it
falsely triggers when dtmf signal is produced ---~the dtmf signal is alternating
below the trigger level and multiple on-hook/off-hook events occur in high
succession).

%Note, that we can not use simple cordless phone---a DECT phone is needed, because
%resetting base station to put the phone on-hook will not work
%(FIXME: check if it is really so).
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
  PORTD |= 1 << PD5; /* led off (before enabling output, because this led is inverted) */
  DDRD |= 1 << PD5; /* on-line/off-line indicator; also |PORTD & 1 << PD5| is used to get current
                       state to determine if transition happened (to save extra variable) */
  @<Set |PD2| to pullup mode@>@;
  EICRA |= 1 << ISC11 | 1 << ISC10; /* set INT1 to trigger on rising edge */
  EIMSK |= 1 << INT1; /* turn on INT1 */
  PORTB |= 1 << PB0; /* led off (before enabling output, because this led is inverted) */
  DDRB |= 1 << PB0; /* DTR indicator; also |PORTB & 1 << PB0| is used to get current DTR state
                       to determine if transition happened (to save extra variable) */
  DDRE |= 1 << PE6;

  char digit;
  while (1) {
    @<Get |line_status|@>@;
    if (line_status.DTR) {
      PORTE &= ~(1 << PE6); /* base station on */
      PORTB |= 1 << PB0; /* led off */
    }
    else {
      if (PORTB & 1 << PB0) { /* transition happened */
        PORTE |= 1 << PE6; /* base station off */
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
@ @<Pullup input pins@>=
PORTB |= 1 << PB4 | 1 << PB5;
PORTE |= 1 << PE6;
PORTD |= 1 << PD7;

@ @<Global variables@>=
U8 btn = 0;

@ @<Get button@>=
    for (int i = PF4, done = 0; i <= PF6 && !done; i++) {
      DDRF |= 1 << i;
      @<Eliminate capacitance@>@;
      switch (~PINB & (1 << PB4 | 1 << PB5) | ~PINE & 1 << PE6 | ~PIND & 1 << PD7) {
      case 1 << PB4:
        switch (i) {
        case PF4: btn = '1'; @+ break;
        case PF5: btn = '2'; @+ break;
        case PF6: btn = '3'; @+ break;
        }
        done = 1;
        break;
      case 1 << PB5:
        switch (i) {
        case PF4: btn = '4'; @+ break;
        case PF5: btn = '5'; @+ break;
        case PF6: btn = '6'; @+ break;
        }
        done = 1;
        break;
      case 1 << PE6:
        switch (i) {
        case PF4: btn = '7'; @+ break;
        case PF5: btn = '8'; @+ break;
        case PF6: btn = '9'; @+ break;
        }
        done = 1;
        break;
      case 1 << PD7:
        switch (i) {
        case PF4: btn = '*'; @+ break;
        case PF5: btn = '0'; @+ break;
        case PF6: btn = '#'; @+ break;
        }
        done = 1;
        break;
      default: @/
        btn = 0;
      }
      DDRF &= ~(1 << i);
    }

@ Delay to eliminate capacitance on the wire which may be open-ended on
the side of input pin (i.e., when button is not pressed), and capacitance
on the longer wire (i.e., when button is pressed).

To adjust the number of no-ops, remove all no-ops from here,
then do this: 1) If symbol(s) will appear by themselves,
add one no-op. Repeat until this does not happen. 2) If
symbol does not appear after pressing a key, add one no-op.
Repeat until this does not happen.

@d nop() __asm__ __volatile__ ("nop")

@<Eliminate capacitance@>=
nop();
nop();
nop();
nop();
nop();

@ @<Send button@>=
while (!(UEINTX & 1 << TXINI)) ;
UEINTX &= ~(1 << TXINI);
UEDATX = btn;
UEINTX &= ~(1 << FIFOCON);
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
