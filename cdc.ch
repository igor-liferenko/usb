Put this to avrtel.w + see usbttl/avrtel.ch

  PORTD |= 1 << PD5; /* led off (before enabling output) */
  DDRD |= 1 << PD5; /* on-hook indication */
  DDRB |= 1 << PB0; /* DTR indication */
  DDRE |= 1 << PE6;
  PORTE |= 1 << PE6; /* |DTR| pin high */


line_status.all = wValue;
if (line_status.DTR) {
  PORTE &= ~(1 << PE6); /* |DTR| pin low */
  PORTB |= 1 << PB0; /* led off */
}
else {
  PORTE |= 1 << PE6; /* |DTR| pin high */
  PORTB &= ~(1 << PB0); /* led on */
}
