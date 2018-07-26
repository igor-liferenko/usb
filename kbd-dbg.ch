@x
  UHWCON = 1 << UVREGE;
@y
  UHWCON = 1 << UVREGE;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';
@z

@x
  else UDCON |= 1 << RSTCPU; /* see \S\cpuresetonlyonhostreboot\ */
@y
  else UDCON |= 1 << RSTCPU; /* see \S\cpuresetonlyonhostreboot\ */
  while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
@z

@x
UDADDR = UEDATX & 0x7F;
UEINTX &= ~(1 << RXSTPI);
@y
UDADDR = UEDATX & 0x7F;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
@z

@x
send_descriptor(&dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'D';
send_descriptor(&dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);
@z

@x
send_descriptor(&user_conf_desc, wLength);
@y
while (!(UCSR1A & 1 << UDRE1)) ;
if (wLength == 9) UDR1 = 'g'; else UDR1 = 'G';
send_descriptor(&user_conf_desc, wLength);
@z

@x
send_descriptor(lang_desc, sizeof lang_desc);
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'L';
send_descriptor(lang_desc, sizeof lang_desc);
@z

@x
send_descriptor(&mfr_desc, pgm_read_byte(&mfr_desc.bLength));
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'M';
send_descriptor(&mfr_desc, pgm_read_byte(&mfr_desc.bLength));
@z

@x
send_descriptor(&prod_desc, pgm_read_byte(&prod_desc.bLength));
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'P';
send_descriptor(&prod_desc, pgm_read_byte(&prod_desc.bLength));
@z

@x
send_descriptor(NULL, 1 + 1 + SN_LENGTH * 2);
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'N';
send_descriptor(NULL, 1 + 1 + SN_LENGTH * 2);
@z

@x
UECONX |= 1 << STALLRQ;
UEINTX &= ~(1 << RXSTPI);
@y
UECONX |= 1 << STALLRQ;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'Q';
@z

@x
send_descriptor(hid_report_descriptor, sizeof hid_report_descriptor);
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
send_descriptor(hid_report_descriptor, sizeof hid_report_descriptor);
@z

@x
@ @<Handle {\caps set configuration}@>=
UEINTX &= ~(1 << RXSTPI);
@y
@ @<Handle {\caps set configuration}@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'S';
@z

@x
@<Handle {\caps set idle}@>=
UEINTX &= ~(1 << RXSTPI);
@y
@<Handle {\caps set idle}@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'I';
@z
