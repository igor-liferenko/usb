\let\lheader\rheader
%\datethis
\secpagedepth=2 % begin new page only on *

@* Program. This embedded application source code illustrates how to implement a HID
with the ATmega32U4 controller.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3} (use \.{http://www.engbedded.com/fusecalc}).

@d EP0 0
@d EP1 1
@d EP2 2
@d EP0_SIZE 32 /* bytes */

@d M /* microsin.net/programming/avr-working-with-usb/usb-device-on-assembler.html */

@c
@<Header files@>@;
@<Functions@>@;
@<Type \null definitions@>@;
@<Global \null variables@>@;
int flag = 0;

void main(void)
{
  UHWCON = 1 << UVREGE;
  cli();
  wdt_reset();
  MCUSR &= ~(1<<WDRF);
  WDTCSR |= (1<<WDCE) | (1<<WDE);
  WDTCSR = 0;
  DDRB |= 1 << PB0; /* debug */
  DDRC |= 1 << PC7; /* reset */
  PORTC |= 1 << PC7;
  PLLCSR = (1 << PINDIV) | (1 << PLLE);
  while (!(PLLCSR & (1 << PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  while (!(USBSTA & (1 << VBUS))) ;
  UDCON &= ~(1 << DETACH);
  while (!(UDINT & (1 << EORSTI))) ;
  UDINT &= ~(1 << EORSTI);
  UENUM = EP0;
  UECONX |= 1 << EPEN;
  UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) | (0 << EPDIR); /* control, OUT */
  UECFG1X = (0 << EPBK0) | (1 << EPSIZE1) + (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 32
    bytes\footnote\dag{Must correspond to |bMaxPacketSize0| in |dev_desc|.} */
  while (!(UESTA0X & (1 << CFGOK))) ;
  UDCON |= 1 << RSTCPU;
  UDIEN = (1 << SUSPE) | (1 << EORSTE);
  UEIENX = 1 << RXSTPE;
  SMCR = 1 << SE;
  sei();
  while (1) ;
}

@ The trick here is that order of checking matters (as multiple bits can be set in |UDINT|).

@c
ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
  }
  else if (UDINT & (1 << SUSPI)) {
    UDINT &= ~(1 << SUSPI);
    USBCON |= 1 << FRZCLK;
    PLLCSR &= ~(1 << PLLE);
    UDIEN |= 1 << WAKEUPE;
  }
  else if (UDINT & (1 << WAKEUPI)) {
    PLLCSR |= 1 << PLLE;
    while (!(PLLCSR & (1 << PLOCK))) ;
    USBCON &= ~(1 << FRZCLK);
    UDINT &= ~(1 << WAKEUPI);
    UDIEN &= ~(1 << WAKEUPE);
    UENUM = EP0;
    flag = 1;
  }
}

@ @c
ISR(USB_COM_vect)
{
  if (UEINT == (1 << EP0)) {
    uint8_t bmRequestType = UEDATX;
    uint8_t bRequest = UEDATX;
    uint8_t bDescriptorType;
    uint16_t wLength;
    int index;
    const void *buf;
    int size;
    switch (bRequest)
    {
    case 0x06: /* TODO: first check bmRequestType, not bRequest, like bRequest
      is checked before bDescriptorType, not after */
      /* TODO: this bRequest is for two requests - device descriptor and hid report descriptor */
      @<get\_dsc@>@;
      break;
    case 0x05: @/
      @<set\_adr@>@;
      break;
    case 0x09:
      if (bmRequestType == 0x00) {
        @<set\_cfg@>@;
      } /* TODO: what is SET\_REPORT ? (its bRequest is also 0x09) */
      break;
    case 0x0A:
      if (bmRequestType == 0x21) {
        @<set\_idle@>@;
      }
      break;
    default: @/
      UEINTX &= ~(1 << RXSTPI);
      @<Stall@>@;
    }
  }
  else if (UEINT == (1 << EP1)) {
//ep\_in
  }
  else if (UEINT == (1 << EP2)) {
//ep\_out
  }
}

@ @<get\_dsc@>=
switch (bmRequestType)
{
case 0x80: @/
  @<stand\_desc@>@;
  break;
case 0x81: @/
  @<int\_desc@>@;
  break;
default: @/
  UEINTX &= ~(1 << RXSTPI);
  @<Stall@>@;
}

@ @<set\_adr@>=
UDADDR = UEDATX & 0x7F;
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  if (!(UEINTX & (1 << TXINI))) break;
#endif

UEINTX &= ~(1 << TXINI);

while (!(UEINTX & (1 << TXINI))) ; /* wait until ZLP, prepared by previous command, is
  sent to host\footnote{$\sharp$}{According to \S22.7 of the datasheet,
  firmware must send ZLP in the STATUS stage before enabling the new address.
  The reason is that the request started by using zero address, and all the stages of the request
  must use the same address.
  Otherwise STATUS stage will not complete, and thus set address request will not succeed.
  We can determine when ZLP is sent by receiving the ACK, which sets TXINI to 1.
  See ``Control write (by host)'' in table of contents for the picture (note that DATA
  stage is absent).} */
UDADDR |= 1 << ADDEN;

@ @<set\_cfg@>=
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
#endif

UEINTX &= ~(1 << TXINI);

UENUM = EP1;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1) + (1 << EPTYPE0) | (1 << EPDIR); /* interrupt\footnote\dag
{Must correspond to IN endpoint description in |@<Initialize element 4...@>|.}, IN */
UECFG1X = (0 << EPBK0) | (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 8 bytes\footnote
{\dag\dag}{Must correspond to IN endpoint description in |hid_report_descriptor|.} */
while (!(UESTA0X & (1 << CFGOK))) ;

UENUM = EP2;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1) + (1 << EPTYPE0) | (0 << EPDIR); /* interrupt\footnote\ddag
{Must correspond to OUT endpoint description in |@<Initialize element 5...@>|.}, OUT */
UECFG1X = (0 << EPBK0) | (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 8 bytes\footnote
{\ddag\ddag}{Must correspond to OUT endpoint description in |hid_report_descriptor|.} */
while (!(UESTA0X & (1 << CFGOK))) ;

UENUM = EP0;

@ @<set\_idle@>=
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  if (!(UEINTX & (1 << TXINI))) break;
#endif

UEINTX &= ~(1 << TXINI);

if (flag == 1) {
  flag = 0;
  UENUM = EP2;
}

@ @<stand\_desc@>=
@<Read buffer@>@;
UEINTX &= ~(1 << RXSTPI);
switch (bDescriptorType)
{
case 0x01: @/
  @<d\_dev@>@;
  break;
case 0x02: @/
  @<d\_con@>@;
  break;
case 0x03: @/
  @<d\_str@>@;
  break;
default: @/
  @<Stall@>@;
}

@ @<int\_desc@>=
@<Read buffer@>@;
UEINTX &= ~(1 << RXSTPI);
if (bDescriptorType == 0x22 && wLength == sizeof hid_report_descriptor) { /* WinXP bug is here */
@^WinXP bug@>
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
  UEIENX = 1 << RXOUTE;
}

@ @<d\_dev@>=
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

@ @<d\_con@>=
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

@ @<d\_str@>=
switch (index)
{
case 0x00:
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
  break;
case 0x01:
#ifdef M
  @<Send manufacturer descriptor@>@;
#else
  send_descriptor(&(mfr_desc[0]), sizeof mfr_desc);
#endif
  break;
case 0x02:
#ifdef M
  @<Send product descriptor@>@;
#else
  send_descriptor(&(prod_desc[0]), sizeof prod_desc);
#endif
  break;
case 0x03:
  buf = &(sn_desc[0]);
  size = sizeof sn_desc;
#ifdef M
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
}

@ @<Read buffer@>=
index = UEDATX;
bDescriptorType = UEDATX;
(void) UEDATX;
(void) UEDATX;
((uint8_t *) &wLength)[0] = UEDATX;
((uint8_t *) &wLength)[1] = UEDATX;

@ See datasheet \S22.12.2.

@<Functions@>=
void send_descriptor(const void *buf, int size)
{
#if 1==1 /* FIXME: where is it said in datasheet on USB spec that the last packet full check
  is necessary? */
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE)
        break;
      UEDATX = pgm_read_byte_near((unsigned int) buf++);
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
#else
  int last_packet_full = 0;
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE) {
        last_packet_full = 1;
        break;
      }
      UEDATX = pgm_read_byte_near((unsigned int) buf++);
      size--;
    }
    if (nb_byte == 0) {
      if (last_packet_full)
        UEINTX &= ~(1 << TXINI);
    }
    else
      UEINTX &= ~(1 << TXINI);
    if (nb_byte != EP0_SIZE)
      last_packet_full = 0;
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
#endif
}

