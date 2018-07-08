@ @c
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
typedef unsigned char U8;
typedef unsigned short U16;
@<Type definitions@>@;
@<Initialize |dev_desc|@>@;
@<Initialize |con_desc|@>@;
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
    return;
  }
  if (UDINT & (1 << SUSPI)) {
    UDINT &= ~(1 << SUSPI);
    USBCON |= 1 << FRZCLK;
    PLLCSR &= ~(1 << PLLE);
    UDIEN |= 1 << WAKEUPE;
    return;
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
}
ISR(USB_COM_vect)
{
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;
  if (UEINT == (1 << EP0)) {
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;

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
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;
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
//debug: if (!(UEINTX & (1 << TXINI))) {DDRC|=1<<PC7;PORTC|=1<<PC7;}
/* this is from datasheet 22.12.2 */
  const void *buf = &dev_desc.bLength;
  int size = sizeof dev_desc;
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
          return;
        }
        if (bDescriptorType == 0x02) {
#if 1==1
          while (!(UEINTX & (1 << TXINI))) ;
#else

#endif
        }
      }
//      else sl_1
    }
    if (bRequest == 0x05) {
      UDADDR = UEDATX & 0x7F;
      UEINTX &= ~(1 << RXSTPI);
#if 1==1
      if (!(UEINTX & (1 << TXINI))) return;
      UEINTX &= ~(1 << TXINI);
#else
      UEINTX &= ~(1 << TXINI);
#endif
      while (!(UEINTX & (1 << TXINI))) ;
      UDADDR |= 1 << ADDEN;
    }
  }
}

@*1 Device descriptor.

@<Type definitions@>=
typedef struct {
  U8      bLength;              //!< Size of this descriptor in bytes
  U8      bDescriptorType;      //!< DEVICE descriptor type
  U16     bscUSB;               //!< Binay Coded Decimal Spec. release
  U8      bDeviceClass;         //!< Class code assigned by the USB
  U8      bDeviceSubClass;      //!< Sub-class code assigned by the USB
  U8      bDeviceProtocol;      //!< Protocol code assigned by the USB
  U8      bMaxPacketSize0;      //!< Max packet size for EP0
  U16     idVendor;             //!< Vendor ID. ATMEL = 0x03EB
  U16     idProduct;            //!< Product ID assigned by the manufacturer
  U16     bcdDevice;            //!< Device release number
  U8      iManufacturer;        //!< Index of manu. string descriptor
  U8      iProduct;             //!< Index of prod. string descriptor
  U8      iSerialNumber;        //!< Index of S.N.  string descriptor
  U8      bNumConfigurations;   //!< Number of possible configurations
} S_usb_device_descriptor;

@ @<Initialize |dev_desc|@>=
PROGMEM const S_usb_device_descriptor dev_desc = {
  sizeof (S_usb_device_descriptor),
  0x01, /* device */
  0x0110, /* bcdUSB */
  0, /* device class */
  0, /* subclass */
  0, /* device protocol */
  32, /* control endpoint size */
  0x03EB,
  0x2013,
  0x1000,
  0x01, /* iManufacturer ("Mfr=" in kern.log) */
  0x02, /* iProduct ("Product=" in kern.log) */
  0x03, /* iSerialNumber ("SerialNumber=" in kern.log) */
  1 /* number of configurations */
};

@*1 User configuration descriptor.

@<Type definitions@>=
typedef struct {
   S_usb_configuration_descriptor cfg;
   S_usb_interface_descriptor     ifc;
   S_usb_hid_descriptor           hid;
   S_usb_endpoint_descriptor      ep1;
   S_usb_endpoint_descriptor      ep2;
} S_usb_user_configuration_descriptor;

@ @<Initialize |con_desc|@>=
PROGMEM const S_usb_user_configuration_descriptor con_desc = {
  @<Initialize |cfg|@>,
  @<Initialize |ifc|@>,
  @<Initialize |hid|@>,
  @<Initialize |ep1|@>,
  @<Initialize |ep2|@>
};

@*1 Configuration descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;              //!< size of this descriptor in bytes
   U8      bDescriptorType;      //!< CONFIGURATION descriptor type
   U16     wTotalLength;         //!< total length of data returned
   U8      bNumInterfaces;       //!< number of interfaces for this conf.
   U8      bConfigurationValue;  //!< value for SetConfiguration resquest
   U8      iConfiguration;       //!< index of string descriptor
   U8      bmAttibutes;          //!< Configuration characteristics
   U8      MaxPower;             //!< maximum power consumption
} S_usb_configuration_descriptor;

@ @<Initialize |cfg|@>= {
  sizeof (S_usb_configuration_descriptor),
  0x02,
  0x0029,
  1,
  1,
  0,
  0x80,
  0x32
}

@*1 Interface descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;               //!< size of this descriptor in bytes
   U8      bDescriptorType;       //!< INTERFACE descriptor type
   U8      bInterfaceNumber;      //!< Number of interface
   U8      bAlternateSetting;     //!< value to select alternate setting
   U8      bNumEndpoints;         //!< Number of EP except EP 0
   U8      bInterfaceClass;       //!< Class code assigned by the USB
   U8      bInterfaceSubClass;    //!< Sub-class code assigned by the USB
   U8      bInterfaceProtocol;    //!< Protocol code assigned by the USB
   U8      iInterface;            //!< Index of string descriptor
}  S_usb_interface_descriptor;

@ @<Initialize |ifc|@>= {
  sizeof (S_usb_interface_descriptor),
  0x04,
  0,
  0,
  0x02,
  0x03,
  0,
  0,
  0
}

@*1 HID descriptor.

@<Type definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  uint16_t myHidVersion;
  uint8_t myCountryCode;
  uint8_t myNumDescriptors;
  uint8_t myDescriptorType;
  uint16_t myReportLength;
} S_usb_hid_descriptor;

@ @<Initialize |hid|@>= {
  sizeof (S_usb_hid_descriptor),
  0x21,
  0x0100,
  0x00,
  0x01,
  0x22,
  0x0022
}

@*1 Endpoint descriptor.

@<Type definitions@>=
typedef struct {
   U8      bLength;               //!< Size of this descriptor in bytes
   U8      bDescriptorType;       //!< ENDPOINT descriptor type
   U8      bEndpointAddress;      //!< Address of the endpoint
   U8      bmAttributes;          //!< Endpoint's attributes
   U16     wMaxPacketSize;        //!< Maximum packet size for this EP
   U8      bInterval;             //!< Interval for polling EP in ms
} S_usb_endpoint_descriptor;

@ @<Initialize |ep1|@>= {
  sizeof (S_usb_endpoint_descriptor),
  0x05,
  0x81,
  0x03,
  0x0008,
  0x0F
}

@ @<Initialize |ep2|@>= {
  sizeof (S_usb_endpoint_descriptor),
  0x05,
  0x02,
  0x03,
  0x0008,
  0x0F
}
