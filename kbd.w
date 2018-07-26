\secpagedepth=2 % begin new page only on * % TODO: check via dvidiff if it is used here or after
                                           % \datethis in test.w (with and without kbd.ch)

@i test.w % \datethis is here (and \let\lheader...)

@* Program. This embedded application source code illustrates how to implement a HID
with the ATmega32U4 controller.

Read fuses via ``\.{avrdude -c usbasp -p m32u4}'' and ensure that the following fuses are
unprogrammed: \.{WDTON}, \.{CKDIV8}, \.{CKSEL3} (use \.{http://www.engbedded.com/fusecalc}).
In short, fuses must be these: \.{E:CB}, \.{H:D8}, \.{L:FF}.

@d EP0 0
@d EP1 1
@d EP0_SIZE 32 /* 32 bytes\footnote\dag{Must correspond to |UECFG1X| of |EP0|.} */

@c
@<Header files@>@;
@<Type \null definitions@>@;
@<Global \null variables@>@;
@<Functions@>@;

volatile int connected = 0;
void main(void)
{
/* TODO: ensure that all is done via `\.{\char'174=}', because MCU may be reset via RSTCPU,
 when usb stuff remains active (and cmp with original asm.S) */
  UHWCON = 1 << UVREGE;

  UBRR1 = 34; // table 18-12 in datasheet
  UCSR1A |= 1 << U2X1;
  UCSR1B = 1 << TXEN1;
  UDR1 = 'v';

  PLLCSR = (1 << PINDIV) | (1 << PLLE);
  while (!(PLLCSR & (1 << PLOCK))) ;
  USBCON |= 1 << USBE;
  USBCON &= ~(1 << FRZCLK);
  USBCON |= 1 << OTGPADE;
  while (!(USBSTA & (1 << VBUS))) ;
  UDCON &= ~(1 << DETACH);
  UDCON &= ~(1 << RSTCPU);

  UDIEN = 1 << EORSTE;
  sei();

  uint16_t wLength;
  while (!connected)
    if (UEINTX & (1 << RXSTPI))
      @<Process {\sc SETUP} request@>@;

  PORTD |= 1 << PD0;
  PORTD |= 1 << PD1;
  while (1) {
    if (!(PIND & 1 << PD0)) {
      @<Press button `a'@>@;
      _delay_ms(1000);
    }
    if (!(PIND & 1 << PD1)) {
      @<Press button `ESC'@>@;
      _delay_ms(1000);
    }
  }
}

@ @c
ISR(USB_GEN_vect)
{
  UDINT &= ~(1 << EORSTI);
  if (!connected) {
    UECONX |= 1 << EPEN;
    UECFG0X = (0 << EPTYPE1) + (0 << EPTYPE0) | (0 << EPDIR); /* control, OUT */
    UECFG1X = (0 << EPBK0) | (1 << EPSIZE1) + (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 32
      bytes\footnote\ddag{Must correspond to |EP0_SIZE|.} */
  }
  else UDCON |= 1 << RSTCPU;
  while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'r';
}

@ Here we dispatch {\sc SETUP} request to corresponding processing module.

@<Process {\sc SETUP} request@>=
      switch (UEDATX | UEDATX << 8)
      {
      case 0x0500: @/
        @<SET ADDRESS@>@;
        break;
      case 0x0680: @/
        switch (UEDATX | UEDATX << 8)
        {
        case 0x0100: @/
          @<GET DESCRIPTOR DEVICE\null@>@;
          break;
        case 0x0200: @/
          @<GET DESCRIPTOR CONFIGURATION@>@;
          break;
        case 0x0300: @/
          @<GET DESCRIPTOR STRING (language)@>@;
          break;
        case 0x03 << 8 | MANUFACTURER: @/
          @<GET DESCRIPTOR STRING (manufacturer)@>@;
          break;
        case 0x03 << 8 | PRODUCT: @/
          @<GET DESCRIPTOR STRING (product)@>@;
          break;
        case 0x03 << 8 | SERIAL_NUMBER: @/
          @<GET DESCRIPTOR STRING (serial)@>@;
          break;
        case 0x0600: @/
          @<GET DESCRIPTOR DEVICE QUALIFIER@>@;
          break;
        }
        break;
      case 0x0681: @/
        @<GET DESCRIPTOR HID@>@;
        @<Finish connection@>@;
        break;
      case 0x0900: @/
        @<SET CONFIGURATION@>@;
        break;
      case 0x0a21: @/
        @<SET IDLE@>@;
        break;
      }

@ @<SET ADDRESS@>=
UDADDR = UEDATX & 0x7F;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'A';
UEINTX &= ~(1 << TXINI); /* STATUS stage */
while (!(UEINTX & (1 << TXINI))) ; /* wait until ZLP, prepared by previous command, is
            sent to host\footnote{$\sharp$}{According to \S22.7 of the datasheet,
            firmware must send ZLP in the STATUS stage before enabling the new address.
            The reason is that the request started by using zero address, and all the stages of the
            request must use the same address.
            Otherwise STATUS stage will not complete, and thus set address request will not
            succeed. We can determine when ZLP is sent by receiving the ACK, which sets TXINI to 1.
            See ``Control write (by host)'' in table of contents for the picture (note that DATA
            stage is absent).} */
UDADDR |= 1 << ADDEN;

@ @<SET CONFIGURATION@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'S';
UEINTX &= ~(1 << TXINI); /* STATUS stage */

@ When host is booting, |wLength| is 8 bytes in first request of device descriptor (8 bytes is
sufficient for first request of device descriptor). If host is operational,
|wLength| is 64 bytes in first request of device descriptor.
It is OK if we transfer less than the requested amount. But if we try to
transfer more, device will hang.

@<GET DESCRIPTOR DEVICE\null@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'D';
send_descriptor(&dev_desc, wLength < sizeof dev_desc ? 8 : sizeof dev_desc);

@ @<GET DESCRIPTOR DEVICE QUALIFIER@>=
UECONX |= 1 << STALLRQ; /* according to the spec */
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'Q';

@ @<GET DESCRIPTOR CONFIGURATION@>=
(void) UEDATX; @+ (void) UEDATX;
wLength = UEDATX | UEDATX << 8;
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ;
if (wLength == 9) UDR1 = 'g'; else UDR1 = 'G';
send_descriptor(&user_conf_desc, wLength);

@ This request is used to set idle rate for reports. Duration 0 (first byte of wValue)
means that host lets the device send reports only when it needs.

@<SET IDLE@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'I';
UEINTX &= ~(1 << TXINI); /* STATUS stage */

@ @<GET DESCRIPTOR STRING (language)@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'L';
send_descriptor(lang_desc, sizeof lang_desc);

@ @<GET DESCRIPTOR STRING (manufacturer)@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'M';
send_descriptor(&mfr_desc, pgm_read_byte(&mfr_desc.bLength));

@ @<GET DESCRIPTOR STRING (product)@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'P';
send_descriptor(&prod_desc, pgm_read_byte(&prod_desc.bLength));

@ @<GET DESCRIPTOR STRING (serial)@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'N';
send_descriptor(NULL, 1 + 1 + SN_LENGTH * 2);

@ @<GET DESCRIPTOR HID@>=
UEINTX &= ~(1 << RXSTPI);
while (!(UCSR1A & 1 << UDRE1)) ; @+ UDR1 = 'R';
send_descriptor(hid_report_descriptor, sizeof hid_report_descriptor);

@ @<Finish connection@>=
connected = 1; /* in contrast with \.{test.w}, it must be before switching from |EP0| */
UENUM = EP1;
UECONX |= 1 << EPEN;
UECFG0X = (1 << EPTYPE1) + (1 << EPTYPE0) | (1 << EPDIR); /* interrupt\footnote\dag
  {Must correspond to IN endpoint description in |@<Initialize element 4...@>|.}, IN */
UECFG1X = (0 << EPBK0) | (0 << EPSIZE0) | (1 << ALLOC); /* one bank, 8 bytes\footnote
  {\dag\dag}{Must correspond to IN endpoint description in |hid_report_descriptor|.} */
while (!(UESTA0X & (1 << CFGOK))) ; /* TODO: test with led if it is necessary (create
  a test for this in test.w, like the first test for control endpoint) */

@ See datasheet \S22.12.2.

Here we also handle one case when data (serial number) needs to be transmitted from memory,
not from program.

@<Functions@>=
void send_descriptor(const void *buf, int size)
{
  @<Fill in serial number if |buf == NULL|@>@;
#if 1==1
  while (1) {
    int nb_byte = 0;
    while (size != 0) {
      if (nb_byte++ == EP0_SIZE)
        break;
      UEDATX = from_program ? pgm_read_byte(buf++) : *(uint8_t *) buf++;
      size--;
    }
    UEINTX &= ~(1 << TXINI);
    while (!(UEINTX & (1 << TXINI)) && !(UEINTX & (1 << RXOUTI))) ;
    if (UEINTX & (1 << RXOUTI)) {
      UEINTX &= ~(1 << RXOUTI);
      break;
    }
  }
#else /* FIXME: where is it said in datasheet or USB spec that the last-packet-full check
         is necessary? */
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

@i control-endpoint-management.w

@i IN-endpoint-management.w

@* USB stack.

The order of descriptors here is the same as the order in which they are transmitted.

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

@ @d MANUFACTURER 0x01
@d PRODUCT 0x02
@d SERIAL_NUMBER 0x03
@d NOT_USED 0x00

@<Global \null variables@>=
const S_device_descriptor dev_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  sizeof (S_device_descriptor), @/
  0x01, /* device */
  0x0200, /* USB 2.0 */
  0, /* no class */
  0, /* no subclass */
  0, @/
  EP0_SIZE, @/
  0x03EB, /* ATMEL */
  0x2013, /* standard Human Interaction Device */
  0x1000, /* from Atmel demo */
  MANUFACTURER, /* (\.{Mfr} in \.{kern.log}) */
  PRODUCT, /* (\.{Product} in \.{kern.log}) */
  NOT_USED, /* (\.{SerialNumber} in \.{kern.log}) */
@t\2@> 1 /* one configuration for this device */
};

@*1 User configuration descriptor.

$$\hbox to5cm{\vbox to7.7cm{\vfil\special{psfile=kbd-structure.eps
  clip llx=0 lly=0 urx=187 ury=288 rwi=1417}}\hfil}$$

@<Type \null definitions@>=
@<Type definitions used in user configuration descriptor@>@;
typedef struct {
   S_configuration_descriptor conf_desc;
   S_interface_descriptor     ifc;
   S_hid_descriptor           hid;
   S_endpoint_descriptor      ep1;
} S_user_configuration_descriptor;

@ @<Global \null variables@>=
@<Global variables used in user configuration descriptor@>@;
const S_user_configuration_descriptor user_conf_desc
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  @<Initialize element 1...@>, @/
  @<Initialize element 2...@>, @/
  @<Initialize element 3...@>, @/
@t\2@> @<Initialize element 4...@> @/
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

@ |bInterfaceSubClass| signifies device type (non-bootable or bootable).

|bInterfaceProtocol| is used if device is determined as bootable. It signifies
standard protocol which the device supports (user-defined, keyboard or mouse).

@<Initialize element 2 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_interface_descriptor), @/
  0x04, /* interface descriptor */
  0, /* this corresponds to `0' in `if0' on picture */
  0, /* this corresponds to `0' in `alt0' on picture */
  1, /* one endpoint is used */
  0x03, /* HID */
  0, /* non-bootable */
  0, /* not used */
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
  uint16_t wReportDescriptorLength;
} S_hid_descriptor;

@ @<Initialize element 3 in user configuration descriptor@>= { @t\1@> @/
  sizeof (S_hid_descriptor), @/
  0x21, /* HID */
  0x0100, /* HID version 1.0 */
  0x00, /* no localization */
  0x01, /* one descriptor for this device */
  0x22, /* HID report (value of |bDescriptorType| in GET DESCRIPTOR request for HID report) */
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

@*1 HID report descriptor.

The usual format for keyboard reports is the following byte array:

\centerline{modifier, reserved, Key1, Key2, Key3, Key4, Key5, Key6}

When you press the letter `a' on a USB keyboard, the following report will be sent in
response to an IN interrupt request:

\centerline{|0x00|, |0x00|, |0x04|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

\noindent This `|0x04|' value is the Keycode for the letter `a'.

After releasing the key, the following report will be sent:

\centerline{|0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

\noindent An array of zeros means nothing is being pressed.

For an uppercase `A', the report will also need to contain a `Left Shift' modifier.
The modifier byte is actually a bitmap, which means that each bit corresponds to one key:

bit 0: left control\par
bit 1: left shift\par
bit 2: left alt\par
bit 3: left GUI (Win/Apple/Meta key)\par
bit 4: right control\par
bit 5: right shift\par
bit 6: right alt\par
bit 7: right GUI\par

\noindent With left shift pressed, out report will look like that:

\centerline{|0x02|, |0x00|, |0x04|, |0x00|, |0x00|, |0x00|, |0x00|, |0x00|}

{\bf Note:} This report descriptor was prepared in ``HID descriptor tool'' (it works
in \.{wine}; start the executable from the same folder to which it was unpacked).

@<Global variables ...@>=
const uint8_t hid_report_descriptor[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x05, 0x01, @t\hskip10pt@> // \.{USAGE\_PAGE (Generic Desktop)}
  0x09, 0x06, @t\hskip10pt@> // \.{USAGE (Keyboard)}
  0xa1, 0x01, @t\hskip10pt@> // \.{COLLECTION (Application)}
  0x05, 0x07, @t\hskip21pt@> //   \.{USAGE\_PAGE (Keyboard)}
  0x75, 0x01, @t\hskip21pt@> //   \.{REPORT\_SIZE (1)}
  0x95, 0x08, @t\hskip21pt@> //   \.{REPORT\_COUNT (8)}
  0x19, 0xe0, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Keyboard LeftControl)}
  0x29, 0xe7, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Right GUI)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x01, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (1)}
  0x81, 0x02, @t\hskip21pt@> //   \.{INPUT (Data,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x01, @t\hskip21pt@> //   \.{REPORT\_COUNT (1)}
  0x81, 0x03, @t\hskip21pt@> //   \.{INPUT (Cnst,Var,Abs)}
  0x75, 0x08, @t\hskip21pt@> //   \.{REPORT\_SIZE (8)}
  0x95, 0x06, @t\hskip21pt@> //   \.{REPORT\_COUNT (6)}
  0x19, 0x00, @t\hskip21pt@> //   \.{USAGE\_MINIMUM (Reserved (no event indicated))}
  0x29, 0x65, @t\hskip21pt@> //   \.{USAGE\_MAXIMUM (Keyboard Application)}
  0x15, 0x00, @t\hskip21pt@> //   \.{LOGICAL\_MINIMUM (0)}
  0x25, 0x65, @t\hskip21pt@> //   \.{LOGICAL\_MAXIMUM (101)}
  0x81, 0x00, @t\hskip21pt@> //   \.{INPUT (Data,Ary,Abs)}