@ @<Stall@>=
#ifdef M
  if (!(UEINTX & (1 << TXINI))) PORTB |= 1 << PB0;
  while (!(UEINTX & (1 << TXINI))) ;
#endif

UECONX |= 1 << STALLRQ;

@* Control endpoint management.

@*1 Control read (by host). There are the folowing
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to6cm{\vbox to0.94cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=1700}}\hfil}$$

$$\hbox to10cm{\vbox to11.87cm{\vfil\special{psfile=control-read-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=2834}}\hfil}$$

$$\hbox to12.5cm{\vbox to4.22cm{\vfil\special{psfile=control-IN.eps
  clip llx=0 lly=0 urx=1206 ury=408 rwi=3543}}\hfil}$$

@ This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

@*1 Control write (by host). There are the following
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to6cm{\vbox to0.94cm{\vfil\special{psfile=direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=1700}}\hfil}$$

$$\hbox to10cm{\vbox to11.87cm{\vfil\special{psfile=control-write-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=2834}}\hfil}$$

$$\hbox to16cm{\vbox to4.39cm{\vfil\special{psfile=control-OUT.eps
  clip llx=0 lly=0 urx=1474 ury=405 rwi=4535}}\hfil}$$

Commentary to the drawing why ``controller will not necessarily send a NAK at the first IN token''
(see \S22.12.1 in datasheet): If TXINI is already cleared when IN packet arrives, NAKINI is not
set. This corresponds to case 1. If TXINI is not yet cleared when IN packet arrives, NAKINI
is set. This corresponds to case 2.

