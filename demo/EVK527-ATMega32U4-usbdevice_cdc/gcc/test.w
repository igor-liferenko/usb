\let\lheader\rheader
%\datethis
\secpagedepth=2 % begin new page only on *

@* Program.

@d EP0 0
@d EP1 1
@d EP2 2

@c
@<Header files@>@;
@<Type definitions@>@;
@<Global variables@>@;

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
  UECFG0X = 0x00; /* (0 << EPTYPE1)+(0 << EPTYPE0)+(0 << EPDIR) */
  UECFG1X = 0x22; /* 0 << EPBK0  2 << EPSIZE0  1 << ALLOC */
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
    // flag = 1;
  }
out:;
}
ISR(USB_COM_vect)
{
  if (UEINT == (1 << EP0)) {
    uint8_t bmRequestType = UEDATX;
    uint8_t bRequest = UEDATX;
    if (bRequest == 0x06) { // TODO: first check bmRequestType, not bRequest
      if (bmRequestType == 0x80) {
        (void) UEDATX;
        uint8_t bDescriptorType = UEDATX;
        (void) UEDATX;
        (void) UEDATX;
        uint16_t wLength;
        ((uint8_t *) &wLength)[0] = UEDATX;
        ((uint8_t *) &wLength)[1] = UEDATX;
        UEINTX &= ~(1 << RXSTPI);
        if (bDescriptorType == 0x01) {
#if 1==1
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
#endif
          goto out;
        }
        if (bDescriptorType == 0x02) {
#if 1==1
/* this is from microsin */
          while (!(UEINTX & (1 << TXINI))) ;
          const void *buf = &con_desc.cfg.bLength;
          if (wLength == 9) {
            for (int i = 0; i < 9; i++)
              UEDATX = pgm_read_byte_near((unsigned int) buf++);
            UEINTX &= ~(1 << TXINI);
            while (!(UEINTX & (1 << NAKOUTI))) ;
            UEINTX &= ~(1 << NAKOUTI);
            while (!(UEINTX & (1 << RXOUTI))) ;
            UEINTX &= ~(1 << RXOUTI);
            goto out;
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
            goto out;
          }
#else
/* this is from datasheet */
          const void *buf = &con_desc.cfg.bLength;
          int size = wLength;
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
          goto out;
#endif
        }
      }
      else {
        if (bmRequestType == 0x81) {
          (void) UEDATX;
          uint8_t bDescriptorType = UEDATX;
          (void) UEDATX;
          (void) UEDATX;
          uint16_t wLength;
          ((uint8_t *) &wLength)[0] = UEDATX;
          ((uint8_t *) &wLength)[1] = UEDATX;
          UEINTX &= ~(1 << RXSTPI);
          if (bDescriptorType == 0x01) {
            if (wLength == 34) {
              while (!(UEINTX & (1 << TXINI))) ;
//see asm.S 0x22
            }
          }
        }
      }
    }
    if (bRequest == 0x05) {
      UDADDR = UEDATX & 0x7F;
      UEINTX &= ~(1 << RXSTPI);
#if 1==1
      if (!(UEINTX & (1 << TXINI))) goto out;
      UEINTX &= ~(1 << TXINI);
#else
      UEINTX &= ~(1 << TXINI);
#endif
      while (!(UEINTX & (1 << TXINI))) ;
      UDADDR |= 1 << ADDEN;
      goto out;
    }
    if (bRequest == 0x09 && bmRequestType == 0) {
      UEINTX &= ~(1 << RXSTPI);
#if 1==1
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
      goto out;
    }
  }
out:;
}

@* USB.

@*1 Device descriptor.

@<Type definitions@>=
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
} S_usb_device_descriptor;

@ @<Global variables@>=
const S_usb_device_descriptor dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  sizeof (S_usb_device_descriptor), @/
  0x01, /* device */
  0x0110, /* USB version 1.1 */
  0, /* not specified */
  0, /* not specified */
  0, /* not specified */
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

@<Type definitions@>=
@<User configuration type definitions@>@;
typedef struct {
   S_usb_configuration_descriptor cfg;
   S_usb_interface_descriptor     ifc;
   S_usb_hid_descriptor           hid;
   S_usb_endpoint_descriptor      ep1;
   S_usb_endpoint_descriptor      ep2;
} S_usb_user_configuration_descriptor;

@ @<Global variables@>=
@<HID report descriptor@>@;
const S_usb_user_configuration_descriptor con_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize |con_desc.cfg|@>, @/
  @<Initialize |con_desc.ifc|@>, @/
  @<Initialize |con_desc.hid|@>, @/
  @<Initialize |con_desc.ep1|@>, /* FIXME: why it does not get to the index? */
@t\2@> @<Initialize |con_desc.ep2|@> @/
};

@*2 Configuration descriptor.

@s S_usb_configuration_descriptor int

