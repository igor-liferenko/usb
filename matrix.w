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

@ @<Global \null variables@>=
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
    for (int i = PF4, done = 0; i <= PF6 && !done; i++) {
      DDRF |= 1 << i;
      @<Eliminate capacitance@>@;
      switch (~PINB & (1 << PB4 | 1 << PB5) | ~PINE & 1 << PE6 | ~PIND & 1 << PD7) {
      case 1 << PB4:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x1e; @+ break;
        case PF5: mod = 0; @+ btn = 0x1f; @+ break;
        case PF6: mod = 0; @+ btn = 0x20; @+ break;
        }
        done = 1;
        break;
      case 1 << PB5:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x21; @+ break;
        case PF5: mod = 0; @+ btn = 0x22; @+ break;
        case PF6: mod = 0; @+ btn = 0x23; @+ break;
        }
        done = 1;
        break;
      case 1 << PE6:
        switch (i) {
        case PF4: mod = 0; @+ btn = 0x24; @+ break;
        case PF5: mod = 0; @+ btn = 0x25; @+ break;
        case PF6: mod = 0; @+ btn = 0x26; @+ break;
        }
        done = 1;
        break;
      case 1 << PD7:
        switch (i) {
        case PF4: mod = 0x02; @+ btn = 0x25; @+ break;
        case PF5: mod = 0x00; @+ btn = 0x27; @+ break;
        case PF6: mod = 0x02; @+ btn = 0x20; @+ break;
        }
        done = 1;
        break;
      default: @/
        btn = 0; @+ mod = 0;
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
