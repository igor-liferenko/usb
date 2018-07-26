@x
  UDR1 = 'v';
@y
@z

@x
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'r';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'A';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'D';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ;
if (wLength == 9) UDR1 = 'g'; else UDR1 = 'G';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'L';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'M';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'P';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'N';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'Q';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'R';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'S';
@y
@z

@x
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'I';
@y
@z