@t\2@> 0xc0   @t\hskip36pt@> // \.{END\_COLLECTION}
};

@ @<Press button `a'@>=
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
      while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent */

@ @<Press button `ESC'@>=
      UEDATX = 0;
      UEDATX = 0;
      UEDATX = 0x29;
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
      while (!(UEINTX & (1 << TXINI))) ; /* wait until previous packet will be sent */

@*1 Language descriptor.

This is necessary to transmit serial number.

@<Global \null variables@>=
const uint8_t lang_desc[]
@t\hskip2.5pt@> @=PROGMEM@> = { @t\1@> @/
  0x04, /* size */
  0x03, /* type (string) */
@t\2@> 0x09,0x04 /* id (English) */
};

@*1 String descriptors.

The trick here is that when defining a variable of type |S_string_descriptor|,
the string content follows the first two elements in program memory.
The C standard says that a flexible array member in a struct does not increase the size of the
struct (aside from possibly adding some padding at the end) but gcc lets you initialize it anyway.
So, |sizeof| on the variable counts only first two elements.
So, we use |pgm_read_byte| to read the size of the variable during execution time.
TODO: put here explanation from \.{https://stackoverflow.com/questions/51470592/}
@^TODO@>

@^GCC-specific@>

@s S_string_descriptor int

@<Type \null definitions@>=
typedef struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  int16_t wString[];
} S_string_descriptor;

