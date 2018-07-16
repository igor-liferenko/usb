@x
@d EP2 2
@y
@z

@x
@d M /* microsin.net/programming/avr-working-with-usb/usb-device-on-assembler.html */
@y
@z

@x
@ @<Global \null variables@>=
volatile uint8_t a[8];
@y
@z

@x
  else if (UEINT == (1 << EP1)) {
#ifdef M
    if (!(UEINTX & (1 << FIFOCON))) PORTB |= 1 << PB0;
    while (!(UEINTX & (1 << FIFOCON))) ;
    if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
    while (!(UEINTX & (1 << TXINI))) ;
#endif
    for (int i = 0; i < 8; i++)
      UEDATX = a[i];
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);
#ifdef M
    while (!(UEINTX & (1 << TXINI))) ;
    while (!(UEINTX & (1 << FIFOCON))) ;
    UEIENX = 1 << RXOUTE;
#endif
    UENUM = EP2;
  }
@y
  else if (UEINT == (1 << EP1)) {
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0x04;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);
    while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent, then prepare
      new packet to be sent when following IN request arrives (for key release) */
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEDATX = 0;
    UEINTX &= ~(1 << TXINI);
    UEINTX &= ~(1 << FIFOCON);
  }
@z

@x
  else if (UEINT == (1 << EP2)) {
#ifdef M
    if (!(UEINTX & (1 << RXOUTI))) PORTB |= 1 << PB0;
    while (!(UEINTX & (1 << RXOUTI))) ;
    if (!(UEINTX & (1 << FIFOCON))) PORTB |= 1 << PB0;
    while (!(UEINTX & (1 << FIFOCON))) ;
#endif
    UEINTX &= ~(1 << RXOUTI);
    for (int i = 0; i < 8; i++)
      a[i] = UEDATX;
    UEINTX &= ~(1 << FIFOCON);

    UENUM = EP1;
    UEIENX = 1 << TXINE; /* trigger interrupt when IN packet arrives */
  }
@y
@z

@x
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  if (!(UEINTX & (1 << TXINI))) break;
#endif
@y
@z

@x
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
#endif
@y
@z

@x
UENUM = EP2;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1) + (1 << EPTYPE0) | (0 << EPDIR); /* interrupt\footnote\ddag
{Must correspond to OUT endpoint description in |@<Initialize element 5...@>|.}, OUT */
UECFG1X = (0 << EPBK0) | (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 8 bytes\footnote
{\ddag\ddag}{Must correspond to OUT endpoint description in |hid_report_descriptor|.} */
while (!(UESTA0X & (1 << CFGOK))) ;
@y
@z
  
@x
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  if (!(UEINTX & (1 << TXINI))) break;
#endif
@y
@z

@x
  UENUM = EP2;
@y
  UENUM = EP1;
@z

@x
#ifdef M
  while (!(UEINTX & (1 << TXINI))) ;
  buf = &(hid_report_descriptor[0]);
  int i = 0;
  for (; i < 32; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << TXINI))) ;
  for (; i < 34; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);
#else
  send_descriptor(&(hid_report_descriptor[0]), wLength);
#endif

  UENUM = EP2;
  UEIENX = 1 << RXOUTE; /* trigger interrupt when OUT packet arrives */
@y
  send_descriptor(&(hid_report_descriptor[0]), wLength);

  UENUM = EP1;
  UEIENX = 1 << TXINE; /* trigger interrupt when IN packet arrives */
@z

@x
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
  buf = &dev_desc.bLength;
  for (int i = 0; i < sizeof dev_desc; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);
#else
  send_descriptor(&dev_desc.bLength, sizeof dev_desc);
    /* TODO: reduce |size| to |wLength| if it exceeds it */
#endif
@y
send_descriptor(&dev_desc.bLength, sizeof dev_desc);
  /* TODO: reduce |size| to |wLength| if it exceeds it */
@z

