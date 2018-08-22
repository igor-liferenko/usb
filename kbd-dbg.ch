Note about "while":
It is not efficient to wait right after writing to UDR.
We may do other things - meanwhile the data will be transmitted.
It is only necessary to wait right before sending next data.

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
    UECFG1X |= 1 << ALLOC;
  }
  else {
    @<Reset MCU@>@; /* see \S\resetmcuonhostreboot\ */
@y
    UECFG1X |= 1 << ALLOC;
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'r';
  }
  else {
    while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'u'; while (!(UCSR1A & 1 << UDRE1)) ;
    @<Reset MCU@>@; /* see \S\resetmcuonhostreboot\ */    
@z

@x
UDADDR = wValue & 0x7F;
UEINTX &= ~(1 << RXSTPI);
@y
UDADDR = wValue & 0x7F;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'A';
@z

@x
buf = &dev_desc;
@y
while (!(UCSR1A & 1 << UDRE1)) ;
if (wLength == 8) UDR1 = 'd'; else UDR1 = 'D';
buf = &dev_desc;
@z

@x
buf = &conf_desc;
@y
while (!(UCSR1A & 1 << UDRE1)) ;
if (wLength == 9) UDR1 = 'g'; else UDR1 = 'G';
buf = &conf_desc;
@z

@x
buf = lang_desc;
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'L';
buf = lang_desc;
@z

@x
buf = &mfr_desc;
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'M';
buf = &mfr_desc;
@z

@x
buf = &prod_desc;
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'P';
buf = &prod_desc;
@z

@x
UEINTX &= ~(1 << RXSTPI);
UECONX |= 1 << STALLRQ; /* return STALL in response to IN token of the DATA stage */
@y
UEINTX &= ~(1 << RXSTPI);
UECONX |= 1 << STALLRQ; /* return STALL in response to IN token of the DATA stage */
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'Q';
@z

@x
buf = hid_report_descriptor;
@y
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'R';
buf = hid_report_descriptor;
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
@ @<Handle {\caps set idle}@>=
UEINTX &= ~(1 << RXSTPI);
@y
@ @<Handle {\caps set idle}@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; UDR1 = 'I';
@z
