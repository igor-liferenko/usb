@* Intro. This embedded application source code illustrates how to implement a CDC application
with the ATmega32U4 controller.

This application will enumerate as a CDC (communication device class) virtual COM port.
The application can be used as a USB to serial converter.

Changes: now does not allow to send data before end enumeration AND open port detection.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3}
(use \.{http://www.engbedded.com/fusecalc}).

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
//      DDRB|=1<<PB0;PORTB|=1<<PB0;
      /*process dtr here - grep SETUP_CDC_SET_CONTROL_LINE_STATE*/
    }
    //if (line_status.DTR) {
      /* send a character (see cdc_task.w) */
    //}
    //_delay_ms(1000);
  }
}

@ @<EOR interrupt handler@>=
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

@ NAKINI is set if we did not send anything in IN request
(but why? - TXINI was never cleared). This can be checked by the following
code:

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
    if (UEINTX & (1 << RXSTPI)) PORTD |= 1 << PD5; /* this is on */
  }
}

@ Reset is done more than once. This can be checked by the following code:

@(test.c@>=
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
}  S_usb_device_descriptor;
  code const S_usb_device_descriptor usb_dev_desc = {
  sizeof(usb_dev_desc)
, DESCRIPTOR_DEVICE
, Usb_write_word_enum_struc(0x0110) /* bcdUSB */
, DEVICE_CLASS
, DEVICE_SUB_CLASS
, DEVICE_PROTOCOL
, EP_CONTROL_LENGTH
, Usb_write_word_enum_struc(VENDOR_ID)
, Usb_write_word_enum_struc(PRODUCT_ID)
, Usb_write_word_enum_struc(RELEASE_NUMBER)
, 0x00 /* iManufacturer ("Mfr=" in kern.log) */
, 0x00 /* iProduct ("Product=" in kern.log) */
, 0x00 /* iSerialNumber ("SerialNumber=" in kern.log) */
, NB_CONFIGURATION
};
  U8 data_to_transfer = sizeof (usb_dev_desc);
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




}