@x
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
  buf = &user_conf_desc.conf_desc.bLength;
  if (wLength == 9) {
    for (int i = 0; i < 9; i++)
      UEDATX = pgm_read_byte_near((unsigned int) buf++);
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << NAKOUTI))) ;
    UEINTX &= ~(1 << NAKOUTI);
    while (!(UEINTX & (1 << RXOUTI))) ;
    UEINTX &= ~(1 << RXOUTI);
  }
  else {
    int i = 0;
    for (; i < 32; i++)
      UEDATX = pgm_read_byte_near((unsigned int) buf++);
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI))) ;
    for (; i < 41; i++)
      UEDATX = pgm_read_byte_near((unsigned int) buf++);
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << NAKOUTI))) ;
    UEINTX &= ~(1 << NAKOUTI);
    while (!(UEINTX & (1 << RXOUTI))) ;
    UEINTX &= ~(1 << RXOUTI);
  }
#else
  send_descriptor(&user_conf_desc.conf_desc.bLength, wLength);
#endif
@y
send_descriptor(&user_conf_desc.conf_desc.bLength, wLength);
@z

@x
#ifdef M
  buf = &(lang_desc[0]);
  size = sizeof lang_desc;
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
  for (int i = 0; i < 4; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);
#else
  send_descriptor(&(lang_desc[0]), sizeof lang_desc);
#endif
@y
  send_descriptor(&(lang_desc[0]), sizeof lang_desc);
@z

@x
#ifdef M
  @<Send manufacturer descriptor@>@;
#else
  send_descriptor(&(mfr_desc[0]), sizeof mfr_desc);
#endif
@y
  send_descriptor(&(mfr_desc[0]), sizeof mfr_desc);
@z

@x
#ifdef M
  @<Send product descriptor@>@;
#else
  send_descriptor(&(prod_desc[0]), sizeof prod_desc);
#endif
@y
  send_descriptor(&(prod_desc[0]), sizeof prod_desc);
@z

@x
case 0x03:
  UDR1 = 'N';
#ifdef M
  buf = &(sn_desc[0]);
  size = sizeof sn_desc;
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
  for (int i = 0; i < 10; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);
#else
  send_descriptor(&(sn_desc[0]), sizeof sn_desc);
#endif
  break;
@y
@z

@x
   S_endpoint_descriptor      ep2;
@y
@z

@x
  @<Initialize element 4...@>, @/
@t\2@> @<Initialize element 5...@> @/
@y
@t\2@> @<Initialize element 4...@> @/
@z

@x
@ @d OUT (0 << 7)

@<Initialize element 5 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_endpoint_descriptor), @/
  0x05, /* endpoint */
  OUT | 2, /* this corresponds to `2' in `ep2' on picture */
  0x03, /* transfers via interrupts\footnote\ddag{Must correspond to
    |UECFG0X| of |EP2|.} */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}
@y
@z

@x
@<Global variables ...@>=
#if 1==1
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x06, 0x00, 0xFF, /* {\bf1} Usage Page (Vendordefined) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf2} Usage (UsageID - 1) */
  0xA1, 0x01, @t\hskip21pt@> /* {\bf3} Collection (Application) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf4} Usage (UsageID - 2) */
  0x15, 0x00, @t\hskip21pt@> /* {\bf5} Logical Minimum (0) */
  0x26, 0xFF, 0x00, /* {\bf6} Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* {\bf7} Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* {\bf8} Report Count (8)\footnote{\dag\dag}{Must
    correspond to |UECFG1X| of |EP1|.} */
  0x81, 0x02, @t\hskip21pt@> /* {\bf9} IN report (Data, Variable, Absolute) */
  0x09, 0x00, @t\hskip21pt@> /* {\bf10} Usage (UsageID - 3) */
  0x15, 0x00, @t\hskip21pt@> /* {\bf11} Logical Minimum (0) */
  0x26, 0xFF,0x00, /* {\bf12} Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* {\bf13} Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* {\bf14} Report Count (8)\footnote{\ddag\ddag}{Must
    correspond to |UECFG1X| of |EP2|.} */
  0x91, 0x02, @t\hskip21pt@> /* {\bf15} OUT report (Data, Variable, Absolute) */
