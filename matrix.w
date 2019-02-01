@* Matrix.

$$\hbox to6cm{\vbox to6.59cm{\vfil\special{psfile=keymap.eps
  clip llx=0 lly=0 urx=321 ury=353 rwi=1700}}\hfil}$$

This is the working principle:
$$\hbox to7cm{\vbox to4.2cm{\vfil\special{psfile=keypad.eps
  clip llx=0 lly=0 urx=240 ury=144 rwi=1984}}\hfil}$$

A is input and  C1 ... Cn are outputs.
We "turn on" one of C1, C2, ... Cn at a time by connecting it to ground inside the chip
(i.e., setting it to logic zero).
Other pins of C1, C2, ... Cn are not connected anywhere at that time.
The current will always flow into the pin which is connected to ground.
The current has to flow into your transmitter for the receiver to be able to tell it's a zero.
Now when the switch connected to this output pin is pressed, the input A
is pulled to ground through the switch, and its state becomes zero.
Pressing other switches doesn't change anything, since their other pins
are not connected to ground. When we want to read another switch, we
change the output pin which is connected to ground, so that always
just one of them is set like that.

To set output pin, do this:
|DDRx.y = 1|.
To unset output pin, do this;
|DDRx.y = 0|.

@ This is how keypad is connected:

\chardef\ttv='174 % vertical line
$$\vbox{\halign{\tt#\cr
+-----------+ \cr
{\ttv} 1 {\ttv} 2 {\ttv} 3 {\ttv} \cr
{\ttv} 4 {\ttv} 5 {\ttv} 6 {\ttv} \cr
{\ttv} 7 {\ttv} 8 {\ttv} 9 {\ttv} \cr
{\ttv} * {\ttv} 0 {\ttv} \char`#\ {\ttv} \cr
+-----------+ \cr
\ \ \ \ \ {\ttv} {\ttv} \cr
\ \ \ \ \ {\ttv} {\ttv} \cr
\ \ +-------+ \cr
\ \ {\ttv}1234567{\ttv} \cr
\ \ +-------+ \cr
}}$$

Where 1,2,3,4 are |PB4|,|PB5|,|PE6|,|PD7| and 5,6,7 are |PF4|,|PF5|,|PF6|.

@ @<Pullup input pins@>=
PORTB |= 1 << PB4 | 1 << PB5;
PORTE |= 1 << PE6;
PORTD |= 1 << PD7;

@ @<Global variables@>=
U8 btn = 0, mod = 0;

@
% NOTE: use index into an array of Pxn if pins in "for" are not consequtive:
% int a[3] = { PF3, PD4, PB5 }; ... for (int i = 0, ... DDRF |= 1 << a[i]; ... switch (a[i]) ...

% NOTE: use array of indexes to separate bits if pin numbers in "switch" collide:
% int b[256] = {0};
% if (~PINB & 1 << PB4) b[0xB4] = 1 << 0; ... if ... b[0xB5] = 1 << 1; ... b[0xE6] = 1 << 2; ...
% switch (b[0xB4] | ...) ... case b[0xB4]: ...
% (here # in woven output will represent P)

@<Get button@>=
    for (int i = PF4, done = 0; i <= PF7 && !done; i++) {
      DDRF |= 1 << i;
      @<Eliminate capacitance@>@;
      switch (~PINB & (1 << PB4 | 1 << PB5) | ~PINE & 1 << PE6 | ~PIND & 1 << PD7) {
      case 1 << PB4:
        switch (i) {
        case PF4: btn = '1'; @+ break;
        case PF5: btn = '2'; @+ break;
        case PF6: btn = '3'; @+ break;
        case PF7: btn = 'A'; @+ break;
        }
        done = 1;
        break;
      case 1 << PB5:
        switch (i) {
        case PF4: btn = '4'; @+ break;
        case PF5: btn = '5'; @+ break;
        case PF6: btn = '6'; @+ break;
        case PF7: btn = 'B'; @+ break;
        }
        done = 1;
        break;
      case 1 << PE6:
        switch (i) {
        case PF4: btn = '7'; @+ break;
        case PF5: btn = '8'; @+ break;
        case PF6: btn = '9'; @+ break;
        case PF7: btn = 'C'; @+ break;
        }
        done = 1;
        break;
      case 1 << PD7:
        switch (i) {
        case PF4: btn = '*'; @+ break;
        case PF5: btn = '0'; @+ break;
        case PF6: btn = '#'; @+ break;
        case PF7: btn = 'D'; @+ break;
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
then do this: 1)\footnote*{In contrast with usual \\{\_delay\_us(1)}, here we need
to use minimum possible delay because it is done repeatedly.}
If symbol(s) will appear by themselves (FIXME: under which conditions?),
add one no-op. Repeat until this does not happen. 2) If
symbol does not appear after pressing a key, add one no-op.
Repeat until this does not happen.

FIXME: maybe do |_delay_us(1);| in |@<Pullup input pins@>| and use only 2) here?
(and then change references to this section from everywhere)

one more way to test: use |@<Get button@>| in a `|while (1) ... _delay_us(1);|' loop
and when you detect a certain button, after a debounce delay (via |i++; ... if (i<delay) ...|),
check if btn==0 in the cycle and if yes, turn on led - while you are holding the button,
led must not turn on - if it does, add nop's

NOTE: in above methods add some more nops after testing to depass border state

@d nop() __asm__ __volatile__ ("nop")

@<Eliminate capacitance@>=
nop();
nop();
nop();
nop();
nop();