@ This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

@* USB stack.

The order of descriptors here matches the order in which they are transmitted.

@*1 Device descriptor.

@<Type \null definitions@>=
typedef struct {
  uint8_t      bLength;
  uint8_t      bDescriptorType;
  uint16_t     bcdUSB; /* Binay Coded Decimal Spec. release */
  uint8_t      bDeviceClass; /* class code assigned by the USB */
  uint8_t      bDeviceSubClass; /* sub-class code assigned by the USB */
  uint8_t      bDeviceProtocol; /* protocol code assigned by the USB */
  uint8_t      bMaxPacketSize0; /* max packet size for EP0 */
  uint16_t     idVendor;
  uint16_t     idProduct;
  uint16_t     bcdDevice; /* device release number */
  uint8_t      iManufacturer; /* index of manu. string descriptor */
  uint8_t      iProduct; /* index of prod. string descriptor */
  uint8_t      iSerialNumber; /* index of S.N. string descriptor */
  uint8_t      bNumConfigurations;
} S_device_descriptor;

@ @<Global \null variables@>=
const S_device_descriptor dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  sizeof (S_device_descriptor), @/
  0x01, /* device */
  0x0110, /* USB version 1.1 */
  0, /* no class */
  0, /* no subclass */
  0, @/
  EP0_SIZE, /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP0|.} */
  0x03EB, /* ATMEL */
  0x2013, /* standard Human Interaction Device */
  0x1000, /* from Atmel demo */
  0x01, /* (\.{Mfr} in \.{kern.log}) */
  0x02, /* (\.{Product} in \.{kern.log}) */
  0x03, /* (\.{SerialNumber} in \.{kern.log}) */
@t\2@> 1 /* one configuration for this device */
};

@*1 User configuration descriptor.

$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=hid-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$

@<Type \null definitions@>=
@<Type definitions used in user configuration descriptor@>@;
typedef struct {
   S_configuration_descriptor conf_desc;
   S_interface_descriptor     ifc;
   S_hid_descriptor           hid;
   S_endpoint_descriptor      ep1;
   S_endpoint_descriptor      ep2;
} S_user_configuration_descriptor;

@ @<Global \null variables@>=
@<Global variables used in user configuration descriptor@>@;
const S_user_configuration_descriptor user_conf_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize element 1...@>, @/
  @<Initialize element 2...@>, @/
  @<Initialize element 3...@>, @/
  @<Initialize element 4...@>, @/
@t\2@> @<Initialize element 5...@> @/
};

@*2 Configuration descriptor.

@s S_configuration_descriptor int

@<Type definitions ...@>=
typedef struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint16_t     wTotalLength;
   uint8_t      bNumInterfaces;
   uint8_t      bConfigurationValue; /* number between 1 and |bNumConfigurations|, for
     each configuration\footnote\dag{For some reason
     configurations start numbering with `1', and interfaces and altsettings with `0'.} */
   uint8_t      iConfiguration; /* index of string descriptor */
   uint8_t      bmAttibutes;
   uint8_t      MaxPower;
} S_configuration_descriptor;

@ @<Initialize element 1 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_configuration_descriptor), @/
  0x02, /* configuration descriptor */
  sizeof (S_user_configuration_descriptor), @/
  1, /* one interface in this configuration */
  1, /* this corresponds to `1' in `cfg1' on picture */
  0, /* no string descriptor */
  0x80, /* device is powered from bus */
@t\2@> 0x32 /* device uses 100mA */
}

@*2 Interface descriptor.

@s S_interface_descriptor int