@t\2@> 0xC0 @t\hskip46pt@> /* {\bf16} End Collection */
};
#else
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  HID_USAGE_PAGE @,@, (GENERIC_DESKTOP), @/
  HID_USAGE @,@, (MOUSE), @/
  HID_COLLECTION @,@, (APPLICATION), @t\1@> @/
    HID_USAGE @,@, (POINTER), @/
    HID_COLLECTION @,@, (PHYSICAL), @t\1@> @/
      HID_USAGE_PAGE @,@, (BUTTONS), @/
      HID_USAGE_MINIMUM @,@, (1, 1), @/
      HID_USAGE_MAXIMUM @,@, (1, 3), @/
      HID_LOGICAL_MINIMUM @,@, (1, 0), @/
      HID_LOGICAL_MAXIMUM @,@, (1, 1), @/
      HID_REPORT_COUNT @,@, (3), @/
      HID_REPORT_SIZE @,@, (1), @/
      HID_INPUT @,@, (DATA, VARIABLE, ABSOLUTE), @/
      HID_REPORT_COUNT @,@, (1), @/
      HID_REPORT_SIZE @,@, (5), @/
      HID_INPUT @,@, (CONSTANT), @/
      HID_USAGE_PAGE @,@, (GENERIC_DESKTOP), @/
      HID_USAGE @,@, (X), @/
      HID_USAGE @,@, (Y), @/
      HID_LOGICAL_MINIMUM @,@, (1, -127), @/
      HID_LOGICAL_MAXIMUM @,@, (1, 127), @/
      HID_REPORT_SIZE @,@, (8), @/
      HID_REPORT_COUNT @,@, (2), @/
    @t\2@> HID_INPUT @,@, (DATA, VARIABLE, RELATIVE), @/
  @t\2@> HID_END_COLLECTION @,@, (PHYSICAL), @/
@t\2@> HID_END_COLLECTION @,@, (APPLICATION) @/
};
#endif
@y
@<Global variables ...@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
0x05, 0x01, @/
0x09, 0x06, @/
0xA1, 0x01, @/
0x05, 0x07, @/
0x19, 0xE0, @/
0x29, 0xE7, @/
0x15, 0x00, @/
0x25, 0x01, @/
0x75, 0x01, @/
0x95, 0x08, @/
0x81, 0x02, @/
0x95, 0x01, @/
0x75, 0x08, @/
0x81, 0x01, @/
0x05, 0x08, @/
0x19, 0x01, @/
0x29, 0x05, @/
0x95, 0x05, @/
0x75, 0x01, @/
0x91, 0x02, @/
0x95, 0x01, @/
0x75, 0x03, @/
0x91, 0x01, @/
0x15, 0x00, @/
0x26, 0xff, @/
0x00, 0x05, @/
0x07, 0x19, @/
0x00, 0x29, @/
0xff, 0x95, @/
0x06, 0x75, @/
0x08, 0x81, @/
@t\2@> 0x00, 0xC0
};
@z

@x
@ @<Send manufacturer descriptor@>=
buf = &(mfr_desc[0]);
size = sizeof mfr_desc;
if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
while (!(UEINTX & (1 << TXINI))) ;
for (int i = 0; i < 12; i++)
  UEDATX = pgm_read_byte_near((unsigned int) buf++);
UEINTX &= ~(1 << TXINI);
while (!(UEINTX & (1 << NAKOUTI))) ;
UEINTX &= ~(1 << NAKOUTI);
while (!(UEINTX & (1 << RXOUTI))) ;
UEINTX &= ~(1 << RXOUTI);
@y
@z

@x
@ @<Send product descriptor@>=
buf = &(prod_desc[0]);
size = sizeof prod_desc;
if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
while (!(UEINTX & (1 << TXINI))) ;
int i = 0;
for (; i < 32; i++)
  UEDATX = pgm_read_byte_near((unsigned int) buf++);
UEINTX &= ~(1 << TXINI);
while (!(UEINTX & (1 << TXINI))) ;
for (; i < 34; i++)
  UEDATX = pgm_read_byte_near((unsigned int) buf++);
UEINTX &= ~(1 << TXINI);
while (!(UEINTX & (1 << NAKOUTI))) ;
UEINTX &= ~(1 << NAKOUTI);
while (!(UEINTX & (1 << RXOUTI))) ;
UEINTX &= ~(1 << RXOUTI);
@y
@z

@x
@*1 Serial number descriptor.

@<Global \null variables@>=
const uint8_t sn_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x0A, /* size */
  0x03, /* type (string) */
@t\2@> '0', 0, '0', 0, '0', 0, '0', 0 /* set only what is in quotes */
};
@y
@z
