\let\lheader\rheader
%\datethis
\secpagedepth=2 % begin new page only on *

@* Program.

@d EP0 0
@d EP1 1
@d EP2 2

@d M

@c
@<Header files@>@;
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
  UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) + (0 << EPDIR);
  UECFG1X = (0 << EPBK0) + (2 << EPSIZE0) + (1 << ALLOC);
  while (!(UESTA0X & (1 << CFGOK))) ;
  UDCON |= 1 << RSTCPU;
  UDIEN = (1 << SUSPE) | (1 << EORSTE);
  UEIENX = 1 << RXSTPE;
  SMCR = 1 << SE;
  sei();
  while (1) ;
}
ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    goto out;
  }
  if (UDINT & (1 << SUSPI)) {
    UDINT &= ~(1 << SUSPI);
    USBCON |= 1 << FRZCLK;
    PLLCSR &= ~(1 << PLLE);
    UDIEN |= 1 << WAKEUPE;
    goto out;
  }
  if (UDINT & (1 << WAKEUPI)) {
    PLLCSR |= 1 << PLLE;
    while (!(PLLCSR & (1 << PLOCK))) ;
    USBCON &= ~(1 << FRZCLK);
    UDINT &= ~(1 << WAKEUPI);
    UDIEN &= ~(1 << WAKEUPE);
    UENUM = EP0;
    flag = 1;
  }
out:;
}
ISR(USB_COM_vect)
{
  if (UEINT == (1 << EP0)) {
    uint8_t bmRequestType = UEDATX;
    uint8_t bRequest = UEDATX;
    if (bRequest == 0x06) { // TODO: first check bmRequestType, not bRequest
      @<get\_dsc@>@;
      goto out;
    }
    if (bRequest == 0x05) {
      @<set\_adr@>@;
      goto out;
    }
    if (bRequest == 0x09 && bmRequestType == 0x00) {
      @<set\_cfg@>@;
      goto out;
    }
    /* TODO: what is SET\_REPORT ? (its bRequest is also 0x09) */
    if (bRequest == 0x0A && bmRequestType == 0x21) {
      @<set\_idle@>@;
      goto out;
    }
    UEINTX &= ~(1 << RXSTPI);
    @<Stall@>@;
    goto out;
  }
  if (UEINT == (1 << EP1)) {
//ep\_in
  }
  if (UEINT == (1 << EP2)) {
//ep\_out
  }
out:;
}

@ @<get\_dsc@>=
if (bmRequestType == 0x80) {
  @<stand\_desc@>@;
  goto out;
}
if (bmRequestType == 0x81) {
  @<int\_desc@>@;
  goto out;
}

@ @<set\_adr@>=
UDADDR = UEDATX & 0x7F;
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  if (!(UEINTX & (1 << TXINI))) goto out;
  UEINTX &= ~(1 << TXINI);
#else
  UEINTX &= ~(1 << TXINI);
#endif

while (!(UEINTX & (1 << TXINI))) ;
UDADDR |= 1 << ADDEN;

@ @<set\_cfg@>=
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  while (!(UEINTX & (1 << TXINI))) ;
  UEINTX &= ~(1 << TXINI);
#else
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << TXINI))) ;
#endif

UENUM = EP1;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1)+(1 << EPTYPE0)+(1 << EPDIR);
UECFG1X = 0x02; /* ? << EPBK0  ? << EPSIZE0  ? << ALLOC */
while (!(UESTA0X & (1 << CFGOK))) ;

UENUM = EP2;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1)+(1 << EPTYPE0)+(0 << EPDIR);
UECFG1X = 0x02; /* ? << EPBK0  ? << EPSIZE0  ? << ALLOC */
while (!(UESTA0X & (1 << CFGOK))) ;

UENUM = EP0;

@ @<set\_idle@>=
UEINTX &= ~(1 << RXSTPI);

#ifdef M
  if (!(UEINTX & (1 << TXINI))) goto out;
  UEINTX &= ~(1 << TXINI);
#else
  UEINTX &= ~(1 << TXINI);
#endif

if (flag == 1) {
  flag = 0;
  UENUM = EP2;
}

@ @<stand\_desc@>=
@<Read buffer@>@;
if (bDescriptorType == 0x01) {
  @<d\_dev@>@;
  goto out;
}
if (bDescriptorType == 0x02) {
  @<d\_con@>@;
  goto out;
}
if (bDescriptorType == 0x03) {
  //d\_str
}
@<Stall@>@;

