@ @c
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
typedef unsigned char U8;
typedef unsigned short U16;
@<Type definitions@>@;
@<Create device descriptor |dev_desc|@>@;
@<Create user configuration descriptor |con_desc|@>@;
#define EP0 0
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
          const void *buf = &usb_con_desc.cfg.bLength;
          if (wLength == 9) {
            output first 9 bytes
            UEINTX &= ~(1 << TXINI);
            while (!(UEINTX & (1 << NAKOUTI))) ;
            UEINTX &= ~(1 << NAKOUTI);
            while (!(UEINTX & (1 << RXOUTI))) ;
            UEINTX &= ~(1 << RXOUTI);
            goto out;
          }
          else {
            output first 32 bytes
            UEINTX &= ~(1 << TXINI);
            while (!(UEINTX & (1 << TXINI))) ;
            output remaininig bytes
            UEINTX &= ~(1 << TXINI);
            while (!(UEINTX & (1 << NAKOUTI))) ;
            UEINTX &= ~(1 << NAKOUTI);
            while (!(UEINTX & (1 << RXOUTI))) ;
            UEINTX &= ~(1 << RXOUTI);
            goto out;
          }
#else
/* this is from datasheet */
          if (wLength == sizeof (S_usb_configuration_descriptor)) {
            const void *buf = &usb_con_desc.cfg.bLength;
            int size = sizeof (S_usb_configuration_descriptor); /* TODO: reduce |size| to |wLength| if
                                                                   it exceeds it */
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
          }
          else {
            const void *buf = &usb_con_desc.cfg.bLength;
            int size = sizeof (S_usb_user_configuration_descriptor); /* TODO: reduce |size| to
                                                                        |wLength| if it exceeds it */
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
          }
#endif
        }
      }
//      else |sl_1|
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
    }
  }
out:;
}

@*1 Device descriptor.

@<Create device descriptor...@>=
typedef struct {
  U8      bLength;
  U8      bDescriptorType;
  U16     bcdUSB; /* Binay Coded Decimal Spec. release */
  U8      bDeviceClass; /* class code assigned by the USB */
  U8      bDeviceSubClass; /* sub-class code assigned by the USB */
  U8      bDeviceProtocol; /* protocol code assigned by the USB */
  U8      bMaxPacketSize0; /* max packet size for EP0 */
  U16     idVendor;
  U16     idProduct;
  U16     bcdDevice; /* device release number */
  U8      iManufacturer; /* index of manu. string descriptor */
  U8      iProduct; /* index of prod. string descriptor */
  U8      iSerialNumber; /* index of S.N. string descriptor */
  U8      bNumConfigurations;
} S_usb_device_descriptor;

PROGMEM const S_usb_device_descriptor dev_desc = {
  sizeof (S_usb_device_descriptor),
  0x01, /* device */
  0x0110, /* USB version 1.1 */
  0, /* not specified */
  0, /* not specified */
  0, /* not specified */
  32, /* 32 bytes */
  0x03EB, /* ATMEL */
  0x2013, /* standard Human Interaction Device */
  0x1000, /* from Atmel demo */
  0x01, /* (\.{Mfr} in \.{kern.log}) */
  0x02, /* (\.{Product} in \.{kern.log}) */
  0x03, /* (\.{SerialNumber} in \.{kern.log}) */
  1 /* one configuration for this device */
};

@*1 User configuration descriptor.

$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=hid-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$

@<Create user configuration descriptor...@>=
typedef struct {
   S_usb_configuration_descriptor cfg;
   S_usb_interface_descriptor     ifc;
   S_usb_hid_descriptor           hid;
   S_usb_endpoint_descriptor      ep1;
   S_usb_endpoint_descriptor      ep2;
} S_usb_user_configuration_descriptor;

PROGMEM const S_usb_user_configuration_descriptor con_desc = {
  @<Initialize user configuration descriptor element 1@>,
  @<Initialize user configuration descriptor element 2@>,
  @<Initialize user configuration descriptor element 3@>,
  @<Initialize user configuration descriptor element 4@>,
  @<Initialize user configuration descriptor element 5@>
};

@*1 Configuration descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;
   U8      bDescriptorType;
   U16     wTotalLength;
   U8      bNumInterfaces;
   U8      bConfigurationValue; /* value for SetConfiguration resquest */
   U8      iConfiguration; /* index of string descriptor */
   U8      bmAttibutes;
   U8      MaxPower;
} S_usb_configuration_descriptor;

@ @<Initialize user configuration descriptor element 1@>= {
  sizeof (S_usb_configuration_descriptor),
  0x02, /* configuration descriptor */
  sizeof (S_usb_user_configuration_descriptor),
  1, /* one interface in this configuration */
  1, /* ??? */
  0, /* not used */
  0x80, /* device is powered from bus */
  0x32 /* device uses 100mA */
}

@*1 Interface descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;
   U8      bDescriptorType;
   U8      bInterfaceNumber;
   U8      bAlternateSetting;
   U8      bNumEndpoints; /* number of EP except EP 0 */
   U8      bInterfaceClass; /* class code assigned by the USB */
   U8      bInterfaceSubClass; /* sub-class code assigned by the USB */
   U8      bInterfaceProtocol; /* protocol code assigned by the USB */
   U8      iInterface; /* index of string descriptor */
}  S_usb_interface_descriptor;

@ @<Initialize user configuration descriptor element 2@>= {
  sizeof (S_usb_interface_descriptor),
  0x04, /* interface descriptor */
  0, /* ??? */
  0, /* ??? */
  0x02, /* two endpoints are used */
  0x03, /* HID */
  0, /* no subclass */
  0, /* ??? */
  0 /* not specified */
}

@*1 HID descriptor.

@<Type definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t bcdHID;
  uint8_t bCountryCode;
  uint8_t bNumDescriptors;
  uint8_t bDescriptorType;
  uint16_t wDescriptorLength;
} S_usb_hid_descriptor;

@ @<Initialize user configuration descriptor element 3@>= {
  sizeof (S_usb_hid_descriptor),
  0x21, /* HID */
  0x0100, /* HID version 1.0 */
  0x00, /* no localization */
  0x01, /* one descriptor for this device */
  0x22, /* HID report */
  0x0022 /* 34 bytes */
}

@*1 Endpoint descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;
   U8      bDescriptorType;
   U8      bEndpointAddress;
   U8      bmAttributes;
   U16     wMaxPacketSize;
   U8      bInterval; /* interval for polling EP by host to determine if data is available (ms) */
} S_usb_endpoint_descriptor;

@ @<Initialize user configuration descriptor element 4@>= {
  sizeof (S_usb_endpoint_descriptor),
  0x05, /* endpoint */
  0x81, /* IN */
  0x03, /* transfers via interrupts */
  0x0008, /* 8 bytes */
  0x0F /* 15 */
}

@ @<Initialize user configuration descriptor element 5@>= {
  sizeof (S_usb_endpoint_descriptor),
  0x05, /* endpoint */
  0x02, /* OUT */
  0x03, /* transfers via interrupts */
  0x0008, /* 8 bytes */
  0x0F /* 15 */
}