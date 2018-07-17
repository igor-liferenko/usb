@ NOTICE: test.w and these tests differ in number of resets because in test.w RSTCPU is done
see also "XXX" in test.w

@ In this test we determine how endpoint configuration reacts to reset.
The result is `\.{esa}'. So, after each reset each of these parameters must be set again.

\xdef\epconf{\secno}

@(/dev/null@>=
#include <avr/io.h>

#define configure @,@,@,@,@, UECONX |= 1 << EPEN; @+ UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))
#define send(c) @,@,@,@,@, UDR1 = c; @+ while (!(UCSR1A & 1 << UDRE1)) ;

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  configure;
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');

  while (!(UEINTX & (1 << RXSTPI))) ;
  send('%');
}

@ Here we want to find out how many resets happen until first setup packet arrives.
We start like in \S\epconf\ and start adding code for waiting for successive resets.
Adding code for waiting for a reset consists of two stages: first we add code to configure items
which are output after previous reset and check if `\.{\%}' appears.
If it is, we are done. If not, we add the |while| loop and checking endpoint configuration.
Then the process repeats. To count the number of resets, we output a number after each reset.
The result is sometimes two sometimes three resets. And after each reset endpoint must
be configured.
And |CFGOK| need not be checked.

\xdef\numreset{\secno}

@(/dev/null@>=
#include <avr/io.h>

#define configure @,@,@,@,@, UECONX |= 1 << EPEN; @+ UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
#define configured_en (UECONX & (1 << EPEN))
#define configured_sz (UECFG1X & (1 << EPSIZE1))
#define configured_al (UECFG1X & (1 << ALLOC))
#define configured_ok (UESTA0X & (1 << CFGOK))
#define send(c) @,@,@,@,@, UDR1 = c; @+ while (!(UCSR1A & 1 << UDRE1)) ;

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  configure;
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  send('1');
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');
  configure;
  if (!configured_ok) send('=');

  while(1) if (UDINT & (1 << EORSTI)) break; UDINT &= ~(1 << EORSTI);
  send('2');
  if (!configured_en) send('e');
  if (!configured_sz) send('s');
  if (!configured_al) send('a');
  configure;

  while (!(UEINTX & (1 << RXSTPI))) ;
  send('%');
}

@ Now we can move further: we detect reset via interrupts.
Also, here we count number of resets.
Result is the same as in \S\numreset---two or three.

\xdef\interrupt{\secno}

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>

#define send(c) @,@,@,@,@, UDR1 = c; @+ while (!(UCSR1A & 1 << UDRE1)) ;

volatile int num = 0;

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!(UEINTX & (1 << RXSTPI))) ;
  send(num + '0');
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    num++;
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  }
}

@ Now we can move further: to count number of resets before set address request.
The result is one.

@(/dev/null@>=
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>

typedef struct {
  uint8_t      bLength;              //!< Size of this descriptor in bytes
  uint8_t      bDescriptorType;      //!< DEVICE descriptor type
  uint16_t     bscUSB;               //!< Binay Coded Decimal Spec. release
  uint8_t      bDeviceClass;         //!< Class code assigned by the USB
  uint8_t      bDeviceSubClass;      //!< Sub-class code assigned by the USB
  uint8_t      bDeviceProtocol;      //!< Protocol code assigned by the USB
  uint8_t      bMaxPacketSize0;      //!< Max packet size for EP0
  uint16_t     idVendor;             //!< Vendor ID. ATMEL = 0x03EB
  uint16_t     idProduct;            //!< Product ID assigned by the manufacturer
  uint16_t     bcdDevice;            //!< Device release number
  uint8_t      iManufacturer;        //!< Index of manu. string descriptor
  uint8_t     iProduct;             //!< Index of prod. string descriptor
  uint8_t      iSerialNumber;        //!< Index of S.N.  string descriptor
  uint8_t      bNumConfigurations;   //!< Number of possible configurations
} S_usb_device_descriptor;

const S_usb_device_descriptor usb_dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  sizeof (S_usb_device_descriptor), @/
  0x01, /* device */
  0x0110, /* bcdUSB */
  0x02, /* device class */
  0, /* subclass */
  0, /* device protocol */
  64, /* control endpoint size */
  0x03EB, @/
  0x2018, @/
  0x1000, @/
  0x00, /* iManufacturer ("Mfr=" in kern.log) */
  0x00, /* iProduct ("Product=" in kern.log) */
  0x00, /* iSerialNumber ("SerialNumber=" in kern.log) */
@t\2@> 1 /* number of configurations */
};

uint8_t data_to_transfer = sizeof usb_dev_desc;
const void *pbuffer = &usb_dev_desc.bLength;
uint8_t bRequest;
uint8_t bmRequestType;
uint8_t bDescriptorType;
uint16_t wLength;

#define send(c) @,@,@,@,@, UDR1 = c; @+ while (!(UCSR1A & 1 << UDRE1)) ;

volatile int num = 0;

void main(void)
{
  UHWCON |= 1 << UVREGE; /* enable internal USB pads regulator */

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;

  PLLCSR |= 1 << PINDIV;
  PLLCSR |= 1 << PLLE;
  while (!(PLLCSR & (1<<PLOCK))) ;

  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);

  USBCON |= 1 << OTGPADE; /* enable VBUS pad */
  while (!(USBSTA & (1 << VBUS))) ; /* wait until VBUS line detects power from host */
  UDCON &= ~(1 << DETACH);

  UDIEN |= 1 << EORSTE;
  sei();

  while (!(UEINTX & (1 << RXSTPI))) ;
  num = 0;
  bmRequestType = UEDATX;
  bRequest = UEDATX;
  (void) UEDATX; /* don't care of Descriptor Index */
  bDescriptorType = UEDATX;
  (void) UEDATX; @+ (void) UEDATX; /* don't care of Language Id */
  ((uint8_t *) &wLength)[0] = UEDATX; /* wLength LSB */
  ((uint8_t *) &wLength)[1] = UEDATX; /* wLength MSB */
  UEINTX &= ~(1 << RXSTPI);
  while (data_to_transfer--)
    UEDATX = pgm_read_byte_near((unsigned int) pbuffer++);
  UEINTX &= ~(1 << TXINI);
  while (!(UEINTX & (1 << NAKOUTI))) ;
  UEINTX &= ~(1 << NAKOUTI);
  while (!(UEINTX & (1 << RXOUTI))) ;
  UEINTX &= ~(1 << RXOUTI);

  while (!(UEINTX & (1 << RXSTPI))) ;
  bmRequestType = UEDATX;
  bRequest = UEDATX;
  if (bRequest == 0x05) send(num + '0');
}

ISR(USB_GEN_vect)
{
  if (UDINT & (1 << EORSTI)) {
    UDINT &= ~(1 << EORSTI);
    num++;
    UECONX |= 1 << EPEN;
    UECFG1X = (1 << EPSIZE1) | (1 << ALLOC);
  }
}

@ OK, enough tests. We now have all the information that we need.

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


@* Index.