@ @<int\_desc@>=
@<Read buffer@>@;
if (bDescriptorType == 0x22 && wLength == sizeof hid_report_descriptor) {

#ifdef M
  while (!(UEINTX & (1 << TXINI))) ;
  const void *buf = &(hid_report_descriptor[0]);
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
  const void *buf = &(hid_report_descriptor[0]);
  int size = wLength;
  @<Write buffer@>@;
#endif

  UENUM = EP2;
  UEIENX = 1 << RXOUTE;
}

@ @<d\_dev@>=
#ifdef M
  /* this is from microsin */
  while (!(UEINTX & (1 << TXINI))) ;
  const void *buf = &dev_desc.bLength;
  for (int i = 0; i < sizeof dev_desc; i++)
    UEDATX = pgm_read_byte_near((unsigned int) buf++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);
#else
  if (!(UEINTX & (1 << TXINI))) {DDRC|=1<<PC7;PORTC|=1<<PC7;} // debug
  /* this is from datasheet 22.12.2 */
  const void *buf = &dev_desc.bLength;
  int size = sizeof dev_desc; /* TODO: reduce |size| to |wLength| if it exceeds it */
  @<Write buffer@>@;
#endif

@ @<d\_con@>=
#ifdef M
  /* this is from microsin */
  while (!(UEINTX & (1 << TXINI))) ;
  const void *buf = &user_conf_desc.conf_desc.bLength;
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
  /* this is from datasheet */
  const void *buf = &user_conf_desc.conf_desc.bLength;
  int size = wLength;
  @<Write buffer@>@;
#endif

@ @<Read buffer@>=
(void) UEDATX;
uint8_t bDescriptorType = UEDATX;
(void) UEDATX;
(void) UEDATX;
uint16_t wLength;
((uint8_t *) &wLength)[0] = UEDATX;
((uint8_t *) &wLength)[1] = UEDATX;
UEINTX &= ~(1 << RXSTPI);

@ @<Write buffer@>=
int last_packet_full = 0;
while (1) {
  int nb_byte = 0;
  while (size != 0) {
    if (nb_byte++ == 32) {
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
  if (nb_byte != 32)
    last_packet_full = 0;
  while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
  if (UEINTX & (1 << RXOUTI)) {
    UEINTX &= ~(1 << RXOUTI);
    break;
  }
}

@ @<Stall@>=
#ifdef M
  while (!(UEINTX & (1 << TXINI))) ;
#endif

UECONX |= 1 << STALLRQ;

@* USB.

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
  32, /* 32 bytes */
  0x03EB, /* ATMEL */
  0x2013, /* standard Human Interaction Device */
  0x1000, /* from Atmel demo */
  0x0, /* (\.{Mfr} in \.{kern.log}) */
  0x0, /* (\.{Product} in \.{kern.log}) */
  0x0, /* (\.{SerialNumber} in \.{kern.log}) */
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
   uint8_t      bConfigurationValue; /* number between 0 and |bNumConfigurations-1|, for
                                        each configuration */
   uint8_t      iConfiguration; /* index of string descriptor */
   uint8_t      bmAttibutes;
   uint8_t      MaxPower;
} S_configuration_descriptor;

@ @<Initialize element 1 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_configuration_descriptor), @/
  0x02, /* configuration descriptor */
  sizeof (S_user_configuration_descriptor), @/
  1, /* one interface in this configuration */
  0, /* \vb{cfg0} */
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
  0, /* \vb{if0} */
  0, /* \vb{alt0} */
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

@ @<Initialize element 4 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_endpoint_descriptor), @/
  0x05, /* endpoint */
  0x81, /* IN */
  0x03, /* transfers via interrupts */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}

@ @<Initialize element 5 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_endpoint_descriptor), @/
  0x05, /* endpoint */
  0x02, /* OUT */
  0x03, /* transfers via interrupts */
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
  0x75, 0x08, @t\hskip21pt@> /* Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* Report Count (8) */
  0x81, 0x02, @t\hskip21pt@> /* IN report (Data, Variable, Absolute) */
  0x09, 0x00, @t\hskip21pt@> /* Usage (UsageID - 3) */
  0x15, 0x00, @t\hskip21pt@> /* Logical Minimum (0) */
  0x26, 0xFF,0x00, /* Logical Maximum (255) */
  0x75, 0x08, @t\hskip21pt@> /* Report Size (8) */
  0x95, 0x08, @t\hskip21pt@> /* Report Count (8) */
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

@* Headers.
\secpagedepth=1 % index on current page

@<Header files@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
#include "hid_def.h"

@* Index.