#define STR_DESC(str) { 1 + 1 + sizeof str - 2, 0x03, str }

@*2 Manufacturer descriptor.

@<Global \null variables@>=
const S_string_descriptor mfr_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"ATMEL");

@*2 Product descriptor.

@<Global \null variables@>=
const S_string_descriptor prod_desc
@t\hskip2.5pt@> @=PROGMEM@> = STR_DESC(L"AVR USB HID DEMO");

@*1 Serial number descriptor.

This one is different in that its content cannot be prepared in compile time,
only in execution time. So, it cannot be stored in program memory.
Therefore, a special trick is used in |send_descriptor| (to avoid cluttering it with
arguments): we pass a null pointer if serial number is to be transmitted.
In |send_descriptor| |sn_desc| is filled in.

@d SN_LENGTH 20 /* length of device signature, multiplied by two */

@<Global \null variables@>=
struct {
  uint8_t bLength;
  uint8_t bDescriptorType;
  int16_t wString[SN_LENGTH];
} sn_desc;

@ @<Fill in serial number if |buf == NULL|@>=
int from_program = 1;
if (buf == NULL) {
  from_program = 0;
  @<Get serial number@>@;
  buf = &sn_desc;
}

@ @d SN_START_ADDRESS 0x0E
@d hex(c) c<10 ? c+'0' : c-10+'A'

@<Get serial number@>=
sn_desc.bLength = 1 + 1 + SN_LENGTH * 2;
sn_desc.bDescriptorType = 0x03;
uint8_t addr = SN_START_ADDRESS;
for (uint8_t i = 0; i < SN_LENGTH; i++) {
  uint8_t c = boot_signature_byte_get(addr);
  if (i & 1) { /* we divide each byte of signature into halves, each of
                  which is represented by a hex number */
    c >>= 4;
    addr++;
  }
  else c &= 0x0F;
  sn_desc.wString[i] = hex(c);
}

@* Headers.
\secpagedepth=1 % index on current page

@<Header files@>=
#include <avr/boot.h> /* |boot_signature_byte_get| */
#include <avr/io.h>
#include <avr/interrupt.h>
#include <avr/pgmspace.h>
#include <stddef.h> /* |NULL| */
#define F_CPU 16000000UL
#include <util/delay.h>

@* Index.