@<User configuration type definitions@>=
typedef struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint16_t     wTotalLength;
   uint8_t      bNumInterfaces;
   uint8_t      bConfigurationValue; /* value for SetConfiguration resquest */
   uint8_t      iConfiguration; /* index of string descriptor */
   uint8_t      bmAttibutes;
   uint8_t      MaxPower;
} S_usb_configuration_descriptor;

@ @<Initialize |con_desc.cfg|@>= { @t\1@> @/
  sizeof (S_usb_configuration_descriptor), @/
  0x02, /* configuration descriptor */
  sizeof (S_usb_user_configuration_descriptor), @/
  1, /* one interface in this configuration */
  1, /* ??? */
  0, /* not used */
  0x80, /* device is powered from bus */
@t\2@> 0x32 /* device uses 100mA */
}

@*2 Interface descriptor.

@s S_usb_interface_descriptor int

@<User configuration type definitions@>=
typedef struct {
   uint8_t      bLength;
   uint8_t      bDescriptorType;
   uint8_t      bInterfaceNumber;
   uint8_t      bAlternateSetting;
   uint8_t      bNumEndpoints; /* number of EP except EP 0 */
   uint8_t      bInterfaceClass; /* class code assigned by the USB */
   uint8_t      bInterfaceSubClass; /* sub-class code assigned by the USB */
   uint8_t      bInterfaceProtocol; /* protocol code assigned by the USB */
   uint8_t      iInterface; /* index of string descriptor */
}  S_usb_interface_descriptor;

@ @<Initialize |con_desc.ifc|@>= { @t\1@> @/
  sizeof (S_usb_interface_descriptor), @/
  0x04, /* interface descriptor */
  0, /* ??? */
  0, /* ??? */
  0x02, /* two endpoints are used */
  0x03, /* HID */
  0, /* no subclass */
  0, /* ??? */
@t\2@> 0 /* not specified */
}

@*2 HID descriptor.

@s S_usb_hid_descriptor int

@<User configuration type definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t HidDescriptorType;
  uint16_t wDescriptorLength;
} S_usb_hid_descriptor;

@ @<Initialize |con_desc.hid|@>= { @t\1@> @/
  sizeof (S_usb_hid_descriptor), @/
  0x21, /* HID */
  0x0100, /* HID version 1.0 */
  0x00, /* no localization */
  0x01, /* one descriptor for this device */
  0x22, /* HID report */
@t\2@> sizeof hid_report_descriptor @/
}

@*2 Endpoint descriptor.

@s S_usb_endpoint_descriptor int

@<User configuration type definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint8_t bEndpointAddress;
  uint8_t bmAttributes;
  uint16_t wMaxPacketSize;
  uint8_t bInterval; /* interval for polling EP by host to determine if data is available (ms-1) */
} S_usb_endpoint_descriptor;

@ @<Initialize |con_desc.ep1|@>= { @t\1@> @/
  sizeof (S_usb_endpoint_descriptor), @/
  0x05, /* endpoint */
  0x81, /* IN */
  0x03, /* transfers via interrupts */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}

@ @<Initialize |con_desc.ep2|@>= { @t\1@> @/
  sizeof (S_usb_endpoint_descriptor), @/
  0x05, /* endpoint */
  0x02, /* OUT */
  0x03, /* transfers via interrupts */
  0x0008, /* 8 bytes */
@t\2@> 0x0F /* 16 */
}

@*1 HID report descriptor.

@<HID report descriptor@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  HID_USAGE_PAGE (GENERIC_DESKTOP), @/
  HID_USAGE (MOUSE), @/
  HID_COLLECTION (APPLICATION), @t\1@> @/
    HID_USAGE (POINTER), @/
    HID_COLLECTION (PHYSICAL), @t\1@> @/
      HID_USAGE_PAGE (BUTTONS), @/
      HID_USAGE_MINIMUM (1, 1), @/
      HID_USAGE_MAXIMUM (1, 3), @/
      HID_LOGICAL_MINIMUM (1, 0), @/
      HID_LOGICAL_MAXIMUM (1, 1), @/
      HID_REPORT_COUNT (3), @/
      HID_REPORT_SIZE (1), @/
      HID_INPUT (DATA, VARIABLE, ABSOLUTE), @/
      HID_REPORT_COUNT (1), @/
      HID_REPORT_SIZE (5), @/
      HID_INPUT (CONSTANT), @/
      HID_USAGE_PAGE (GENERIC_DESKTOP), @/
      HID_USAGE (X), @/
      HID_USAGE (Y), @/
      HID_LOGICAL_MINIMUM (1, -127), @/
      HID_LOGICAL_MAXIMUM (1, 127), @/
      HID_REPORT_SIZE (8), @/
      HID_REPORT_COUNT (2), @/
    @t\2@> HID_INPUT (DATA, VARIABLE, RELATIVE), @/
  @t\2@> HID_END_COLLECTION (PHYSICAL), @/
@t\2@> HID_END_COLLECTION (APPLICATION) @/
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
