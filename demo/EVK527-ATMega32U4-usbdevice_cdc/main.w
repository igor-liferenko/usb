@* Intro. This embedded application source code illustrates how to implement a CDC application
with the ATmega32U4 controller.

This application will enumerate as a CDC (communication device class) virtual COM port.
The application can be used as a USB to serial converter.

Changes: now does not allow to send data before end enumeration AND open port detection.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3}
(use \.{http://www.engbedded.com/fusecalc}).

@ NAKINI is set if we did not send anything in IN request
(but why? - TXINI was never cleared). This can be checked by the following
code:
\xdef\nakinitest{\secno}
@(/dev/null@>=
#include <avr/io.h>

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  DDRC |= 1 << PC7;
  DDRB |= 1 << PB0;
  DDRD |= 1 << PD5;
  while(1) {
    UECONX |= 1 << EPEN;
    UECFG1X |= 1 << ALLOC;
    if (!(UEINTX & (1 << RXSTPI)) && (UEINTX & (1 << NAKINI)))
      PORTC |= 1 << PC7; /* this is not on */
    if ((UEINTX & (1 << RXSTPI)) && (UEINTX & (1 << NAKINI)))
      PORTB |= 1 << PB0; /* this is on */
    if (UEINTX & (1 << RXSTPI)) {
      PORTD |= 1 << PD5; /* this is on */
      UEINTX &= ~(1 << RXSTPI); /* TODO: do above results change with this? this will
      say if ack is sent when we clean rxstpi or it is sent automatically before
      rxstpi is set */
    }
  }
}

@ Reset is done more than once. This can be checked by the following code:
\xdef\resettestone{\secno} % remember the number of this section

@(/dev/null@>=
#include <avr/io.h>
#include <avr/pgmspace.h>

typedef unsigned char U8;
typedef unsigned short U16;
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
PROGMEM const S_usb_device_descriptor usb_dev_desc = {
  sizeof (S_usb_device_descriptor),
  0x01, /* device */
  0x0110, /* bcdUSB */
  0x02, /* device class */
  0, /* subclass */
  0, /* device protocol */
  64, /* control endpoint size */
  0x03EB,
  0x2018,
  0x1000,
  0x00, /* iManufacturer ("Mfr=" in kern.log) */
  0x00, /* iProduct ("Product=" in kern.log) */
  0x00, /* iSerialNumber ("SerialNumber=" in kern.log) */
  1 /* number of configurations */
};

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  DDRC |= 1 << PC7;
  DDRB |= 1 << PB0;
  U8 data_to_transfer = sizeof usb_dev_desc;
  PGM_VOID_P pbuffer = &usb_dev_desc.bLength;
  U8 bRequest;
  U8 bmRequestType;
  U8 bDescriptorType;
  U16 wLength;
  while(1) {
    if (UDINT & (1 << EORSTI)) break;
  }
  bmRequestType = UEDATX;
  bRequest = UEDATX;
  (void) UEDATX; /* don't care of Descriptor Index */
  bDescriptorType = UEDATX;
  (void) UEDATX; @+ (void) UEDATX; /* don't care of Language Id */
  wLength; /* how many bytes host can get (i.e., we must not send more than that) */
  ((U8*) &wLength)[0] = UEDATX; /* wLength LSB */
  ((U8*) &wLength)[1] = UEDATX; /* wLength MSB */
#if 1==1
  UEINTX &= ~(1 << RXSTPI); /* do not do it here to check rxstpi like in section
    \nakinitest */
#endif
   while (data_to_transfer--)
     UEDATX = pgm_read_byte_near((unsigned int) pbuffer++);
   UEINTX &= ~(1 << TXINI);
   while (!(UEINTX & (1 << NAKOUTI))) ;
   UEINTX &= ~(1 << NAKOUTI);
   while (!(UEINTX & (1 << RXOUTI))) ;
   UEINTX &= ~(1 << RXOUTI);
}

@ Here we check initial value of TXINI. This will say if TXINI is set to one if IN
packet was received or on some other condition (depends on what it is initially-check
here) 

@(/dev/null@>=
#include <avr/io.h>

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  DDRC |= 1 << PC7;
  if (UEINTX & (1 << TXINI)) PORTC |= 1 << PC7; /* TODO: write result here and in doc-part */
  while (1) ;
}

@ Here we check if RXOUTI is set when NAKOUTI becomes set. In datasheet it is said
that during switch from IN to OUT transaction NAKOUTI is set. This test will help
to understand if the following phrase from ``USB in a nutshell'' is true:
When OUT request arrives if the endpoint buffer is not empty due to processing of the
previous packet, then device sets NAKOUTI.

;;; move this to section of control-write-stage: from usb in a nutshell: Device replies with
;; a NAK packet in IN transaction if there is
;; no data to send.

@(test.c@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <avr/wdt.h>
typedef unsigned char U8;
typedef unsigned short U16;
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
const S_usb_device_descriptor dev_desc PROGMEM = {
  sizeof (S_usb_device_descriptor),
  0x01, /* device */
  0x0110, /* bcdUSB */
  0x02, /* device class */
  0, /* subclass */
  0, /* device protocol */
  64, /* control endpoint size */
  0x03EB,
  0x2018,
  0x1000,
  0x00, /* iManufacturer ("Mfr=" in kern.log) */
  0x00, /* iProduct ("Product=" in kern.log) */
  0x00, /* iSerialNumber ("SerialNumber=" in kern.log) */
  1 /* number of configurations */
};
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
#define SETUP_GET_DESCRIPTOR 0x06
#define USB_SETUP_DIR_DEVICE_TO_HOST (1<<7)
#define USB_SETUP_TYPE_STANDARD (0<<5)
#define USB_SETUP_RECIPIENT_DEVICE (0)
#define USB_SETUP_GET_STAND_DEVICE (USB_SETUP_DIR_DEVICE_TO_HOST | \
  USB_SETUP_TYPE_STANDARD | USB_SETUP_RECIPIENT_DEVICE)
#define DESCRIPTOR_DEVICE 0x01
ISR(USB_COM_vect)
{
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;
  if (UEINT == (1 << EP0)) {
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;

    uint8_t bmRequestType = UEDATX;
    uint8_t bRequest = UEDATX;
    if (bRequest == SETUP_GET_DESCRIPTOR) { // NOTE: using an define here is wrong - first check
      // bmRequestType, not bRequest - then you may use define
      if (bmRequestType == USB_SETUP_GET_STAND_DEVICE) {
        (void) UEDATX;
        uint8_t bDescriptorType = UEDATX;
        (void) UEDATX;
        (void) UEDATX;
        uint16_t wLength;
        ((uint8_t *) &wLength)[0] = UEDATX;
        ((uint8_t *) &wLength)[1] = UEDATX;
        UEINTX &= ~(1 << RXSTPI);
        if (bDescriptorType == DESCRIPTOR_DEVICE) {
DDRC |= 1 << PC7;
PORTC |= 1 << PC7;
          while (!(UEINTX & (1 << TXINI))) ;
          const void *buf = &dev_desc.bLength;
          for (int i = 0; i < sizeof (dev_desc); i++)
            UEDATX = pgm_read_byte_near((unsigned int) buf++);
          UEINTX &= ~(1 << TXINI);
//---
          while (!(UEINTX & (1 << NAKOUTI))) ;
          UEINTX &= ~(1 << NAKOUTI);
          while (!(UEINTX & (1 << RXOUTI))) ;
          UEINTX &= ~(1 << RXOUTI);
//---
#if 1==0
while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
#endif
          return;
        }
//        else n_1
      }
//      else sl_1
    }
//    if (bRequest == SETUP_SET_ADDRESS) {
  }
}

@ The main function first performs the initialization of a scheduler module and then runs it in
an infinite loop.
The scheduler is a simple infinite loop calling all its tasks defined in the \.{conf\_scheduler.h}
file. No real time schedule is performed, when a task ends, the scheduler calls the next task
defined in the configuration file (\.{conf\_scheduler.h}).

The sample dual role application is based on two different tasks:
\item{-} The |usb_task| (\.{usb\_task.c} associated source file), is the task performing the USB
  low level enumeration process in device mode.
\item{-} The |cdc_task| performs the loop back application between USB and USART interfaces.

@c
#include "config.h"
#include "modules/scheduler/scheduler.h"
#include "lib_mcu/power/power_drv.h"
#include "lib_mcu/usb/usb_drv.h"
#include "modules/usb/ch9/usb_device_task.h"
#include "modules/usb/ch9/usb_standard_request.h"

#include "config.h"
#include "conf_usb.h"

extern U8    usb_configuration_nb;

@<EOR interrupt handler@>@;

int connected = 0;

int main(void)
{
  sei();
  @#
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */
  @#
  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;
  @#
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  @#
  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  @#
  UDIEN |= 1 << EORSTE;
  UDCON &= ~(1 << DETACH);

  while (!connected) {
    if (UEINTX & (1 << RXSTPI)) {
      usb_process_request();
    }
  }
  UDIEN &= ~(1 << EORSTE);
  while (1) { /* main application loop */
    UENUM = 0;
    if (UEINTX & (1 << RXSTPI)) {
//      |DDRB|=1<<PB0;PORTB|=1<<PB0;|
      /*process dtr here - grep SETUP\_CDC\_SET\_CONTROL\_LINE\_STATE*/
    }
#if 1==0
    if (line_status.DTR) {
      /* send a character (see cdc\_task.w) */
    }
    _delay_ms(1000);
#endif
  }
}

@ Such and such decision was made due to section \resettestone.

@<EOR interrupt handler@>=
ISR(USB_GEN_vect)
{
  if ((UDINT & (1 << EORSTI)) && (UDIEN & (1 << EORSTE))) {
    UDINT &= ~(1 << EORSTI);
    UDADDR &= ~(1 << ADDEN);
    UENUM = 0;
    UECONX |= 1 << EPEN;
    UECFG0X |= 0 << EPTYPE0; /* control */
    UECFG0X |= 0 << EPDIR; /* out */
    UECFG1X |= 3 << EPSIZE0; /* 64 bytes (binary 011) - must be in accord with
      |EP_CONTROL_LENGTH| */
    UECFG1X |= 0 << EPBK0; /* one */
    UECFG1X |= 1 << ALLOC;
  }
}

@*2 Control read (by host). There are the folowing
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to7.83cm{\vbox to1.23472222222222cm{\vfil\special{psfile=gcc/direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=2220}}\hfil}$$

$$\hbox to11.28cm{\vbox to13.4055555555556cm{\vfil\special{psfile=gcc/control-read-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=3200}}\hfil}$$

$$\hbox to15.55cm{\vbox to3.77472222222222cm{\vfil\special{psfile=gcc/control-IN.eps
  clip llx=0 lly=0 urx=441 ury=107 rwi=4410}}\hfil}$$

This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

@*2 Control write (by host). There are the following
stages\footnote*{Setup transaction $\equiv$ Setup stage}:

$$\hbox to7.83cm{\vbox to1.23472222222222cm{\vfil\special{psfile=gcc/direction.eps
  clip llx=0 lly=0 urx=222 ury=35 rwi=2220}}\hfil}$$

$$\hbox to11.28cm{\vbox to13.4055555555556cm{\vfil\special{psfile=gcc/control-write-stages.eps
  clip llx=0 lly=0 urx=320 ury=380 rwi=3200}}\hfil}$$

$$\hbox to16cm{\vbox to4.39cm{\vfil\special{psfile=gcc/control-OUT.eps
  clip llx=0 lly=0 urx=1474 ury=405 rwi=4535}}\hfil}$$

This corresponds to the following transactions:

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-SETUP.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-OUT.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

$$\hbox to11.28cm{\vbox to5.29166666666667cm{\vfil\special{psfile=gcc/transaction-IN.eps
  clip llx=0 lly=0 urx=320 ury=150 rwi=3200}}\hfil}$$

@* Index.