@<Type definitions ...@>=
typedef struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint8_t      bInterfaceNumber; /* number between 0 and |bNumInterfaces-1|, for
                                     each interface */
   uint8_t      bAlternativeSetting; /* number starting from 0, for each interface */
   uint8_t      bNumEndpoints; /* number of EP except EP 0 */
   uint8_t      bInterfaceClass; /* class code assigned by the USB */
   uint8_t      bInterfaceSubClass; /* sub-class code assigned by the USB */
   uint8_t      bInterfaceProtocol; /* protocol code assigned by the USB */
   uint8_t      iInterface; /* index of string descriptor */
}  S_interface_descriptor;

@ @<Initialize element 2 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_interface_descriptor), @/
  0x04, /* interface descriptor */
  0, /* this corresponds to `0' in `if0' on picture */
  0, /* this corresponds to `0' in `alt0' on picture */
  0x02, /* two endpoints are used */
  0x03, /* HID */
  0, /* no subclass */
  0, @/
@t\2@> 0 /* no string descriptor */
}

@*2 HID descriptor.

@s S_hid_descriptor int

@<Type definitions ...@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bReportDescriptorType;
  uint16_t wDescriptorLength;
} S_hid_descriptor;

@ @<Initialize element 3 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_hid_descriptor), @/
  0x21, /* HID */
  0x0100, /* HID version 1.0 */
  0x00, /* no localization */
  0x01, /* one descriptor for this device */
  0x22, /* HID report */
@t\2@> sizeof hid_report_descriptor @/
}

@*2 Endpoint descriptor.

@s S_endpoint_descriptor int

@<Type definitions ...@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bEndpointAddress;
  uint8_t bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t bInterval; /* interval for polling EP by host to determine if data is available (ms-1) */
} S_endpoint_descriptor;

@ @d IN (1 << 7)

@<Initialize element 4 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_endpoint_descriptor), @/
  0x05, /* endpoint */
  IN | 1, /* this corresponds to `1' in `ep1' on picture */
  0x03, /* transfers via interrupts\footnote\dag{Must correspond to
    |UECFG0X| of |EP1|.} */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}

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

@*1 HID report descriptor.

@<Global variables ...@>=
#if 1==1
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x06, 0x00, 0xFF, /* Usage Page (Vendordefined) */
  0x09, 0x00, @t\hskip21pt@> /* Usage (UsageID - 1) */
  0xA1, 0x01, @t\hskip21pt@> /* Collection (Application) */
  0x09, 0x00, @t\hskip21pt@> /* Usage (UsageID - 2) */
  0x15, 0x00, @t\hskip21pt@> /* Logical Minimum (0) */
  0x26, 0xFF, 0x00, /* Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* data unit size in bits (8, one byte) */
  0x95, 0x08, @t\hskip21pt@> /* number of data units (8)\footnote{\dag\dag}{Must correspond to
    |UECFG1X| of |EP1|.} */
  0x81, 0x02, @t\hskip21pt@> /* IN report (Data, Variable, Absolute) */
  0x09, 0x00, @t\hskip21pt@> /* Usage (UsageID - 3) */
  0x15, 0x00, @t\hskip21pt@> /* Logical Minimum (0) */
  0x26, 0xFF,0x00, /* Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* data unit size in bits (8, one byte) */
  0x95, 0x08, @t\hskip21pt@> /* number of data units (8)\footnote{\ddag\ddag}{Must correspond to
    |UECFG1X| of |EP2|.} */
  0x91, 0x02, @t\hskip21pt@> /* OUT report (Data, Variable, Absolute) */
@t\2@> 0xC0 @t\hskip46pt@> /* End Collection */
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

@*1 Language descriptor.

This is necessary to transmit serial number.

@<Global \null variables@>=
const uint8_t lang_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x04, /* size */
  0x03, /* type (string) */
@t\2@> 0x09,0x04 /* id (English) */
};

@*1 Manufacturer descriptor.

@<Global \null variables@>=
const uint8_t mfr_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x0C, @/
  0x03, @/
@t\2@> 0x41,0x00,0x54,0x00,0x4D,0x00,0x45,0x00,0x4C,0x00 @/
};

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

@*1 Product descriptor.

@<Global \null variables@>=
const uint8_t prod_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x22, @/
  0x03, @/
  0x41,0x00,0x56,0x00,0x52,0x00,0x20,0x00,0x55,0x00,0x53, @/
  0x00,0x42,0x00,0x20,0x00,0x48,0x00,0x49,0x00,0x44,0x00, @/
@t\2@> 0x20,0x00,0x44,0x00,0x45,0x00,0x4D,0x00,0x4F,0x00 @/
};

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

@*1 Serial number descriptor.

@<Global \null variables@>=
const uint8_t sn_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x0A, /* size */
  0x03, /* type (string) */
@t\2@> '0', 0, '0', 0, '0', 0, '0', 0 /* set only what is in quotes */
};

@* Headers.
\secpagedepth=1 % index on current page

@<Header files@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
#include "hid_def.h"

@* Index.
